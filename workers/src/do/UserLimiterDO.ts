/**
 * UserLimiterDO — 유저당 1개 Durable Object
 *
 * SQLite-backed DO (new_sqlite_classes)
 * Manages per-user credits, concurrency limits, and rule slot enforcement
 */

import { DurableObject } from 'cloudflare:workers';
import type { Env, UserLimiterState } from '../_shared/types';

const PLAN_LIMITS = {
  free: { maxConcurrency: 1, maxRuleSlots: 2, maxItems: 10, initialCredits: 10 },
  pro: { maxConcurrency: 3, maxRuleSlots: 20, maxItems: 200, initialCredits: 200 },
} as const;

export class UserLimiterDO extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);

    // CRITICAL: Use blockConcurrencyWhile for schema initialization to prevent race conditions
    this.ctx.blockConcurrencyWhile(async () => {
      await this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS user_state (
          user_id TEXT PRIMARY KEY,
          credits INTEGER NOT NULL,
          active_jobs INTEGER NOT NULL DEFAULT 0,
          plan TEXT NOT NULL CHECK(plan IN ('free', 'pro')),
          rule_slots_used INTEGER NOT NULL DEFAULT 0
        );
      `);
    });
  }

  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const method = request.method;

    try {
      if (url.pathname === '/init' && method === 'POST') {
        const { userId, plan } = await request.json() as { userId: string; plan: 'free' | 'pro' };
        await this.init(userId, plan);
        return new Response(JSON.stringify({ success: true }), { status: 200 });
      }

      if (url.pathname === '/getUserState' && method === 'GET') {
        const state = await this.getUserState();
        return new Response(JSON.stringify(state), { status: 200 });
      }

      if (url.pathname === '/reserve' && method === 'POST') {
        const { jobId, itemCount } = await request.json() as { jobId: string; itemCount: number };
        const result = await this.reserve(jobId, itemCount);
        return new Response(JSON.stringify(result), { status: result.allowed ? 200 : 403 });
      }

      if (url.pathname === '/release' && method === 'POST') {
        const { jobId, doneItems, totalItems } = await request.json() as { jobId: string; doneItems: number; totalItems: number };
        await this.release(jobId, doneItems, totalItems);
        return new Response(JSON.stringify({ success: true }), { status: 200 });
      }

      if (url.pathname === '/checkRuleSlot' && method === 'GET') {
        const result = await this.checkRuleSlot();
        return new Response(JSON.stringify(result), { status: 200 });
      }

      if (url.pathname === '/incrementRuleSlot' && method === 'POST') {
        await this.incrementRuleSlot();
        return new Response(JSON.stringify({ success: true }), { status: 200 });
      }

      if (url.pathname === '/decrementRuleSlot' && method === 'POST') {
        await this.decrementRuleSlot();
        return new Response(JSON.stringify({ success: true }), { status: 200 });
      }

      return new Response('Not Found', { status: 404 });
    } catch (error) {
      return new Response(JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }), { status: 500 });
    }
  }

  /**
   * Initialize user state - called when user first signs up
   */
  private async init(userId: string, plan: 'free' | 'pro'): Promise<void> {
    const initialCredits = PLAN_LIMITS[plan].initialCredits;

    // Use INSERT OR REPLACE to handle re-initialization
    await this.ctx.storage.sql.exec(
      `INSERT OR REPLACE INTO user_state (user_id, credits, active_jobs, plan, rule_slots_used)
       VALUES (?, ?, 0, ?, 0)`,
      userId,
      initialCredits,
      plan
    );
  }

  /**
   * Get current user state
   */
  async getUserState(): Promise<UserLimiterState> {
    const cursor = await this.ctx.storage.sql.exec(
      `SELECT user_id, credits, active_jobs, plan, rule_slots_used FROM user_state LIMIT 1`
    );

    const row = cursor.toArray()[0];
    if (!row) {
      throw new Error('User state not initialized');
    }

    const plan = row[3] as 'free' | 'pro';
    const limits = PLAN_LIMITS[plan];

    return {
      userId: row[0] as string,
      plan,
      credits: row[1] as number,
      activeJobs: row[2] as number,
      maxConcurrency: limits.maxConcurrency,
      ruleSlots: row[4] as number,
      maxRuleSlots: limits.maxRuleSlots,
    };
  }

  /**
   * Reserve credits for a job - atomic check-and-decrement
   * CRITICAL: Credits must NEVER go negative
   */
  async reserve(jobId: string, itemCount: number): Promise<{ allowed: boolean; reason?: string }> {
    const state = await this.getUserState();

    // Check credits
    if (state.credits < itemCount) {
      return {
        allowed: false,
        reason: `Insufficient credits: ${state.credits} available, ${itemCount} required`,
      };
    }

    // Check concurrency
    if (state.activeJobs >= state.maxConcurrency) {
      return {
        allowed: false,
        reason: `Concurrency limit reached: ${state.activeJobs}/${state.maxConcurrency}`,
      };
    }

    // Atomic decrement of credits and increment of active_jobs
    await this.ctx.storage.sql.exec(
      `UPDATE user_state SET credits = credits - ?, active_jobs = active_jobs + 1 WHERE user_id = ?`,
      itemCount,
      state.userId
    );

    return { allowed: true };
  }

  /**
   * Release a job slot and refund credits for unprocessed items
   */
  async release(jobId: string, doneItems: number, totalItems: number): Promise<void> {
    const refund = totalItems - doneItems;

    // Decrement active_jobs and refund unprocessed credits
    await this.ctx.storage.sql.exec(
      `UPDATE user_state SET active_jobs = active_jobs - 1, credits = credits + ? WHERE active_jobs > 0`,
      refund
    );
  }

  /**
   * Check if user can use a rule slot
   */
  async checkRuleSlot(): Promise<{ allowed: boolean }> {
    const state = await this.getUserState();
    return {
      allowed: state.ruleSlots < state.maxRuleSlots,
    };
  }

  /**
   * Increment rule slot usage
   */
  async incrementRuleSlot(): Promise<void> {
    const state = await this.getUserState();

    if (state.ruleSlots >= state.maxRuleSlots) {
      throw new Error(`Rule slot limit reached: ${state.ruleSlots}/${state.maxRuleSlots}`);
    }

    await this.ctx.storage.sql.exec(
      `UPDATE user_state SET rule_slots_used = rule_slots_used + 1`
    );
  }

  /**
   * Decrement rule slot usage
   */
  async decrementRuleSlot(): Promise<void> {
    await this.ctx.storage.sql.exec(
      `UPDATE user_state SET rule_slots_used = rule_slots_used - 1 WHERE rule_slots_used > 0`
    );
  }
}
