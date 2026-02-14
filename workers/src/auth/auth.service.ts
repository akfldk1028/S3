/**
 * Auth Service — D1 user 생성 + JWT 발급
 *
 * TODO: Auto-Claude 구현
 * - createOrGetUser(db, deviceHash?) → { userId, plan, isNew }
 * - D1 INSERT users + crypto.randomUUID()
 * - signJwt() 호출
 */

import type { Env } from '../_shared/types';
import { signJwt } from '../_shared/jwt';
import { PLAN_LIMITS } from '../_shared/types';

export async function createOrGetUser(
  db: D1Database,
  deviceHash?: string,
): Promise<{ userId: string; plan: 'free' | 'pro'; isNew: boolean }> {
  // If device_hash provided, try to find existing user
  if (deviceHash) {
    const existing = await db
      .prepare('SELECT id, plan FROM users WHERE device_hash = ? AND auth_provider = ?')
      .bind(deviceHash, 'anon')
      .first<{ id: string; plan: 'free' | 'pro' }>();

    if (existing) {
      return {
        userId: existing.id,
        plan: existing.plan,
        isNew: false,
      };
    }
  }

  // Create new anonymous user
  const userId = crypto.randomUUID();
  const plan: 'free' | 'pro' = 'free';
  const credits = PLAN_LIMITS.free.initialCredits;

  await db
    .prepare(
      'INSERT INTO users (id, plan, credits, auth_provider, device_hash) VALUES (?, ?, ?, ?, ?)'
    )
    .bind(userId, plan, credits, 'anon', deviceHash || null)
    .run();

  return {
    userId,
    plan,
    isNew: true,
  };
}

export async function createAuthToken(userId: string, jwtSecret: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const exp = now + 60 * 60 * 24 * 30; // 30 days

  return await signJwt(
    {
      sub: userId,
      iat: now,
      exp,
    },
    jwtSecret
  );
}
