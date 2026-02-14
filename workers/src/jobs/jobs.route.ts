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
import type { Env, AuthUser, GpuQueueMessage, CallbackPayload, JobStatus } from '../_shared/types';
import { generateUploadUrls, pushToQueue } from './jobs.service';

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

// POST /jobs/:id/execute - Execute job with rules, push to GPU queue
app.post('/:id/execute', async (c) => {
  try {
    // 1. Get job ID from URL params
    const jobId = c.req.param('id');

    // 2. Parse request body
    const body = await c.req.json<{
      concepts: Record<string, { action: string; value: string }>;
      protect: string[];
      ruleId?: string;
    }>();

    const { concepts, protect, ruleId } = body;

    // Validate inputs
    if (!concepts || typeof concepts !== 'object') {
      return c.json(
        {
          success: false,
          error: { code: 'INVALID_CONCEPTS', message: 'concepts must be an object' },
        },
        400
      );
    }

    if (!Array.isArray(protect)) {
      return c.json(
        {
          success: false,
          error: { code: 'INVALID_PROTECT', message: 'protect must be an array' },
        },
        400
      );
    }

    // 3. Get JobCoordinatorDO stub
    const jobCoordinatorId = c.env.JOB_COORDINATOR.idFromName(jobId);
    const jobCoordinatorStub = c.env.JOB_COORDINATOR.get(jobCoordinatorId);

    // 4. Call markQueued to update job status and store rule config
    const markQueuedResponse = await jobCoordinatorStub.fetch('http://internal/mark-queued', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        concepts: JSON.stringify(concepts),
        protect: JSON.stringify(protect),
        ruleId: ruleId || null,
      }),
    });

    // 5. Handle error responses (e.g., not in 'uploaded' state)
    if (!markQueuedResponse.ok) {
      const errorResult = await markQueuedResponse.json<{ error: string }>();
      return c.json(
        {
          success: false,
          error: {
            code: 'INVALID_STATE_TRANSITION',
            message: errorResult.error || 'Cannot execute - job not in uploaded state',
          },
        },
        400
      );
    }

    // 6. Get job state to construct queue message
    const stateResponse = await jobCoordinatorStub.fetch('http://internal/state', {
      method: 'GET',
    });

    const jobState = await stateResponse.json<{
      jobId: string;
      userId: string;
      preset: string;
      totalItems: number;
      items: Array<{
        idx: number;
        inputKey: string;
        outputKey: string;
        previewKey: string;
      }>;
    }>();

    // 7. Construct GPU queue message
    const queueMessage: GpuQueueMessage = {
      job_id: jobState.jobId,
      user_id: jobState.userId,
      preset: jobState.preset,
      concepts,
      protect,
      items: jobState.items.map((item) => ({
        idx: item.idx,
        input_key: item.inputKey,
        output_key: item.outputKey,
        preview_key: item.previewKey,
      })),
      callback_url: `https://${c.req.header('host')}/api/jobs/${jobId}/callback`,
      idempotency_prefix: `${jobId}-`,
      batch_concurrency: 4,
    };

    // 8. Push message to GPU queue
    await pushToQueue(c.env.GPU_QUEUE, queueMessage);

    // 9. Return success response
    return c.json({
      success: true,
      data: {
        jobId,
        status: 'queued',
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

// GET /jobs/:id - Get job status and progress
app.get('/:id', async (c) => {
  try {
    // 1. Get job ID from URL params
    const jobId = c.req.param('id');

    // 2. Get JobCoordinatorDO stub
    const jobCoordinatorId = c.env.JOB_COORDINATOR.idFromName(jobId);
    const jobCoordinatorStub = c.env.JOB_COORDINATOR.get(jobCoordinatorId);

    // 3. Get job state
    const stateResponse = await jobCoordinatorStub.fetch('http://internal/state', {
      method: 'GET',
    });

    // 4. Handle 404 if job not found
    if (!stateResponse.ok) {
      const errorResult = await stateResponse.json<{ error: string }>();
      return c.json(
        {
          success: false,
          error: {
            code: 'JOB_NOT_FOUND',
            message: errorResult.error || 'Job not found',
          },
        },
        404
      );
    }

    const jobState = await stateResponse.json<{
      jobId: string;
      userId: string;
      status: string;
      totalItems: number;
      doneItems: number;
      failedItems: number;
    }>();

    // 5. Return job status and progress
    return c.json({
      success: true,
      data: {
        jobId: jobState.jobId,
        status: jobState.status,
        progress: {
          done: jobState.doneItems,
          failed: jobState.failedItems,
          total: jobState.totalItems,
        },
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

// POST /jobs/:id/callback - GPU Worker callback with idempotency
app.post('/:id/callback', async (c) => {
  try {
    // 1. Validate GPU_CALLBACK_SECRET header
    const secret = c.req.header('x-gpu-callback-secret');
    if (!secret || secret !== c.env.GPU_CALLBACK_SECRET) {
      return c.json(
        {
          success: false,
          error: { code: 'UNAUTHORIZED', message: 'Invalid or missing GPU callback secret' },
        },
        401
      );
    }

    // 2. Get job ID from URL params
    const jobId = c.req.param('id');

    // 3. Parse callback payload
    const payload = await c.req.json<CallbackPayload>();

    // Validate payload
    if (
      typeof payload.idx !== 'number' ||
      !payload.status ||
      !['done', 'failed'].includes(payload.status) ||
      !payload.idempotency_key
    ) {
      return c.json(
        {
          success: false,
          error: {
            code: 'INVALID_PAYLOAD',
            message: 'Callback payload must include idx, status (done|failed), and idempotency_key',
          },
        },
        400
      );
    }

    // 4. Get JobCoordinatorDO stub and call onItemResult
    const jobCoordinatorId = c.env.JOB_COORDINATOR.idFromName(jobId);
    const jobCoordinatorStub = c.env.JOB_COORDINATOR.get(jobCoordinatorId);

    const resultResponse = await jobCoordinatorStub.fetch('http://internal/on-item-result', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (!resultResponse.ok) {
      const errorResult = await resultResponse.json<{ error: string }>();
      return c.json(
        {
          success: false,
          error: {
            code: 'COORDINATOR_ERROR',
            message: errorResult.error || 'Failed to process callback',
          },
        },
        500
      );
    }

    const resultData = await resultResponse.json<{
      status: JobStatus;
      doneItems: number;
      failedItems: number;
      totalItems: number;
    }>();

    // 5. If job is in final state (done/failed/canceled), commit or rollback credits
    if (['done', 'failed', 'canceled'].includes(resultData.status)) {
      // Get job coordinator state to retrieve userId
      const statusResponse = await jobCoordinatorStub.fetch('http://internal/status', {
        method: 'GET',
      });

      const statusData = await statusResponse.json<{
        userId: string;
      }>();

      const userId = statusData.userId;

      // Get UserLimiterDO stub
      const userLimiterId = c.env.USER_LIMITER.idFromName(userId);
      const userLimiterStub = c.env.USER_LIMITER.get(userLimiterId);

      // Commit credits (refunds failed items, releases job slot)
      if (resultData.status === 'done' || resultData.status === 'failed') {
        await userLimiterStub.fetch('http://internal/commit', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            jobId,
            doneItems: resultData.doneItems,
            failedItems: resultData.failedItems,
          }),
        });
      } else if (resultData.status === 'canceled') {
        // Rollback all credits
        await userLimiterStub.fetch('http://internal/rollback', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            jobId,
            totalItems: resultData.totalItems,
          }),
        });
      }
    }

    // 6. Return success response
    return c.json({
      success: true,
      data: {
        jobId,
        status: resultData.status,
        progress: {
          done: resultData.doneItems,
          failed: resultData.failedItems,
          total: resultData.totalItems,
        },
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

// POST /jobs/:id/cancel

export default app;
