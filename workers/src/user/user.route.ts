/**
 * User Route — GET /me
 *
 * - UserLimiterDO.getUserState() → { userId, plan, credits, activeJobs, usedRuleSlots, maxRuleSlots }
 */

import { Hono } from 'hono';
import type { Env, AuthUser, UserLimiterState } from '../_shared/types';
import { ok, error as apiError } from '../_shared/response';
import { getUserLimiterStub } from '../do/do.helpers';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// GET /me — returns { success: true, data: {...}, error: null, meta: { request_id, timestamp } }
app.get('/', async (c) => {
  const user = c.var.user;

  try {
    const stub = getUserLimiterStub(c.env, user.userId);
    const state = await (stub as unknown as { getUserState(): Promise<UserLimiterState> }).getUserState();

    return c.json(ok({
      userId: state.userId,
      plan: state.plan,
      credits: state.credits,
      activeJobs: state.activeJobs,
      usedRuleSlots: state.ruleSlots,
      maxRuleSlots: state.maxRuleSlots,
    }));
  } catch (err) {
    return c.json(apiError('INTERNAL_ERROR', 'Failed to retrieve user state'), 500);
  }
});

export default app;
