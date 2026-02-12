/**
 * DO Stub Lookup Helpers
 *
 * TODO: Auto-Claude 구현
 * - getUserLimiter(env, userId) → UserLimiterDO stub
 * - getJobCoordinator(env, jobId) → JobCoordinatorDO stub
 * - DO ID 생성: env.USER_LIMITER.idFromName(userId)
 */

import type { Env } from '../_shared/types';

export function getUserLimiterStub(env: Env, userId: string) {
  const id = env.USER_LIMITER.idFromName(userId);
  return env.USER_LIMITER.get(id);
}

export function getJobCoordinatorStub(env: Env, jobId: string) {
  const id = env.JOB_COORDINATOR.idFromName(jobId);
  return env.JOB_COORDINATOR.get(id);
}
