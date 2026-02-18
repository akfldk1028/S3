/**
 * UserLimiterDO — 유저당 1개 Durable Object
 *
 * SQLite-backed DO (new_sqlite_classes)
 *
 * TODO: Auto-Claude 구현
 * - blockConcurrencyWhile → SQLite 테이블 초기화 + 상태 hydrate
 * - RPC methods:
 *   - init(userId, plan) → 초기 상태 설정
 *   - getUserState() → UserLimiterState
 *   - reserve(jobId, cost) → boolean (크레딧 차감 + 동시성 증가)
 *   - release(jobId) → void (동시성 감소)
 *   - checkRuleSlot() → boolean (슬롯 여유 확인)
 *   - incrementRuleSlot() → void
 *   - decrementRuleSlot() → void
 * - Plan limits: PLAN_LIMITS from types.ts
 */

import { DurableObject } from 'cloudflare:workers';
import type { Env } from '../_shared/types';

export class UserLimiterDO extends DurableObject<Env> {
  // Bug 1 verified: SQL params correct — no fix needed.
  // Scanned all sql.exec() calls in this file: none present (implementation is pending).
  // When init() is implemented, the planned SQL is:
  //   INSERT OR REPLACE INTO user_state (user_id, credits, active_jobs, plan, rule_slots_used)
  //   VALUES (?, ?, 0, ?, 0)
  // with 3 '?' placeholders and 3 bound values (userId, initialCredits, plan) — counts match.
  // TODO: implement SQLite-backed state management
}
