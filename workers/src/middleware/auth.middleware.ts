/**
 * JWT 인증 미들웨어
 *
 * - Authorization: Bearer <token> 추출
 * - verifyJwt() → c.set('user', { userId })
 * - 인증 제외 경로: /auth/anon, /health, /jobs/{id}/callback
 */

import { createMiddleware } from 'hono/factory';
import type { Env, AuthUser } from '../_shared/types';
import { verifyJwt } from '../_shared/jwt';
import { error } from '../_shared/response';
import { ERR } from '../_shared/errors';

export const authMiddleware = createMiddleware<{
  Bindings: Env;
  Variables: { user: AuthUser };
}>(async (c, next) => {
  const path = new URL(c.req.url).pathname;

  // Skip authentication for public paths
  if (
    path === '/health' ||
    path === '/auth/anon' ||
    /^\/jobs\/[^/]+\/callback$/.test(path)
  ) {
    await next();
    return;
  }

  // Extract Bearer token
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json(error(ERR.AUTH_REQUIRED, 'Missing or invalid Authorization header'), 401);
  }

  const token = authHeader.substring(7); // Remove "Bearer " prefix

  // Verify JWT
  try {
    const payload = await verifyJwt(token, c.env.JWT_SECRET);

    // Set user in context
    c.set('user', {
      userId: payload.sub,
    });

    await next();
  } catch (err) {
    // JWT verification failed (expired or invalid)
    const message = err instanceof Error ? err.message : 'Invalid token';
    if (message.includes('exp') || message.includes('expired')) {
      return c.json(error(ERR.AUTH_EXPIRED_TOKEN, 'Token has expired'), 401);
    }
    return c.json(error(ERR.AUTH_INVALID_TOKEN, 'Invalid token'), 401);
  }
});
