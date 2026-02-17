/**
 * JobCoordinatorDO — job당 1개 Durable Object
 *
 * SQLite-backed FSM + 멱등성 Ring Buffer (size 512) + Alarm D1 flush
 *
 * - blockConcurrencyWhile → SQLite 초기화 (job_state, job_items, seen_keys 테이블)
 * - FSM transitions:
 *   - create(jobId, userId, preset, totalItems) → 'created'
 *   - markUploaded() → 'uploaded'
 *   - markQueued(conceptsJson, protectJson, ruleId?) → 'queued'
 *   - onItemResult(callback: CallbackPayload) → 멱등성 체크 → 진행률 갱신
 *   - getStatus() → JobCoordinatorState + items
 *   - cancel() → 'canceled'
 * - 상태머신:
 *   created → uploaded (confirmUpload)
 *   uploaded → queued (execute + Queue push)
 *   queued → running (첫 callback 도착)
 *   running → done (done + failed == total)
 *   running → failed (failed > threshold)
 *   any non-terminal → canceled
 * - alarm() → D1 flush (jobs_log + job_items_log INSERT) + UserLimiterDO.release()
 * - 멱등성: RingBuffer(512) — seen_keys 테이블에 idempotency_key 저장
 */

import { DurableObject } from 'cloudflare:workers';
import type { CallbackPayload, Env, JobCoordinatorState, JobItemState, JobStatus } from '../_shared/types';
import { getUserLimiterStub } from './do.helpers';

const IDEMPOTENCY_RING_SIZE = 512;

