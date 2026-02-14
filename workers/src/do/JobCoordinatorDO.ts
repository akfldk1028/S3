/**
 * JobCoordinatorDO — job당 1개 Durable Object
 *
 * SQLite-backed FSM + 멱등성 Ring Buffer (size 512) + Alarm D1 flush
 *
 * TODO: Auto-Claude 구현
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
import type { Env, JobCoordinatorState, JobItemState, JobStatus } from '../_shared/types';

export class JobCoordinatorDO extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);

    // CRITICAL: Use blockConcurrencyWhile for schema initialization to prevent race conditions
    this.ctx.blockConcurrencyWhile(async () => {
      // Job state table - stores FSM state and progress
      await this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_state (
          job_id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          status TEXT NOT NULL CHECK(status IN ('created', 'uploaded', 'queued', 'running', 'done', 'failed', 'canceled')),
          preset TEXT NOT NULL,
          concepts_json TEXT NOT NULL DEFAULT '{}',
          protect_json TEXT NOT NULL DEFAULT '[]',
          rule_id TEXT,
          total_items INTEGER NOT NULL DEFAULT 0,
          done_items INTEGER NOT NULL DEFAULT 0,
          failed_items INTEGER NOT NULL DEFAULT 0
        );
      `);

      // Job items table - stores individual item states
      await this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_items (
          idx INTEGER PRIMARY KEY,
          status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'done', 'failed')),
          input_key TEXT NOT NULL,
          output_key TEXT NOT NULL,
          preview_key TEXT NOT NULL,
          error TEXT
        );
      `);

      // Idempotency RingBuffer - stores last 512 callback keys to prevent duplicate processing
      await this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS seen_keys (
          idempotency_key TEXT PRIMARY KEY,
          timestamp INTEGER NOT NULL
        );
      `);
    });
  }

  // TODO: implement FSM + idempotency + alarm
}
