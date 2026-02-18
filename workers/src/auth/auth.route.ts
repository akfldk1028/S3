/**
 * Auth Route — POST /auth/anon, GET /me
 *
 * - POST /anon: device_hash (optional) 받음 → D1 user 생성 + JWT 발급
 * - GET /me: 인증된 유저 상태 조회 (UserLimiterDO stub)
 *
 * Note: The canonical GET /me handler lives in user.route.ts (mounted at /me in index.ts).
 */

import { Hono } from 'hono';
import type { Env, AuthUser } from '../_shared/types';
import { ok, error } from '../_shared/response';
import { createOrGetUser, createAuthToken } from './auth.service';
import { ERR } from '../_shared/errors';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// POST /auth/anon
app.post('/anon', async (c) => {
  try {
    const body = await c.req.json<{ device_hash?: string }>().catch(() => ({} as { device_hash?: string }));
    const deviceHash = body.device_hash;

    const { userId, plan, isNew } = await createOrGetUser(c.env.DB, deviceHash);
    const token = await createAuthToken(userId, c.env.JWT_SECRET);

    return c.json(
      ok({
        user_id: userId,
        token,
        plan,
        is_new: isNew,
      })
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json(error('AUTH_ERROR', message), 500);
  }
});

// GET /me - 유저 상태 조회 (UserLimiterDO stub)
app.get('/me', async (c) => {
  try {
    const user = c.get('user');
    if (!user || !user.userId) {
      return c.json(error(ERR.AUTH_REQUIRED, 'Authentication required'), 401);
    }

    // D1에서 유저 정보 조회
    const userRow = await c.env.DB
      .prepare('SELECT id, plan, credits FROM users WHERE id = ?')
      .bind(user.userId)
      .first<{ id: string; plan: 'free' | 'pro'; credits: number }>();

    if (!userRow) {
      return c.json(error(ERR.NOT_FOUND, 'User not found'), 404);
    }

    // 유저 룰 개수 조회 (rule_slots)
    const ruleCountResult = await c.env.DB
      .prepare('SELECT COUNT(*) as count FROM rules WHERE user_id = ?')
      .bind(user.userId)
      .first<{ count: number }>();

    const ruleSlots = ruleCountResult?.count || 0;

    // UserLimiterDO stub — 실제 구현은 후속 태스크
    // concurrent_jobs는 0으로 stub (JobCoordinatorDO 미구현)
    return c.json(
      ok({
        user_id: userRow.id,
        plan: userRow.plan,
        credits: userRow.credits,
        rule_slots: ruleSlots,
        concurrent_jobs: 0, // stub: UserLimiterDO.activeJobs 대신
      })
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json(error('SYSTEM_ERROR', message), 500);
  }
});

export default app;
