/**
 * Auth Service — D1 user 생성 + JWT 발급
 *
 * TODO: Auto-Claude 구현
 * - createOrGetUser(db, deviceHash?) → { userId, plan, isNew }
 * - D1 INSERT users + crypto.randomUUID()
 * - signJwt() 호출
 */

import type { Env } from '../_shared/types';

export async function createOrGetUser(
  db: D1Database,
  deviceHash?: string,
): Promise<{ userId: string; plan: 'free' | 'pro'; isNew: boolean }> {
  // TODO: implement
  throw new Error('Not implemented');
}
