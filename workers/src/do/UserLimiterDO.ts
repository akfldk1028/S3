/**
 * UserLimiterDO — 유저당 1개 Durable Object
 *
 * SQLite-backed DO (new_sqlite_classes)
 *
 * - blockConcurrencyWhile → SQLite 테이블 초기화
 * - RPC methods:
 *   - init(userId, plan) → 초기 상태 설정 (INSERT OR IGNORE — 기존 크레딧 보존)
 *   - getUserState() → UserLimiterState
 *   - reserve(jobId, itemCount) → { allowed: boolean; reason?: string }
 *   - commit(jobId) → void (크레딧 확정 — 예약 레코드 삭제)
 *   - rollback(jobId) → void (크레딧 환불)
 *   - release(jobId) → void (동시성 감소)
 *   - checkRuleSlot() → boolean (슬롯 여유 확인)
 *   - incrementRuleSlot() → void
 *   - decrementRuleSlot() → void
 * - Plan limits: PLAN_LIMITS from types.ts
 */

import { DurableObject } from 'cloudflare:workers';
import type { Env, UserLimiterState } from '../_shared/types';
import { PLAN_LIMITS } from '../_shared/types';

export class UserLimiterDO extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
    this.ctx.blockConcurrencyWhile(async () => {
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS user_state (
          user_id   TEXT PRIMARY KEY,
          plan      TEXT NOT NULL,
          credits   INTEGER NOT NULL,
          active_jobs INTEGER NOT NULL DEFAULT 0,
          rule_slots  INTEGER NOT NULL DEFAULT 0
        )
      `);
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS reserved_jobs (
          job_id      TEXT PRIMARY KEY,
          item_count  INTEGER NOT NULL,
          reserved_at TEXT NOT NULL
        )
      `);
    });
  }

  // ─── init ────────────────────────────────────────────────────────────────

  init(userId: string, plan: 'free' | 'pro'): void {
    console.log(`[UserLimiterDO][init] userId=${userId} plan=${plan}`);
    const limits = PLAN_LIMITS[plan];
    // INSERT OR IGNORE — 기존 레코드가 있으면 아무것도 하지 않음 (크레딧 보존)
    this.ctx.storage.sql.exec(
      `INSERT OR IGNORE INTO user_state (user_id, plan, credits, active_jobs, rule_slots)
       VALUES (?, ?, ?, 0, 0)`,
      userId,
      plan,
      limits.initialCredits,
    );
    console.log(
      `[UserLimiterDO][init] done userId=${userId} initialCredits=${limits.initialCredits} maxConcurrency=${limits.maxConcurrency} maxRuleSlots=${limits.maxRuleSlots}`,
    );
  }

  // ─── getUserState ─────────────────────────────────────────────────────────

  getUserState(): UserLimiterState {
    const rows = this.ctx.storage.sql
      .exec<{
        user_id: string;
        plan: string;
        credits: number;
        active_jobs: number;
        rule_slots: number;
      }>(`SELECT user_id, plan, credits, active_jobs, rule_slots FROM user_state LIMIT 1`)
      .toArray();

    if (rows.length === 0) {
      throw new Error('[UserLimiterDO][getUserState] state not initialized — call init() first');
    }

    const row = rows[0];
    const plan = row.plan as 'free' | 'pro';
    const limits = PLAN_LIMITS[plan];

    return {
      userId: row.user_id,
      plan,
      credits: row.credits,
      activeJobs: row.active_jobs,
      maxConcurrency: limits.maxConcurrency,
      ruleSlots: row.rule_slots,
      maxRuleSlots: limits.maxRuleSlots,
    };
  }

  // ─── reserve ─────────────────────────────────────────────────────────────

  reserve(jobId: string, itemCount: number): { allowed: boolean; reason?: string } {
    console.log(`[UserLimiterDO][reserve] jobId=${jobId} itemCount=${itemCount}`);

    const state = this.getUserState();
    const limits = PLAN_LIMITS[state.plan];

    if (state.activeJobs >= limits.maxConcurrency) {
      console.log(
        `[UserLimiterDO][reserve] denied jobId=${jobId} reason=concurrency_limit activeJobs=${state.activeJobs} maxConcurrency=${limits.maxConcurrency}`,
      );
      return { allowed: false, reason: 'concurrency_limit' };
    }

    if (itemCount > limits.maxItems) {
      console.log(
        `[UserLimiterDO][reserve] denied jobId=${jobId} reason=item_limit itemCount=${itemCount} maxItems=${limits.maxItems}`,
      );
      return { allowed: false, reason: 'item_limit' };
    }

    if (state.credits < itemCount) {
      console.log(
        `[UserLimiterDO][reserve] denied jobId=${jobId} reason=insufficient_credits credits=${state.credits} needed=${itemCount}`,
      );
      return { allowed: false, reason: 'insufficient_credits' };
    }

    this.ctx.storage.sql.exec(
      `UPDATE user_state SET credits = credits - ?, active_jobs = active_jobs + 1`,
      itemCount,
    );
    this.ctx.storage.sql.exec(
      `INSERT OR IGNORE INTO reserved_jobs (job_id, item_count, reserved_at) VALUES (?, ?, ?)`,
      jobId,
      itemCount,
      new Date().toISOString(),
    );

    console.log(
      `[UserLimiterDO][reserve] allowed jobId=${jobId} itemCount=${itemCount} credits_before=${state.credits} credits_after=${state.credits - itemCount}`,
    );
    return { allowed: true };
  }

  // ─── commit ───────────────────────────────────────────────────────────────

  commit(jobId: string): void {
    console.log(`[UserLimiterDO][commit] jobId=${jobId}`);

    const rows = this.ctx.storage.sql
      .exec<{ item_count: number }>(
        `SELECT item_count FROM reserved_jobs WHERE job_id = ?`,
        jobId,
      )
      .toArray();

    if (rows.length === 0) {
      console.log(
        `[UserLimiterDO][commit] skipped jobId=${jobId} reason=no_reservation_found`,
      );
      return;
    }

    const { item_count } = rows[0];
    this.ctx.storage.sql.exec(`DELETE FROM reserved_jobs WHERE job_id = ?`, jobId);

    console.log(
      `[UserLimiterDO][commit] done jobId=${jobId} itemCount=${item_count} credits_deducted=permanent`,
    );
  }

  // ─── rollback ────────────────────────────────────────────────────────────

  rollback(jobId: string): void {
    console.log(`[UserLimiterDO][rollback] jobId=${jobId}`);

    const rows = this.ctx.storage.sql
      .exec<{ item_count: number }>(
        `SELECT item_count FROM reserved_jobs WHERE job_id = ?`,
        jobId,
      )
      .toArray();

    if (rows.length === 0) {
      console.log(
        `[UserLimiterDO][rollback] skipped jobId=${jobId} reason=no_reservation_found`,
      );
      return;
    }

    const { item_count } = rows[0];
    this.ctx.storage.sql.exec(
      `UPDATE user_state SET credits = credits + ?`,
      item_count,
    );
    this.ctx.storage.sql.exec(`DELETE FROM reserved_jobs WHERE job_id = ?`, jobId);

    console.log(
      `[UserLimiterDO][rollback] done jobId=${jobId} itemCount=${item_count} credits_refunded=${item_count}`,
    );
  }

  // ─── release ─────────────────────────────────────────────────────────────

  release(jobId: string): void {
    console.log(`[UserLimiterDO][release] jobId=${jobId}`);

    this.ctx.storage.sql.exec(
      `UPDATE user_state SET active_jobs = MAX(0, active_jobs - 1)`,
    );

    console.log(`[UserLimiterDO][release] done jobId=${jobId}`);
  }

  // ─── checkRuleSlot ────────────────────────────────────────────────────────

  checkRuleSlot(): boolean {
    const state = this.getUserState();
    const limits = PLAN_LIMITS[state.plan];
    const available = state.ruleSlots < limits.maxRuleSlots;
    return available;
  }

  // ─── incrementRuleSlot ───────────────────────────────────────────────────

  incrementRuleSlot(): void {
    const state = this.getUserState();
    console.log(
      `[UserLimiterDO][incrementRuleSlot] current=${state.ruleSlots} max=${PLAN_LIMITS[state.plan].maxRuleSlots}`,
    );

    this.ctx.storage.sql.exec(`UPDATE user_state SET rule_slots = rule_slots + 1`);

    console.log(`[UserLimiterDO][incrementRuleSlot] done new=${state.ruleSlots + 1}`);
  }

  // ─── decrementRuleSlot ───────────────────────────────────────────────────

  decrementRuleSlot(): void {
    const state = this.getUserState();
    console.log(`[UserLimiterDO][decrementRuleSlot] current=${state.ruleSlots}`);

    this.ctx.storage.sql.exec(
      `UPDATE user_state SET rule_slots = MAX(0, rule_slots - 1)`,
    );

    console.log(
      `[UserLimiterDO][decrementRuleSlot] done new=${Math.max(0, state.ruleSlots - 1)}`,
    );
  }
}
