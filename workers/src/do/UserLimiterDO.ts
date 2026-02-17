/**
 * UserLimiterDO — 유저당 1개 Durable Object
 *
 * SQLite-backed DO (new_sqlite_classes)
 *
 * - blockConcurrencyWhile → SQLite 테이블 초기화
 * - RPC methods (HTTP fetch 핸들러로 노출):
 *   - init(userId, plan) → 초기 상태 설정 (INSERT OR IGNORE — 기존 크레딧 보존)
 *   - getUserState() → UserLimiterState
 *   - reserve(jobId, cost) → boolean (크레딧 차감 + 동시성 증가)
 *   - release(doneItems, failedItems, totalItems) → void (동시성 감소 + 미처리분 환불)
 *   - commit(jobId) → void (동시성만 감소, 크레딧 변화 없음)
 *   - rollback(jobId, totalItems) → void (동시성 감소 + 전액 환불)
 *   - checkRuleSlot() → boolean (슬롯 여유 확인)
 *   - incrementRuleSlot() → void
 *   - decrementRuleSlot() → void
 * - Plan limits: PLAN_LIMITS from types.ts
 */

import { DurableObject } from 'cloudflare:workers';
import { PLAN_LIMITS, type Env, type UserLimiterState } from '../_shared/types';

export class UserLimiterDO extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);

    // SQLite 테이블 초기화 — DO 첫 활성화 시 한 번만 실행
    this.ctx.blockConcurrencyWhile(async () => {
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS user_state (
          user_id       TEXT    PRIMARY KEY,
          credits       INTEGER NOT NULL,
          active_jobs   INTEGER NOT NULL DEFAULT 0,
          plan          TEXT    NOT NULL DEFAULT 'free',
          rule_slots_used INTEGER NOT NULL DEFAULT 0
        )
      `);
    });
  }

  // ─── fetch 핸들러 (HTTP 라우팅) ──────────────────────────

  override async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    try {
      if (path === '/init' && request.method === 'POST') {
        return await this._handleInit(request);
      }
      if (path === '/getUserState' && request.method === 'GET') {
        return await this._handleGetUserState();
      }
      if (path === '/reserve' && request.method === 'POST') {
        return await this._handleReserve(request);
      }
      if (path === '/release' && request.method === 'POST') {
        return await this._handleRelease(request);
      }
      if (path === '/commit' && request.method === 'POST') {
        return await this._handleCommit(request);
      }
      if (path === '/rollback' && request.method === 'POST') {
        return await this._handleRollback(request);
      }
      if (path === '/checkRuleSlot' && request.method === 'GET') {
        return await this._handleCheckRuleSlot();
      }
      if (path === '/incrementRuleSlot' && request.method === 'POST') {
        return await this._handleIncrementRuleSlot();
      }
      if (path === '/decrementRuleSlot' && request.method === 'POST') {
        return await this._handleDecrementRuleSlot();
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

  // ─── 핸들러 구현 ─────────────────────────────────────────

  /**
   * POST /init — userId와 plan으로 초기 상태 생성.
   * INSERT OR IGNORE: 이미 존재하는 사용자의 크레딧은 변경하지 않음 (CRED-1).
   */
  private async _handleInit(request: Request): Promise<Response> {
    const { userId, plan } = await request.json<{ userId: string; plan: 'free' | 'pro' }>();
    const initialCredits = PLAN_LIMITS[plan].initialCredits;

    // [CRED-1] INSERT OR IGNORE — 기존 레코드가 있으면 아무것도 하지 않음 (크레딧 보존)
    this.ctx.storage.sql.exec(
      `INSERT OR IGNORE INTO user_state (user_id, credits, active_jobs, plan, rule_slots_used)
       VALUES (?, ?, 0, ?, 0)`,
      userId,
      initialCredits,
      plan,
    );

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * GET /getUserState — 현재 사용자 상태 반환.
   */
  private async _handleGetUserState(): Promise<Response> {
    const state = this._readState();
    if (!state) {
      return new Response(JSON.stringify({ error: 'User not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }
    return new Response(JSON.stringify(state), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * POST /reserve — 크레딧 차감 및 동시성 증가.
   * 크레딧 부족 또는 동시성 한도 초과 시 false 반환.
   */
  private async _handleReserve(request: Request): Promise<Response> {
    const { jobId, cost } = await request.json<{ jobId: string; cost: number }>();
    const state = this._readState();

    if (!state) {
      return new Response(JSON.stringify({ success: false, error: 'User not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const maxConcurrency = PLAN_LIMITS[state.plan].maxConcurrency;

    if (state.credits < cost || state.activeJobs >= maxConcurrency) {
      return new Response(JSON.stringify({ reserved: false }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    this.ctx.storage.sql.exec(
      `UPDATE user_state
       SET credits = credits - ?, active_jobs = active_jobs + 1
       WHERE user_id = ?`,
      cost,
      state.userId,
    );

    return new Response(JSON.stringify({ reserved: true, jobId }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * POST /release — 동시성 감소 + 미처리 아이템 환불 (CRED-2).
   * refund = totalItems - doneItems - failedItems (완료/실패분은 환불 제외)
   */
  private async _handleRelease(request: Request): Promise<Response> {
    const { doneItems, failedItems, totalItems } = await request.json<{
      doneItems: number;
      failedItems: number;
      totalItems: number;
    }>();

    this.release(doneItems, failedItems, totalItems);

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * POST /commit — job 완료 시 동시성만 감소 (크레딧 변화 없음).
   */
  private async _handleCommit(request: Request): Promise<Response> {
    const { jobId } = await request.json<{ jobId: string }>();
    const state = this._readState();

    if (!state) {
      return new Response(JSON.stringify({ success: false, error: 'User not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // active_jobs > 0 조건으로 언더플로 방지
    this.ctx.storage.sql.exec(
      `UPDATE user_state
       SET active_jobs = active_jobs - 1
       WHERE user_id = ? AND active_jobs > 0`,
      state.userId,
    );

    return new Response(JSON.stringify({ success: true, jobId }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * POST /rollback — job 취소 시 동시성 감소 + 전액 환불.
   */
  private async _handleRollback(request: Request): Promise<Response> {
    const { jobId, totalItems } = await request.json<{ jobId: string; totalItems: number }>();
    const state = this._readState();

    if (!state) {
      return new Response(JSON.stringify({ success: false, error: 'User not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // active_jobs > 0 조건으로 언더플로 방지
    this.ctx.storage.sql.exec(
      `UPDATE user_state
       SET credits = credits + ?, active_jobs = active_jobs - 1
       WHERE user_id = ? AND active_jobs > 0`,
      totalItems,
      state.userId,
    );

    return new Response(JSON.stringify({ success: true, jobId }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * GET /checkRuleSlot — 룰 슬롯 여유 확인.
   */
  private async _handleCheckRuleSlot(): Promise<Response> {
    const state = this._readState();

    if (!state) {
      return new Response(JSON.stringify({ available: false }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const maxRuleSlots = PLAN_LIMITS[state.plan].maxRuleSlots;
    const available = state.ruleSlots < maxRuleSlots;

    return new Response(JSON.stringify({ available }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * POST /incrementRuleSlot — 룰 슬롯 사용 증가.
   */
  private async _handleIncrementRuleSlot(): Promise<Response> {
    const state = this._readState();

    if (!state) {
      return new Response(JSON.stringify({ success: false, error: 'User not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    this.ctx.storage.sql.exec(
      `UPDATE user_state SET rule_slots_used = rule_slots_used + 1 WHERE user_id = ?`,
      state.userId,
    );

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * POST /decrementRuleSlot — 룰 슬롯 사용 감소.
   */
  private async _handleDecrementRuleSlot(): Promise<Response> {
    const state = this._readState();

    if (!state) {
      return new Response(JSON.stringify({ success: false, error: 'User not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // rule_slots_used > 0 조건으로 언더플로 방지
    this.ctx.storage.sql.exec(
      `UPDATE user_state
       SET rule_slots_used = rule_slots_used - 1
       WHERE user_id = ? AND rule_slots_used > 0`,
      state.userId,
    );

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // ─── 내부 헬퍼 ──────────────────────────────────────────

  /**
   * SQLite에서 사용자 상태를 읽어 UserLimiterState로 반환.
   */
  private _readState(): UserLimiterState | null {
    const cursor = this.ctx.storage.sql.exec<{
      user_id: string;
      credits: number;
      active_jobs: number;
      plan: string;
      rule_slots_used: number;
    }>(`SELECT * FROM user_state LIMIT 1`);

    const rows = [...cursor];
    if (rows.length === 0) return null;

    const row = rows[0];
    const plan = row.plan as 'free' | 'pro';
    const limits = PLAN_LIMITS[plan];

    return {
      userId: row.user_id,
      plan,
      credits: row.credits,
      activeJobs: row.active_jobs,
      maxConcurrency: limits.maxConcurrency,
      ruleSlots: row.rule_slots_used,
      maxRuleSlots: limits.maxRuleSlots,
    };
  }

  // ─── 공개 RPC 메서드 (alarm 등 내부 호출용) ──────────────

  /**
   * [CRED-2] release — 동시성 감소 + 미처리 아이템 환불.
   *
   * refund = totalItems - doneItems - failedItems
   * (완료 및 실패 아이템은 이미 처리된 것이므로 환불 제외)
   *
   * WHERE active_jobs > 0 조건으로 언더플로 방지.
   */
  release(doneItems: number, failedItems: number, totalItems: number): void {
    const state = this._readState();
    if (!state) return;

    // 미처리 아이템만 환불 (done + failed는 실제 처리된 아이템)
    const refund = totalItems - doneItems - failedItems;

    this.ctx.storage.sql.exec(
      `UPDATE user_state
       SET credits = credits + ?, active_jobs = active_jobs - 1
       WHERE user_id = ? AND active_jobs > 0`,
      refund,
      state.userId,
    );
  }
}
