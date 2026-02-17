/**
 * JobCoordinatorDO — job당 1개 Durable Object
 *
 * SQLite-backed FSM + 멱등성 Ring Buffer (size 512) + Alarm D1 flush
 *
 * FSM transitions:
 *   created → uploaded (confirmUpload)
 *   uploaded → queued (markQueued + Queue push)
 *   queued → running (first callback via onItemResult)
 *   running → done (done + failed == total, done > 0)
 *   running → failed (done + failed == total, done == 0)
 *   any non-terminal → canceled
 *
 * alarm() → D1 flush (jobs_log + job_items_log INSERT) + UserLimiterDO.release()
 * 멱등성: RingBuffer(512) — seen_keys 테이블에 idempotency_key 저장
 */

import { DurableObject } from 'cloudflare:workers';
import type { Env, JobStatus, JobCoordinatorState, JobItemState, CallbackPayload } from '../_shared/types';
import type { UserLimiterDO } from './UserLimiterDO';

// ─── Constants ────────────────────────────────────────────────────────────────

const IDEMPOTENCY_RING_SIZE = 512;

const TERMINAL_STATUSES: ReadonlySet<string> = new Set(['done', 'failed', 'canceled']);

/** Valid FSM transitions: from → allowed targets */
const VALID_TRANSITIONS: Partial<Record<JobStatus, JobStatus[]>> = {
  created: ['uploaded', 'canceled'],
  uploaded: ['queued', 'canceled'],
  queued: ['running', 'canceled'],
  running: ['done', 'failed', 'canceled'],
};

// ─── Internal row shape (for TS typing outside of exec<>) ─────────────────────

interface JobStateRow {
  job_id: string;
  user_id: string;
  status: string;
  preset: string;
  concepts_json: string;
  protect_json: string;
  rule_id: string | null;
  total_items: number;
  done_items: number;
  failed_items: number;
  created_at: string;
  updated_at: string;
}

interface JobItemRow {
  idx: number;
  status: string;
  input_key: string;
  output_key: string;
  preview_key: string;
  error: string | null;
}

// ─── Durable Object ──────────────────────────────────────────────────────────

