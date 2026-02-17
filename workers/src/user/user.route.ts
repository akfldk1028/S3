/**
 * User Route — GET /me
 *
 * - UserLimiterDO.getUserState() → { userId, plan, credits, activeJobs, maxConcurrency, usedRuleSlots, maxRuleSlots }
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
    const limiterNs = c.env.USER_LIMITER as unknown as DurableObjectNamespace<UserLimiterDO>;
    const limiterStub = limiterNs.get(limiterNs.idFromName(user.userId));
    const state = await limiterStub.getUserState();

    return c.json(
      ok({
        userId: state.userId,
        plan: state.plan,
        credits: state.credits,
        activeJobs: state.activeJobs,
        maxConcurrency: state.maxConcurrency,
        usedRuleSlots: state.ruleSlots,
        maxRuleSlots: state.maxRuleSlots,
      }),
    );
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

export default app;
