/**
 * User Route — GET /me
 *
 * Fetches user state from UserLimiterDO.
 * Calls init() first to ensure DO is initialized (INSERT OR IGNORE — safe to repeat).
 */

import { Hono } from 'hono';
import type { Env, AuthUser } from '../_shared/types';
import { ok, error } from '../_shared/response';
import { ERR } from '../_shared/errors';
import type { UserLimiterDO } from '../do/UserLimiterDO';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// ─── GET /me ─────────────────────────────────────────────────────────────────
// 인증된 유저 상태 조회 (크레딧, 플랜, 동시성, 룰 슬롯)

app.get('/', async (c) => {
  const user = c.get('user');

  try {
    // D1에서 plan 조회 (DO init에 필요)
    const userRow = await c.env.DB
      .prepare('SELECT plan FROM users WHERE id = ?')
      .bind(user.userId)
      .first<{ plan: 'free' | 'pro' }>();

    const plan = userRow?.plan ?? 'free';

    // DO init (INSERT OR IGNORE — 이미 초기화되었으면 무시됨)
    const limiterNs = c.env.USER_LIMITER as unknown as DurableObjectNamespace<UserLimiterDO>;
    const limiterStub = limiterNs.get(limiterNs.idFromName(user.userId));
    await limiterStub.init(user.userId, plan);

    const state = await limiterStub.getUserState();

    return c.json(
      ok({
        user_id: state.userId,
        plan: state.plan,
        credits: state.credits,
        rule_slots: state.ruleSlots,
        concurrent_jobs: state.activeJobs,
      }),
    );
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

export default app;