export class JobCoordinatorDO extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
    this.ctx.blockConcurrencyWhile(async () => {
      // job_state: single row per DO, holds FSM state + counters
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_state (
          job_id        TEXT PRIMARY KEY,
          user_id       TEXT NOT NULL,
          status        TEXT NOT NULL DEFAULT 'created',
          preset        TEXT NOT NULL,
          concepts_json TEXT NOT NULL DEFAULT '{}',
          protect_json  TEXT NOT NULL DEFAULT '[]',
          rule_id       TEXT,
          total_items   INTEGER NOT NULL,
          done_items    INTEGER NOT NULL DEFAULT 0,
          failed_items  INTEGER NOT NULL DEFAULT 0,
          created_at    TEXT NOT NULL,
          updated_at    TEXT NOT NULL
        )
      `);
      // job_items: one row per item (idx), tracks per-item result
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_items (
          job_id      TEXT NOT NULL,
          idx         INTEGER NOT NULL,
          status      TEXT NOT NULL DEFAULT 'pending',
          input_key   TEXT NOT NULL DEFAULT '',
          output_key  TEXT NOT NULL DEFAULT '',
          preview_key TEXT NOT NULL DEFAULT '',
          error       TEXT,
          PRIMARY KEY (job_id, idx)
        )
      `);
      // seen_keys: idempotency ring buffer (capacity: IDEMPOTENCY_RING_SIZE)
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS seen_keys (
          idempotency_key TEXT PRIMARY KEY,
          inserted_at     TEXT NOT NULL
        )
      `);
    });
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  private getJobState(): JobStateRow | null {
    // Use inline type for exec<> to satisfy Record<string, SqlStorageValue> constraint
    const rows = this.ctx.storage.sql
      .exec<{
        job_id: string;
        user_id: string;
        status: string;
        preset: string;
        concepts_json: string;
        protect_json: string;
        rule_id: string | null;
        total_items: number;
        done_items: number;
        failed_items: number;
        created_at: string;
        updated_at: string;
      }>(
        `SELECT job_id, user_id, status, preset, concepts_json, protect_json,
                rule_id, total_items, done_items, failed_items, created_at, updated_at
         FROM job_state
         LIMIT 1`,
      )
      .toArray();
    return rows.length > 0 ? (rows[0] as JobStateRow) : null;
  }

  private async transitionState(newStatus: JobStatus): Promise<boolean> {
    const row = this.getJobState();
    if (!row) {
      console.log(`[JobCoordinatorDO][transitionState] REJECTED to=${newStatus} reason=no_job_state`);
      return false;
    }

    const currentStatus = row.status as JobStatus;
    const allowed = VALID_TRANSITIONS[currentStatus];

    if (!allowed || !allowed.includes(newStatus)) {
      console.log(
        `[JobCoordinatorDO][transitionState] REJECTED from=${currentStatus} to=${newStatus} reason=invalid_transition`,
      );
      return false;
    }

    console.log(`[JobCoordinatorDO][transitionState] from=${currentStatus} to=${newStatus}`);

    this.ctx.storage.sql.exec(
      `UPDATE job_state SET status = ?, updated_at = ?`,
      newStatus,
      new Date().toISOString(),
    );

    console.log(
      `[JobCoordinatorDO][transitionState] done jobId=${row.job_id} from=${currentStatus} to=${newStatus}`,
    );
    return true;
  }

  // ─── create ─────────────────────────────────────────────────────────────────

  create(jobId: string, userId: string, preset: string, totalItems: number): void {
    console.log(
      `[JobCoordinatorDO][create] jobId=${jobId} userId=${userId} preset=${preset} totalItems=${totalItems}`,
    );

    const now = new Date().toISOString();
    this.ctx.storage.sql.exec(
      `INSERT OR IGNORE INTO job_state
         (job_id, user_id, status, preset, total_items, created_at, updated_at)
       VALUES (?, ?, 'created', ?, ?, ?, ?)`,
      jobId,
      userId,
      preset,
      totalItems,
      now,
      now,
    );

    for (let i = 0; i < totalItems; i++) {
      this.ctx.storage.sql.exec(
        `INSERT OR IGNORE INTO job_items (job_id, idx) VALUES (?, ?)`,
        jobId,
        i,
      );
    }

    console.log(`[JobCoordinatorDO][create] done jobId=${jobId} totalItems=${totalItems} status=created`);
  }

  // ─── confirmUpload (created → uploaded) ─────────────────────────────────────

  async confirmUpload(): Promise<{ success: boolean }> {
    const success = await this.transitionState('uploaded');
    return { success };
  }

  // ─── markQueued (uploaded → queued) ─────────────────────────────────────────

  async markQueued(
    conceptsJson: string,
    protectJson: string,
    ruleId?: string,
  ): Promise<{ success: boolean }> {
    const success = await this.transitionState('queued');
    if (success) {
      this.ctx.storage.sql.exec(
        `UPDATE job_state SET concepts_json = ?, protect_json = ?, rule_id = ?, updated_at = ?`,
        conceptsJson,
        protectJson,
        ruleId ?? null,
        new Date().toISOString(),
      );
    }
    return { success };
  }

  // ─── onItemResult / handleCallback ──────────────────────────────────────────

  async onItemResult(callback: CallbackPayload): Promise<{ success: boolean; duplicate: boolean }> {
    // 1. Idempotency check
    const existing = this.ctx.storage.sql
      .exec<{ idempotency_key: string }>(
        `SELECT idempotency_key FROM seen_keys WHERE idempotency_key = ?`,
        callback.idempotency_key,
      )
      .toArray();

    const isDuplicate = existing.length > 0;

    console.log(
      `[JobCoordinatorDO][handleCallback] idx=${callback.idx} status=${callback.status} idempotent=${isDuplicate} key=${callback.idempotency_key}`,
    );

    if (isDuplicate) {
      console.log(
        `[JobCoordinatorDO][handleCallback] skipped duplicate idx=${callback.idx} key=${callback.idempotency_key}`,
      );
      return { success: true, duplicate: true };
    }

    // 2. Maintain idempotency ring buffer — evict oldest if at capacity
    const countRows = this.ctx.storage.sql
      .exec<{ cnt: number }>(`SELECT COUNT(*) AS cnt FROM seen_keys`)
      .toArray();
    const currentCount = countRows[0]?.cnt ?? 0;

    if (currentCount >= IDEMPOTENCY_RING_SIZE) {
      this.ctx.storage.sql.exec(
        `DELETE FROM seen_keys
         WHERE idempotency_key = (
           SELECT idempotency_key FROM seen_keys ORDER BY inserted_at ASC LIMIT 1
         )`,
      );
    }

    this.ctx.storage.sql.exec(
      `INSERT INTO seen_keys (idempotency_key, inserted_at) VALUES (?, ?)`,
      callback.idempotency_key,
      new Date().toISOString(),
    );

    // 3. Get current job state for job_id reference
    const jobRow = this.getJobState();
    if (!jobRow) {
      return { success: false, duplicate: false };
    }

    // 4. Update item record
    this.ctx.storage.sql.exec(
      `UPDATE job_items
         SET status = ?, output_key = ?, preview_key = ?, error = ?
       WHERE job_id = ? AND idx = ?`,
      callback.status,
      callback.output_key ?? '',
      callback.preview_key ?? '',
      callback.error ?? null,
      jobRow.job_id,
      callback.idx,
    );

    // 5. Increment progress counter
    if (callback.status === 'done') {
      this.ctx.storage.sql.exec(
        `UPDATE job_state SET done_items = done_items + 1, updated_at = ?`,
        new Date().toISOString(),
      );
    } else {
      this.ctx.storage.sql.exec(
        `UPDATE job_state SET failed_items = failed_items + 1, updated_at = ?`,
        new Date().toISOString(),
      );
    }

    // 6. Transition queued → running on first callback arrival
    if (jobRow.status === 'queued') {
      await this.transitionState('running');
    }

    // 7. Check for terminal condition
    const updatedRow = this.getJobState();
    if (updatedRow && updatedRow.status === 'running') {
      const { total_items, done_items, failed_items } = updatedRow;
      if (done_items + failed_items >= total_items) {
        const finalStatus: JobStatus = done_items > 0 ? 'done' : 'failed';
        await this.transitionState(finalStatus);
        // Schedule D1 flush alarm with short delay to batch any in-flight callbacks
        await this.ctx.storage.setAlarm(Date.now() + 5_000);
      }
    }

    console.log(
      `[JobCoordinatorDO][handleCallback] processed idx=${callback.idx} status=${callback.status} jobId=${jobRow.job_id}`,
    );
    return { success: true, duplicate: false };
  }

  // ─── getStatus ──────────────────────────────────────────────────────────────

  getStatus(): { state: JobCoordinatorState; items: JobItemState[] } | null {
    const row = this.getJobState();
    if (!row) return null;

    const itemRows = this.ctx.storage.sql
      .exec<{
        idx: number;
        status: string;
        input_key: string;
        output_key: string;
        preview_key: string;
        error: string | null;
      }>(
        `SELECT idx, status, input_key, output_key, preview_key, error
         FROM job_items
         ORDER BY idx`,
      )
      .toArray() as JobItemRow[];

    const state: JobCoordinatorState = {
      jobId: row.job_id,
      userId: row.user_id,
      status: row.status as JobStatus,
      preset: row.preset,
      conceptsJson: row.concepts_json,
      protectJson: row.protect_json,
      ruleId: row.rule_id,
      totalItems: row.total_items,
      doneItems: row.done_items,
      failedItems: row.failed_items,
    };

    const items: JobItemState[] = itemRows.map((r) => ({
      idx: r.idx,
      status: r.status as 'pending' | 'done' | 'failed',
      inputKey: r.input_key,
      outputKey: r.output_key,
      previewKey: r.preview_key,
      ...(r.error !== null ? { error: r.error } : {}),
    }));

    return { state, items };
  }

  // ─── cancel (any non-terminal → canceled) ───────────────────────────────────

  async cancel(): Promise<{ success: boolean }> {
    const row = this.getJobState();
    if (!row || TERMINAL_STATUSES.has(row.status)) {
      return { success: false };
    }

    const success = await this.transitionState('canceled');
    if (success) {
      // Schedule D1 flush + release
      await this.ctx.storage.setAlarm(Date.now() + 5_000);
    }
    return { success };
  }

  // ─── alarm (D1 flush + UserLimiterDO.release) ────────────────────────────────

  async alarm(): Promise<void> {
    const row = this.getJobState();
    if (!row) {
      console.log('[JobCoordinatorDO][alarm] no job state found, skipping');
      return;
    }

    console.log(
      `[JobCoordinatorDO][alarm] flushing jobId=${row.job_id} status=${row.status} doneItems=${row.done_items} failedItems=${row.failed_items} totalItems=${row.total_items}`,
    );

    const now = new Date().toISOString();

    // ── D1 flush: jobs_log ──
    try {
      await this.env.DB.prepare(
        `INSERT OR REPLACE INTO jobs_log
           (job_id, user_id, status, preset, rule_id, concepts_json, protect_json, finished_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      )
        .bind(
          row.job_id,
          row.user_id,
          row.status,
          row.preset,
          row.rule_id,
          row.concepts_json,
          row.protect_json,
          now,
        )
        .run();

      console.log(`[JobCoordinatorDO][alarm] jobs_log flush done jobId=${row.job_id}`);
    } catch (e) {
      console.log(
        `[JobCoordinatorDO][alarm] jobs_log flush error jobId=${row.job_id} error=${String(e)}`,
      );
    }

    // ── D1 flush: job_items_log ──
    try {
      const itemRows = this.ctx.storage.sql
        .exec<{
          idx: number;
          status: string;
          input_key: string;
          output_key: string;
          preview_key: string;
          error: string | null;
        }>(
          `SELECT idx, status, input_key, output_key, preview_key, error
           FROM job_items
           ORDER BY idx`,
        )
        .toArray() as JobItemRow[];

      for (const item of itemRows) {
        await this.env.DB.prepare(
          `INSERT OR REPLACE INTO job_items_log
             (job_id, idx, status, input_key, output_key, error)
           VALUES (?, ?, ?, ?, ?, ?)`,
        )
          .bind(row.job_id, item.idx, item.status, item.input_key, item.output_key, item.error)
          .run();
      }

      console.log(
        `[JobCoordinatorDO][alarm] job_items_log flush done jobId=${row.job_id} itemCount=${itemRows.length}`,
      );
    } catch (e) {
      console.log(
        `[JobCoordinatorDO][alarm] job_items_log flush error jobId=${row.job_id} error=${String(e)}`,
      );
    }

    // ── UserLimiterDO.release (only for terminal states) ──
    if (TERMINAL_STATUSES.has(row.status)) {
      try {
        const limiterNs = this.env.USER_LIMITER as unknown as DurableObjectNamespace<UserLimiterDO>;
        const limiterStub = limiterNs.get(limiterNs.idFromName(row.user_id));
        await limiterStub.release(row.job_id);
        console.log(
          `[JobCoordinatorDO][alarm] UserLimiterDO.release done jobId=${row.job_id} userId=${row.user_id}`,
        );
      } catch (e) {
        console.log(
          `[JobCoordinatorDO][alarm] UserLimiterDO.release error jobId=${row.job_id} error=${String(e)}`,
        );
      }
    }

    console.log(`[JobCoordinatorDO][alarm] complete jobId=${row.job_id} status=${row.status}`);
  }
}
