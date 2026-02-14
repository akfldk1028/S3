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
import { generateUploadUrls } from './jobs.service';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// POST /jobs - Create job, reserve credits, generate presigned URLs
app.post('/', async (c) => {
  try {
    // 1. Get authenticated user
    const user = c.get('user');
    const userId = user.userId;

    // 2. Parse request body
    const body = await c.req.json<{
      preset: string;
      itemCount: number;
    }>();

    const { preset, itemCount } = body;

    // Validate inputs
    if (!preset || typeof preset !== 'string') {
      return c.json(
        { success: false, error: { code: 'INVALID_PRESET', message: 'Invalid preset value' } },
        400
      );
    }

    if (!itemCount || typeof itemCount !== 'number' || itemCount < 1) {
      return c.json(
        { success: false, error: { code: 'INVALID_ITEM_COUNT', message: 'Item count must be >= 1' } },
        400
      );
    }

    // 3. Generate unique job ID
    const jobId = crypto.randomUUID();

    // 4. Get UserLimiterDO stub and reserve credits
    const userLimiterId = c.env.USER_LIMITER.idFromName(userId);
    const userLimiterStub = c.env.USER_LIMITER.get(userLimiterId);

    const reserveResponse = await userLimiterStub.fetch('http://internal/reserve', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        jobId,
        itemCount,
      }),
    });

    const reserveResult = await reserveResponse.json<{
      allowed: boolean;
      reason?: string;
    }>();

    // 5. If reserve fails, return 403
    if (!reserveResult.allowed) {
      return c.json(
        {
          success: false,
          error: {
            code: 'INSUFFICIENT_RESOURCES',
            message: reserveResult.reason || 'Insufficient credits or concurrency limit reached',
          },
        },
        403
      );
    }

    // 6. Get JobCoordinatorDO stub and create job
    const jobCoordinatorId = c.env.JOB_COORDINATOR.idFromName(jobId);
    const jobCoordinatorStub = c.env.JOB_COORDINATOR.get(jobCoordinatorId);

    await jobCoordinatorStub.fetch('http://internal/create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        jobId,
        userId,
        preset,
        totalItems: itemCount,
      }),
    });

    // 7. Generate presigned upload URLs
    const uploadUrls = await generateUploadUrls(c.env, userId, jobId, itemCount);

    // 8. Return success response with jobId and URLs
    return c.json({
      success: true,
      data: {
        jobId,
        urls: uploadUrls,
      },
      error: null,
      meta: {
        request_id: crypto.randomUUID(),
        timestamp: new Date().toISOString(),
      },
    });
  } catch (error) {
    return c.json(
      {
        success: false,
        data: null,
        error: {
          code: 'INTERNAL_ERROR',
          message: error instanceof Error ? error.message : 'Unknown error occurred',
        },
        meta: {
          request_id: crypto.randomUUID(),
          timestamp: new Date().toISOString(),
        },
      },
      500
    );
  }
});

// POST /jobs/:id/confirm-upload - Mark items uploaded
app.post('/:id/confirm-upload', async (c) => {
  try {
    // 1. Get job ID from URL params
    const jobId = c.req.param('id');

    // 2. Parse request body
    const body = await c.req.json<{
      totalItems: number;
    }>();

    const { totalItems } = body;

    // Validate inputs
    if (!totalItems || typeof totalItems !== 'number' || totalItems < 1) {
      return c.json(
        {
          success: false,
          error: { code: 'INVALID_TOTAL_ITEMS', message: 'totalItems must be >= 1' },
        },
        400
      );
    }

    // 3. Get JobCoordinatorDO stub and call confirmUpload
    const jobCoordinatorId = c.env.JOB_COORDINATOR.idFromName(jobId);
    const jobCoordinatorStub = c.env.JOB_COORDINATOR.get(jobCoordinatorId);

    const confirmResponse = await jobCoordinatorStub.fetch('http://internal/confirm-upload', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ totalItems }),
    });

    // 4. Handle error responses (e.g., invalid state transition)
    if (!confirmResponse.ok) {
      const errorResult = await confirmResponse.json<{ error: string }>();
      return c.json(
        {
          success: false,
          error: {
            code: 'INVALID_STATE_TRANSITION',
            message: errorResult.error || 'Cannot confirm upload - job not in created state',
          },
        },
        400
      );
    }

    // 5. Return success response
    return c.json({
      success: true,
      data: {
        jobId,
        status: 'uploaded',
      },
      error: null,
      meta: {
        request_id: crypto.randomUUID(),
        timestamp: new Date().toISOString(),
      },
    });
  } catch (error) {
    return c.json(
      {
        success: false,
        data: null,
        error: {
          code: 'INTERNAL_ERROR',
          message: error instanceof Error ? error.message : 'Unknown error occurred',
        },
        meta: {
          request_id: crypto.randomUUID(),
          timestamp: new Date().toISOString(),
        },
      },
      500
    );
  }
});

// POST /jobs/:id/execute
// GET /jobs/:id
// POST /jobs/:id/callback
// POST /jobs/:id/cancel

export default app;
