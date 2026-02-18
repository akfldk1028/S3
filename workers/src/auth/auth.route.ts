/**
 * Auth Route — POST /auth/anon
 *
 * - POST /anon: device_hash (optional) 받음 → D1 user 생성 + JWT 발급
 *
 * Note: GET /me is handled by user.route.ts (mounted at /me in index.ts).
 */

import { Hono } from 'hono';
import type { Env, AuthUser } from '../_shared/types';
import { ok, error } from '../_shared/response';
import { createOrGetUser, createAuthToken } from './auth.service';

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

export default app;
