/**
 * Jobs Route — 6 endpoints
 *
 * TODO: Auto-Claude 구현
 * - POST /jobs → Job 생성 + presigned URLs (UserLimiterDO.reserve → JobCoordinatorDO.create → R2 presigned)
 * - POST /jobs/:id/confirm-upload → 업로드 완료 (JobCoordinatorDO.markUploaded)
 * - POST /jobs/:id/execute → 룰 적용 실행 (JobCoordinatorDO.markQueued → Queue push)
 * - GET /jobs/:id → 상태/진행률 (JobCoordinatorDO.getStatus → presigned download URLs)
 * - POST /jobs/:id/callback → GPU 콜백 (GPU_CALLBACK_SECRET 검증 → JobCoordinatorDO.onItemResult)
 * - POST /jobs/:id/cancel → 취소 (JobCoordinatorDO.cancel)
 */

import { Hono } from 'hono';
import type { Env, AuthUser } from '../_shared/types';
import { authMiddleware } from '../middleware/auth.middleware';
import { ok } from '../_shared/response';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// GET /jobs — list jobs for authenticated user
app.get('/', authMiddleware, async (c) => {
  const user = c.get('user');

  const { results } = await c.env.DB.prepare(
    `SELECT job_id, status, preset, created_at, progress_done, progress_failed, progress_total
     FROM jobs
     WHERE user_id = ?
     ORDER BY created_at DESC
     LIMIT 50`,
  ).bind(user.userId).all();

  return c.json(ok(results));
});

// POST /jobs
// POST /jobs/:id/confirm-upload
// POST /jobs/:id/execute
// GET /jobs/:id
// POST /jobs/:id/callback
// POST /jobs/:id/cancel

export default app;
