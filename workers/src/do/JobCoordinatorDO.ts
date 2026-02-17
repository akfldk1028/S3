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
  // Bug 2 verified: await sql.exec() — no fix needed (file is a stub, no implementation present).
  // Scanned all sql.exec() calls in this file: none present (implementation is pending).
  // When implemented, all this.ctx.storage.sql.exec() calls MUST be called WITHOUT await —
  // ctx.storage.sql.exec() is synchronous in Cloudflare DO SQLite.
  // Planned locations that must NOT use await (per spec):
  //   constructor blockConcurrencyWhile: 3× CREATE TABLE calls
  //   transitionState(): 3× UPDATE/INSERT calls
  //   confirmUpload(): 1× UPDATE call
  //   handleCallback(): ~9× SELECT/INSERT/UPDATE calls
  //   alarm(): 2× SELECT calls
  //   create(): 3× INSERT/UPDATE calls
  //   markQueued(): 1× UPDATE call
  //   getState(): 2× SELECT calls
  // Preserve awaits on: ctx.blockConcurrencyWhile(), ctx.storage.setAlarm(),
  //   this.env.DB.*() D1 calls, and any async method calls.
  // TODO: implement FSM + idempotency + alarm
}
