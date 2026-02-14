/**
 * JWT 인증 미들웨어
 *
 * TODO: Auto-Claude 구현
 * - Authorization: Bearer <token> 추출
 * - verifyJwt() → c.set('user', { userId, plan })
 * - 인증 제외 경로: /auth/anon, /health, /jobs/{id}/callback
 */

import { createMiddleware } from 'hono/factory';
import type { Env, AuthUser } from '../_shared/types';

export const authMiddleware = createMiddleware<{
  Bindings: Env;
  Variables: { user: AuthUser };
}>(async (c, next) => {
  // Skip auth for health check and callback endpoints
  const path = new URL(c.req.url).pathname;
  if (path === '/health' || path.includes('/callback')) {
    await next();
    return;
  }

  // TEMPORARY: Mock user for testing (replace with real JWT verification)
  // Extract user ID from Authorization header or use default test user
  const authHeader = c.req.header('Authorization');
  let userId = 'test-user-id';

  if (authHeader?.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    // For testing: use token value as userId if provided
    if (token && token !== 'test-token') {
      userId = token;
    }
  }

  c.set('user', { userId });
  await next();
});