export class JobCoordinatorDO extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);

    // SQLite 테이블 초기화 — DO 첫 활성화 시 한 번만 실행
    this.ctx.blockConcurrencyWhile(async () => {
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_state (
          job_id        TEXT PRIMARY KEY,
          user_id       TEXT NOT NULL,
          status        TEXT NOT NULL DEFAULT 'created',
          preset        TEXT NOT NULL DEFAULT '',
          concepts_json TEXT NOT NULL DEFAULT '{}',
          protect_json  TEXT NOT NULL DEFAULT '[]',
          rule_id       TEXT,
          total_items   INTEGER NOT NULL DEFAULT 0,
          done_items    INTEGER NOT NULL DEFAULT 0,
          failed_items  INTEGER NOT NULL DEFAULT 0
        )
      `);

      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_items (
          idx         INTEGER PRIMARY KEY,
          status      TEXT    NOT NULL DEFAULT 'pending',
          input_key   TEXT    NOT NULL DEFAULT '',
          output_key  TEXT    NOT NULL DEFAULT '',
          preview_key TEXT    NOT NULL DEFAULT '',
          error       TEXT
        )
      `);

      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS seen_keys (
          idempotency_key TEXT PRIMARY KEY,
          ring_pos        INTEGER NOT NULL
        )
      `);
    });
  }

  // ─── fetch 핸들러 (HTTP 라우팅) ──────────────────────────

  override async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    try {
      if (path === '/create' && request.method === 'POST') {
        return await this._handleCreate(request);
      }
      if (path === '/markUploaded' && request.method === 'POST') {
        return await this._handleMarkUploaded();
      }
      if (path === '/markQueued' && request.method === 'POST') {
        return await this._handleMarkQueued(request);
      }
      if (path === '/onItemResult' && request.method === 'POST') {
        return await this._handleOnItemResult(request);
      }
      if (path === '/getStatus' && request.method === 'GET') {
        return await this._handleGetStatus();
      }
      if (path === '/cancel' && request.method === 'POST') {
        return await this._handleCancel();
      }

      return new Response(JSON.stringify({ error: 'Not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal error';
      return new Response(JSON.stringify({ error: message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }
  }

  // ─── Alarm: D1 flush + UserLimiterDO.release() ──────────

  /**
   * alarm() — D1에 jobs_log + job_items_log를 INSERT하고,
   * [CRED-2] UserLimiterDO /release를 failedItems 포함한 새 시그니처로 호출.
   */
  override async alarm(): Promise<void> {
    const jobState = this._readJobState();
    if (!jobState) return;

    // D1 flush — jobs_log INSERT
    try {
      await this.env.DB.prepare(
        `INSERT OR IGNORE INTO jobs_log
         (job_id, user_id, status, preset, total_items, done_items, failed_items)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
      )
        .bind(
          jobState.jobId,
          jobState.userId,
          jobState.status,
          jobState.preset,
          jobState.totalItems,
          jobState.doneItems,
          jobState.failedItems,
        )
        .run();
    } catch (_err) {
      // D1 flush 실패는 치명적이지 않음 — 다음 alarm에서 재시도
    }

    // D1 flush — job_items_log INSERT
    try {
      const items = this._readJobItems();
      for (const item of items) {
        await this.env.DB.prepare(
          `INSERT OR IGNORE INTO job_items_log
           (job_id, idx, status, input_key, output_key, preview_key, error)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
        )
          .bind(
            jobState.jobId,
            item.idx,
            item.status,
            item.inputKey,
            item.outputKey,
            item.previewKey,
            item.error ?? null,
          )
          .run();
      }
    } catch (_err) {
      // D1 flush 실패는 치명적이지 않음 — 다음 alarm에서 재시도
    }

    // [CRED-2] UserLimiterDO /release — failedItems 포함하여 새 시그니처와 일치
    const limiterStub = getUserLimiterStub(this.env, jobState.userId);
    await limiterStub.fetch('http://do/release', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        doneItems: jobState.doneItems,
        failedItems: jobState.failedItems,
        totalItems: jobState.totalItems,
      }),
    });
  }

  // ─── 핸들러 구현 ─────────────────────────────────────────

  /**
   * POST /create — jobId, userId, preset, totalItems로 초기 상태 생성.
   */
  private async _handleCreate(request: Request): Promise<Response> {
    const { jobId, userId, preset, totalItems } = await request.json<{
      jobId: string;
      userId: string;
      preset: string;
      totalItems: number;
    }>();

    this.ctx.storage.sql.exec(
      `INSERT OR IGNORE INTO job_state (job_id, user_id, status, preset, total_items)
       VALUES (?, ?, 'created', ?, ?)`,
      jobId,
      userId,
      preset,
      totalItems,
    );

    return new Response(JSON.stringify({ success: true, status: 'created' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * POST /markUploaded — 'created' → 'uploaded'.
   */
  private async _handleMarkUploaded(): Promise<Response> {
    const state = this._readJobState();
    if (!state) {
      return new Response(JSON.stringify({ error: 'Job not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (state.status !== 'created') {
      return new Response(
        JSON.stringify({ error: `Invalid transition: ${state.status} → uploaded` }),
        { status: 409, headers: { 'Content-Type': 'application/json' } },
      );
    }

    this.ctx.storage.sql.exec(
      `UPDATE job_state SET status = 'uploaded' WHERE job_id = ?`,
      state.jobId,
    );

    return new Response(JSON.stringify({ success: true, status: 'uploaded' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * POST /markQueued — 'uploaded' → 'queued', conceptsJson + protectJson + ruleId? 설정.
   */
  private async _handleMarkQueued(request: Request): Promise<Response> {
    const { conceptsJson, protectJson, ruleId } = await request.json<{
      conceptsJson: string;
      protectJson: string;
      ruleId?: string;
    }>();

    const state = this._readJobState();
    if (!state) {
      return new Response(JSON.stringify({ error: 'Job not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (state.status !== 'uploaded') {
      return new Response(
        JSON.stringify({ error: `Invalid transition: ${state.status} → queued` }),
        { status: 409, headers: { 'Content-Type': 'application/json' } },
      );
    }

    this.ctx.storage.sql.exec(
      `UPDATE job_state
       SET status = 'queued', concepts_json = ?, protect_json = ?, rule_id = ?
       WHERE job_id = ?`,
      conceptsJson,
      protectJson,
      ruleId ?? null,
      state.jobId,
    );

    return new Response(JSON.stringify({ success: true, status: 'queued' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * POST /onItemResult — 멱등성 체크 후 아이템 결과 반영 및 FSM 진행.
   * RingBuffer(512) 기반 중복 차단.
   */
  private async _handleOnItemResult(request: Request): Promise<Response> {
    const callback = await request.json<CallbackPayload>();
    const state = this._readJobState();

    if (!state) {
      return new Response(JSON.stringify({ error: 'Job not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 멱등성 체크 — seen_keys RingBuffer
    if (this._isSeenKey(callback.idempotency_key)) {
      return new Response(JSON.stringify({ success: true, duplicate: true }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }
    this._recordSeenKey(callback.idempotency_key);

    // 아이템 상태 업데이트
    this.ctx.storage.sql.exec(
      `UPDATE job_items
       SET status = ?, output_key = ?, preview_key = ?, error = ?
       WHERE idx = ?`,
      callback.status,
      callback.output_key ?? '',
      callback.preview_key ?? '',
      callback.error ?? null,
      callback.idx,
    );

    // 진행률 갱신
    const column = callback.status === 'done' ? 'done_items' : 'failed_items';
    this.ctx.storage.sql.exec(
      `UPDATE job_state SET ${column} = ${column} + 1 WHERE job_id = ?`,
      state.jobId,
    );

    // FSM 전환: queued → running (첫 callback)
    if (state.status === 'queued') {
      this.ctx.storage.sql.exec(
        `UPDATE job_state SET status = 'running' WHERE job_id = ?`,
        state.jobId,
      );
    }

    // 완료 여부 체크 — 최신 상태 재조회
    const updated = this._readJobState();
    if (updated && updated.status === 'running') {
      const allProcessed = updated.doneItems + updated.failedItems >= updated.totalItems;
      if (allProcessed) {
        const newStatus: JobStatus = updated.failedItems > 0 ? 'failed' : 'done';
        this.ctx.storage.sql.exec(
          `UPDATE job_state SET status = ? WHERE job_id = ?`,
          newStatus,
          updated.jobId,
        );
        // alarm 스케줄 — D1 flush + release
        await this.ctx.storage.setAlarm(Date.now() + 1000);
      }
    }

    return new Response(JSON.stringify({ success: true, duplicate: false }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * GET /getStatus — 현재 job 상태 + 아이템 목록 반환.
   */
  private async _handleGetStatus(): Promise<Response> {
    const state = this._readJobState();
    if (!state) {
      return new Response(JSON.stringify({ error: 'Job not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const items = this._readJobItems();
    return new Response(JSON.stringify({ ...state, items }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * POST /cancel — 비종료 상태 → 'canceled'.
   */
  private async _handleCancel(): Promise<Response> {
    const state = this._readJobState();
    if (!state) {
      return new Response(JSON.stringify({ error: 'Job not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (this._isTerminalStatus(state.status)) {
      return new Response(
        JSON.stringify({ error: `Cannot cancel terminal status: ${state.status}` }),
        { status: 409, headers: { 'Content-Type': 'application/json' } },
      );
    }

    this.ctx.storage.sql.exec(
      `UPDATE job_state SET status = 'canceled' WHERE job_id = ?`,
      state.jobId,
    );

    return new Response(JSON.stringify({ success: true, status: 'canceled' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // ─── 내부 헬퍼 ───────────────────────────────────────────

  private _readJobState(): JobCoordinatorState | null {
    const cursor = this.ctx.storage.sql.exec<{
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
    }>(`SELECT * FROM job_state LIMIT 1`);

    const rows = [...cursor];
    if (rows.length === 0) return null;

    const row = rows[0];
    return {
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
  }

  private _readJobItems(): JobItemState[] {
    const cursor = this.ctx.storage.sql.exec<{
      idx: number;
      status: string;
      input_key: string;
      output_key: string;
      preview_key: string;
      error: string | null;
    }>(`SELECT * FROM job_items ORDER BY idx ASC`);

    return [...cursor].map((row) => ({
      idx: row.idx,
      status: row.status as 'pending' | 'done' | 'failed',
      inputKey: row.input_key,
      outputKey: row.output_key,
      previewKey: row.preview_key,
      error: row.error ?? undefined,
    }));
  }

  private _isTerminalStatus(status: JobStatus): boolean {
    return status === 'done' || status === 'failed' || status === 'canceled';
  }

  private _isSeenKey(key: string): boolean {
    const cursor = this.ctx.storage.sql.exec<{ idempotency_key: string }>(
      `SELECT idempotency_key FROM seen_keys WHERE idempotency_key = ? LIMIT 1`,
      key,
    );
    return [...cursor].length > 0;
  }

  private _recordSeenKey(key: string): void {
    // RingBuffer: 총 개수 조회 후 오래된 항목 교체
    const countCursor = this.ctx.storage.sql.exec<{ cnt: number }>(
      `SELECT COUNT(*) as cnt FROM seen_keys`,
    );
    const count = [...countCursor][0]?.cnt ?? 0;
    const pos = count % IDEMPOTENCY_RING_SIZE;

    if (count >= IDEMPOTENCY_RING_SIZE) {
      // 가장 오래된 pos 위치의 항목 삭제 후 새 항목 삽입
      this.ctx.storage.sql.exec(
        `DELETE FROM seen_keys WHERE ring_pos = ?`,
        pos,
      );
    }

    this.ctx.storage.sql.exec(
      `INSERT INTO seen_keys (idempotency_key, ring_pos) VALUES (?, ?)`,
      key,
      pos,
    );
  }
}
