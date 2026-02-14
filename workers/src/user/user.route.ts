/**
 * User Route — GET /me
 *
 * Returns current user state from UserLimiterDO
 * - UserLimiterDO.getUserState() → { user_id, plan, credits, active_jobs, rule_slots: { used, max } }
 */

import { Hono } from 'hono';
import type { Env, AuthUser, UserLimiterState } from '../_shared/types';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// GET /me - Return user state from UserLimiterDO
app.get('/me', async (c) => {
  try {
    // 1. Get authenticated user from middleware
    const user = c.get('user');
    const userId = user.userId;

    // 2. Get UserLimiterDO stub
    const userLimiterId = c.env.USER_LIMITER.idFromName(userId);
    const userLimiterStub = c.env.USER_LIMITER.get(userLimiterId);

    // 3. Call getUserState() on the DO
    const response = await userLimiterStub.fetch('http://internal/getUserState', {
      method: 'GET',
    });

    if (!response.ok) {
      const error = await response.json<{ error: string }>();
      return c.json(
        {
          success: false,
          error: {
            code: 'USER_STATE_ERROR',
            message: error.error || 'Failed to get user state',
          },
        },
        500
      );
    }

    const state = await response.json<UserLimiterState>();

    // 4. Return user state
    return c.json({
      success: true,
      data: {
        userId: state.userId,
        plan: state.plan,
        credits: state.credits,
        activeJobs: state.activeJobs,
        usedRuleSlots: state.ruleSlots,
        maxRuleSlots: state.maxRuleSlots,
      },
    });
  } catch (error) {
    return c.json(
      {
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: error instanceof Error ? error.message : 'Unknown error',
        },
      },
      500
    );
  }
});

export default app;
