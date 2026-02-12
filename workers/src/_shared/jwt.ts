/**
 * JWT HS256 sign/verify — Web Crypto API 사용
 *
 * TODO: Auto-Claude 구현
 * - signJwt(payload, secret) → token string
 * - verifyJwt(token, secret) → JwtPayload
 * - Web Crypto: crypto.subtle.importKey + crypto.subtle.sign/verify (HMAC SHA-256)
 * - Base64url encoding/decoding
 */

import type { JwtPayload } from './types';

export async function signJwt(payload: JwtPayload, secret: string): Promise<string> {
  // TODO: implement with Web Crypto API
  throw new Error('Not implemented');
}

export async function verifyJwt(token: string, secret: string): Promise<JwtPayload> {
  // TODO: implement with Web Crypto API
  throw new Error('Not implemented');
}
