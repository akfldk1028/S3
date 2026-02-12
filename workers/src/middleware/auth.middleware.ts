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
  // TODO: implement JWT verification
  await next();
});
