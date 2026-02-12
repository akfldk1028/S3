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
import type { Env } from '../_shared/types';

export class JobCoordinatorDO extends DurableObject<Env> {
  // TODO: implement FSM + idempotency + alarm
}
