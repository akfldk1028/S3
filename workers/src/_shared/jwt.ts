/**
 * JWT HS256 sign/verify — hono/jwt 사용
 *
 * - signJwt(payload, secret) → token string
 * - verifyJwt(token, secret) → JwtPayload
 * - HS256 algorithm (default for hono/jwt)
 * - NO plan field in JWT payload (UserLimiterDO is source of truth)
 */

import { sign, verify } from 'hono/jwt';
import type { JwtPayload } from './types';

export async function signJwt(payload: JwtPayload, secret: string): Promise<string> {
  return await sign(
    {
      sub: payload.sub,
      iat: payload.iat,
      exp: payload.exp,
    },
    secret
  );
}

export async function verifyJwt(token: string, secret: string): Promise<JwtPayload> {
  const decoded = await verify(token, secret, 'HS256');
  return {
    sub: decoded.sub as string,
    iat: decoded.iat as number,
    exp: decoded.exp as number,
  };
}
