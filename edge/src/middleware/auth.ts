/**
 * Auth middleware — Supabase JWT verification for Hono.
 *
 * TODO: 실제 Supabase JWT 검증 (JWKS endpoint).
 * 현재: 개발용 stub — Bearer 토큰 유무만 확인.
 */

import { createMiddleware } from 'hono/factory';
import { HTTPException } from 'hono/http-exception';
import type { Env, AuthUser } from '../types';

/**
 * Hono Variables — context에 저장되는 타입 정의.
 * 사용: c.get('user') → AuthUser (jwt 필드 포함)
 */
export type AuthVariables = {
  user: AuthUser;
};

/**
 * Auth middleware — 모든 /api/v1/* 라우트에 적용.
 * c.set('user', authUser) 로 인증 정보를 context에 저장.
 * authUser.jwt는 Supabase REST API 호출 시 사용.
 */
export const authMiddleware = createMiddleware<{
  Bindings: Env;
  Variables: AuthVariables;
}>(async (c, next) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    throw new HTTPException(401, { message: 'Authorization header required' });
  }

  const token = authHeader.slice(7);
  if (!token) {
    throw new HTTPException(401, { message: 'Invalid token' });
  }

  // TODO: 실제 Supabase JWT 검증
  // const payload = await verifySupabaseJWT(token, c.env.SUPABASE_URL, c.env.SUPABASE_ANON_KEY);
  // c.set('user', { userId: payload.sub, tier: payload.user_metadata?.tier ?? 'free', jwt: token });

  // Stub: 개발 모드 — JWT를 그대로 전달 (Supabase REST API 호출용)
  c.set('user', { userId: 'dev-user-id', tier: 'free', jwt: token });

  await next();
});
