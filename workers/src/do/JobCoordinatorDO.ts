/**
 * JobCoordinatorDO — job당 1개 Durable Object
 *
 * SQLite-backed FSM + 멱등성 Ring Buffer (size 512) + Alarm D1 flush
 *
 * 상태머신:
 *   created → uploaded (confirmUpload)
 *   uploaded → queued (markQueued + Queue push)
 *   queued → running (첫 callback 도착)
 *   running → done (done + failed == total)
 *   running → failed (failed > threshold)
 *   any non-terminal → canceled
 *
 * alarm() → D1 flush (jobs_log + job_items_log INSERT) + UserLimiterDO.release()
 * 멱등성: RingBuffer(512) — seen_keys 테이블에 idempotency_key 저장
 */

import { DurableObject } from 'cloudflare:workers';
import type { CallbackPayload, Env, JobCoordinatorState, JobItemState, JobStatus } from '../_shared/types';

// Maximum idempotency ring buffer size
const SEEN_KEYS_MAX = 512;

export class JobCoordinatorDO extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);

    // Initialize SQLite tables synchronously inside blockConcurrencyWhile.
    // sql.exec() is a SYNCHRONOUS method — no await needed or desired.
    // Using await here would introduce unnecessary microtask suspension points
    // inside blockConcurrencyWhile, potentially violating DO's single-thread model.
    this.ctx.blockConcurrencyWhile(async () => {
      // Table 1: Single-row FSM state for this job
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_state (
          job_id        TEXT NOT NULL,
          user_id       TEXT NOT NULL,
          status        TEXT NOT NULL DEFAULT 'created'
                        CHECK(status IN ('created','uploaded','queued','running','done','failed','canceled')),
          preset        TEXT NOT NULL DEFAULT '',
          concepts_json TEXT NOT NULL DEFAULT '{}',
          protect_json  TEXT NOT NULL DEFAULT '[]',
          rule_id       TEXT,
          total_items   INTEGER NOT NULL DEFAULT 0,
          done_items    INTEGER NOT NULL DEFAULT 0,
          failed_items  INTEGER NOT NULL DEFAULT 0,
          created_at    TEXT NOT NULL,
          finished_at   TEXT
        )
      `);

      // Table 2: Per-item tracking (output_key/preview_key nullable — set by callback)
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_items (
          idx         INTEGER PRIMARY KEY,
          status      TEXT NOT NULL DEFAULT 'pending'
                      CHECK(status IN ('pending','done','failed')),
          input_key   TEXT NOT NULL,
          output_key  TEXT,
          preview_key TEXT,
          error       TEXT
        )
      `);

      // Table 3: Idempotency ring buffer (max SEEN_KEYS_MAX=512 entries)
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS seen_keys (
          idempotency_key TEXT PRIMARY KEY,
          inserted_at     INTEGER NOT NULL
        )
      `);
    });
  }

  // ─── FSM helper ─────────────────────────────────────────────────────────────

  /**
   * Validates and executes a state transition.
   * Returns the current status row, or throws if the transition is invalid.
   */
  private transitionState(
    from: JobStatus[],
    to: JobStatus,
    finishedAt?: string
  ): { status: JobStatus } {
    const cursor = this.ctx.storage.sql.exec(
      'SELECT status FROM job_state LIMIT 1'
    );
    const row = cursor.toArray()[0] as { status: JobStatus } | undefined;
    if (!row) throw new Error('Job not initialized');

    if (!from.includes(row.status)) {
      throw new Error(`INVALID_STATE_TRANSITION: ${row.status} → ${to}`);
    }

    if (finishedAt) {
      this.ctx.storage.sql.exec(
        'UPDATE job_state SET status = ?1, finished_at = ?2',
        to,
        finishedAt
      );
    } else {
      this.ctx.storage.sql.exec(
        'UPDATE job_state SET status = ?1',
        to
      );
    }

    return { status: to };
  }

  // ─── Public methods (called via DO fetch handler) ────────────────────────────

  /**
   * create(jobId, userId, preset, totalItems)
   * Inserts the initial job_state row and populates job_items with pending rows.
   * Transitions: (no prior state) → 'created'
   */
  async create(
    jobId: string,
    userId: string,
    preset: string,
    totalItems: number
  ): Promise<void> {
    const now = new Date().toISOString();

    // Insert single job_state row
    this.ctx.storage.sql.exec(
      `INSERT INTO job_state
         (job_id, user_id, status, preset, total_items, created_at)
       VALUES (?1, ?2, 'created', ?3, ?4, ?5)`,
      jobId,
      userId,
      preset,
      totalItems,
      now
    );

    // Populate job_items — output_key/preview_key start as NULL
    for (let idx = 0; idx < totalItems; idx++) {
      this.ctx.storage.sql.exec(
        `INSERT INTO job_items (idx, status, input_key, output_key, preview_key)
         VALUES (?1, 'pending', ?2, NULL, NULL)`,
        idx,
        `jobs/${jobId}/input/${idx}`
      );
    }
  }

  /**
   * confirmUpload()
   * Transitions: created → uploaded
   */
  async confirmUpload(): Promise<void> {
    this.transitionState(['created'], 'uploaded');
  }

  /**
   * markQueued(conceptsJson, protectJson, ruleId?)
   * Transitions: uploaded → queued
   */
  async markQueued(
    conceptsJson: string,
    protectJson: string,
    ruleId?: string | null
  ): Promise<void> {
    this.transitionState(['uploaded'], 'queued');

    this.ctx.storage.sql.exec(
      'UPDATE job_state SET concepts_json = ?1, protect_json = ?2, rule_id = ?3',
      conceptsJson,
      protectJson,
      ruleId ?? null
    );
  }

  /**
   * handleCallback(payload)
   * Processes a GPU worker callback for a single item.
   * Returns true if the callback was processed, false if discarded (duplicate/terminal).
   */
  async handleCallback(payload: CallbackPayload): Promise<boolean> {
    // GUARD: discard callbacks when job is already in a terminal state.
    // DO serializes all fetch requests, so this sequential check is sufficient
    // to prevent race conditions between /cancel and GPU callbacks.
    const statusCursor = this.ctx.storage.sql.exec(
      'SELECT status FROM job_state LIMIT 1'
    );
    const statusRow = statusCursor.toArray()[0] as { status: JobStatus } | undefined;

    if (!statusRow) {
      return false;
    }

    if (
      statusRow.status === 'canceled' ||
      statusRow.status === 'done' ||
      statusRow.status === 'failed'
    ) {
      return false;
    }

    // Idempotency check — has this key been processed before?
    const checkCursor = this.ctx.storage.sql.exec(
      'SELECT idempotency_key FROM seen_keys WHERE idempotency_key = ?1',
      payload.idempotency_key
    );

    if (checkCursor.toArray().length > 0) {
      return false;
    }

    // Record idempotency key (ring buffer eviction if over limit)
    this.ctx.storage.sql.exec(
      'INSERT INTO seen_keys (idempotency_key, inserted_at) VALUES (?1, ?2)',
      payload.idempotency_key,
      Date.now()
    );

    // Evict oldest entries if ring buffer exceeds max
    const countCursor = this.ctx.storage.sql.exec(
      'SELECT COUNT(*) as cnt FROM seen_keys'
    );
    const countRow = countCursor.toArray()[0] as { cnt: number } | undefined;
    if (countRow && countRow.cnt > SEEN_KEYS_MAX) {
      this.ctx.storage.sql.exec(
        `DELETE FROM seen_keys WHERE idempotency_key IN (
           SELECT idempotency_key FROM seen_keys
           ORDER BY inserted_at ASC
           LIMIT ?1
         )`,
        countRow.cnt - SEEN_KEYS_MAX
      );
    }

    // Update the item record — output_key/preview_key stored as null if absent
    this.ctx.storage.sql.exec(
      `UPDATE job_items
       SET status = ?1, output_key = ?2, preview_key = ?3, error = ?4
       WHERE idx = ?5`,
      payload.status,
      payload.output_key || null,
      payload.preview_key || null,
      payload.error || null,
      payload.idx
    );

    // Update progress counters
    if (payload.status === 'done') {
      this.ctx.storage.sql.exec(
        'UPDATE job_state SET done_items = done_items + 1'
      );
    } else {
      this.ctx.storage.sql.exec(
        'UPDATE job_state SET failed_items = failed_items + 1'
      );
    }

    // Check if all items are accounted for
    const progressCursor = this.ctx.storage.sql.exec(
      'SELECT total_items, done_items, failed_items FROM job_state LIMIT 1'
    );
    const progress = progressCursor.toArray()[0] as {
      total_items: number;
      done_items: number;
      failed_items: number;
    } | undefined;

    if (progress && progress.done_items + progress.failed_items >= progress.total_items) {
      const finalStatus: JobStatus =
        progress.failed_items > 0 ? 'failed' : 'done';
      const finishedAt = new Date().toISOString();

      this.transitionState(
        ['queued', 'running'],
        finalStatus,
        finishedAt
      );

      // Trigger alarm for D1 flush
      await this.ctx.storage.setAlarm(Date.now() + 1000);
    } else if (statusRow.status === 'queued') {
      // First callback — transition to running
      this.transitionState(['queued'], 'running');
    }

    return true;
  }

  /**
   * cancel()
   * Transitions any non-terminal state → 'canceled'.
   * Triggers alarm for D1 flush.
   */
  async cancel(): Promise<void> {
    const nonTerminal: JobStatus[] = ['created', 'uploaded', 'queued', 'running'];
    this.transitionState(nonTerminal, 'canceled', new Date().toISOString());
    await this.ctx.storage.setAlarm(Date.now() + 1000);
  }

  /**
   * getState()
   * Returns the full JobCoordinatorState + items array.
   */
  async getState(): Promise<{ state: JobCoordinatorState; items: JobItemState[] } | null> {
    const stateCursor = this.ctx.storage.sql.exec(
      `SELECT job_id, user_id, status, preset, concepts_json, protect_json,
              rule_id, total_items, done_items, failed_items
       FROM job_state LIMIT 1`
    );
    const stateRows = stateCursor.toArray() as Array<{
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
    }>;

    if (stateRows.length === 0) return null;

    const s = stateRows[0];

    const itemsCursor = this.ctx.storage.sql.exec(
      'SELECT idx, status, input_key, output_key, preview_key, error FROM job_items ORDER BY idx'
    );
    const itemRows = itemsCursor.toArray() as Array<{
      idx: number;
      status: string;
      input_key: string;
      output_key: string | null;
      preview_key: string | null;
      error: string | null;
    }>;

    const state: JobCoordinatorState = {
      jobId: s.job_id,
      userId: s.user_id,
      status: s.status as JobStatus,
      preset: s.preset,
      conceptsJson: s.concepts_json,
      protectJson: s.protect_json,
      ruleId: s.rule_id,
      totalItems: s.total_items,
      doneItems: s.done_items,
      failedItems: s.failed_items,
    };

    const items: JobItemState[] = itemRows.map((r) => ({
      idx: r.idx,
      status: r.status as 'pending' | 'done' | 'failed',
      inputKey: r.input_key,
      outputKey: r.output_key ?? '',
      previewKey: r.preview_key ?? '',
      error: r.error ?? undefined,
    }));

    return { state, items };
  }

  // ─── Alarm handler ───────────────────────────────────────────────────────────

  /**
   * alarm()
   * Triggered after job reaches a terminal state (done/failed/canceled).
   * Step 1: D1 batch flush — throws on failure (CF retries alarm; INSERT OR REPLACE is idempotent).
   * Step 2: UserLimiterDO.release() — retried up to 3 times with exponential backoff.
   *         On persistent failure, sends a DLQ message to GPU_QUEUE and logs the error.
   *         Does NOT throw (D1 flush already succeeded; re-throwing causes duplicate flush risk).
   */
  async alarm(): Promise<void> {
    // Step 1: Read job state
    const stateCursor = this.ctx.storage.sql.exec(
      `SELECT job_id, user_id, status, preset, concepts_json, protect_json,
              rule_id, total_items, done_items, failed_items, created_at, finished_at
       FROM job_state LIMIT 1`
    );
    const stateRows = stateCursor.toArray() as Array<{
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
      finished_at: string | null;
    }>;

    if (stateRows.length === 0) return;

    const jobState = stateRows[0];

    // Step 2: Read all items
    const itemsCursor = this.ctx.storage.sql.exec(
      'SELECT idx, status, input_key, output_key, preview_key, error FROM job_items ORDER BY idx'
    );
    const items = itemsCursor.toArray() as Array<{
      idx: number;
      status: string;
      input_key: string;
      output_key: string | null;
      preview_key: string | null;
      error: string | null;
    }>;

    // Step 3: D1 atomic batch flush
    const batchStatements: D1PreparedStatement[] = [];

    batchStatements.push(
      this.env.DB.prepare(
        `INSERT OR REPLACE INTO jobs_log
           (job_id, user_id, created_at, finished_at, status, preset,
            rule_id, concepts_json, protect_json)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)`
      ).bind(
        jobState.job_id,
        jobState.user_id,
        jobState.created_at,
        jobState.finished_at,
        jobState.status,
        jobState.preset,
        jobState.rule_id,
        jobState.concepts_json,
        jobState.protect_json
      )
    );

    for (const item of items) {
      batchStatements.push(
        this.env.DB.prepare(
          `INSERT OR REPLACE INTO job_items_log
             (job_id, idx, status, input_key, output_key, error)
           VALUES (?1, ?2, ?3, ?4, ?5, ?6)`
        ).bind(
          jobState.job_id,
          item.idx,
          item.status,
          item.input_key,
          item.output_key,
          item.error
        )
      );
    }

    try {
      await this.env.DB.batch(batchStatements);
    } catch (dbError) {
      // D1 flush failed → throw so CF retries the alarm (INSERT OR REPLACE is idempotent)
      console.error('[alarm] D1 batch flush failed:', dbError);
      throw dbError;
    }

    // Step 4: UserLimiterDO.release() with retry + DLQ fallback
    const userLimiterId = this.env.USER_LIMITER.idFromName(jobState.user_id);
    const userLimiterStub = this.env.USER_LIMITER.get(userLimiterId);

    const MAX_RETRIES = 3;
    let releaseError: Error | null = null;

    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
      try {
        const releaseResp = await userLimiterStub.fetch('http://internal/release', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            jobId: jobState.job_id,
            doneItems: jobState.done_items,
            totalItems: jobState.total_items,
          }),
        });

        if (releaseResp.ok) {
          releaseError = null;
          break;
        }

        releaseError = new Error(
          `UserLimiterDO.release() HTTP ${releaseResp.status} on attempt ${attempt}`
        );
      } catch (fetchError) {
        releaseError = fetchError instanceof Error
          ? fetchError
          : new Error(String(fetchError));
      }

      // Exponential backoff: 100ms → 200ms → 400ms
      if (attempt < MAX_RETRIES) {
        await new Promise<void>((r) => setTimeout(r, 100 * Math.pow(2, attempt - 1)));
      }
    }

    if (releaseError) {
      // 3 attempts all failed → send DLQ message to GPU_QUEUE for ops monitoring
      try {
        await this.env.GPU_QUEUE.send({
          type: 'release-failed',
          jobId: jobState.job_id,
          userId: jobState.user_id,
          doneItems: jobState.done_items,
          totalItems: jobState.total_items,
          error: releaseError.message,
          timestamp: Date.now(),
        } as any);
      } catch (dlqError) {
        console.error('[alarm] DLQ send also failed:', dlqError);
      }
      // Do NOT throw — D1 flush already succeeded; throwing would cause duplicate flush on retry
      console.error(
        `[alarm] release() failed after ${MAX_RETRIES} retries for job ${jobState.job_id}:`,
        releaseError.message
      );
    }
  }

  // ─── HTTP fetch handler ──────────────────────────────────────────────────────

  /**
   * fetch() — routes incoming HTTP requests to the appropriate method.
   * Cloudflare DO serializes all incoming fetch calls, ensuring single-threaded execution.
   */
  override async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    try {
      if (request.method === 'POST' && path === '/create') {
        const body = await request.json() as {
          jobId: string;
          userId: string;
          preset: string;
          totalItems: number;
        };
        await this.create(body.jobId, body.userId, body.preset, body.totalItems);
        return Response.json({ ok: true });
      }

      if (request.method === 'POST' && path === '/confirm-upload') {
        await this.confirmUpload();
        return Response.json({ ok: true });
      }

      if (request.method === 'POST' && path === '/mark-queued') {
        const body = await request.json() as {
          conceptsJson: string;
          protectJson: string;
          ruleId?: string | null;
        };
        await this.markQueued(body.conceptsJson, body.protectJson, body.ruleId);
        return Response.json({ ok: true });
      }

      if (request.method === 'POST' && path === '/callback') {
        const payload = await request.json() as CallbackPayload;
        const processed = await this.handleCallback(payload);
        return Response.json({ processed });
      }

      if (request.method === 'POST' && path === '/cancel') {
        await this.cancel();
        return Response.json({ ok: true });
      }

      if (request.method === 'GET' && path === '/state') {
        const result = await this.getState();
        return Response.json(result);
      }

      return new Response('Not Found', { status: 404 });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      const status = message.startsWith('INVALID_STATE_TRANSITION') ? 400 : 500;
      return Response.json({ error: message }, { status });
    }
  }
}
