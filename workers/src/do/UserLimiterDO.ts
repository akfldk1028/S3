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
  // TODO: implement SQLite-backed state management
}
