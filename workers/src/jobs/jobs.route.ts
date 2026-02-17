/**
 * Jobs Route — 6 endpoints
 *
 * - POST /jobs → Job 생성 + presigned URLs (UserLimiterDO.reserve → JobCoordinatorDO.create → R2 presigned)
 * - POST /jobs/:id/confirm-upload → 업로드 완료 (JobCoordinatorDO.markUploaded)
 * - POST /jobs/:id/execute → 룰 적용 실행 (JobCoordinatorDO.markQueued → Queue push)
 * - GET /jobs/:id → 상태/진행률 (JobCoordinatorDO.getStatus → presigned download URLs)
 * - POST /jobs/:id/callback → GPU 콜백 (GPU_CALLBACK_SECRET 검증 → JobCoordinatorDO.onItemResult)
 * - POST /jobs/:id/cancel → 취소 (JobCoordinatorDO.cancel)
 */

import { Hono } from 'hono';
import type { Env, AuthUser, UserLimiterState, JobCoordinatorState } from '../_shared/types';
import { PLAN_LIMITS } from '../_shared/types';
import { ERR } from '../_shared/errors';
import { ok, error } from '../_shared/response';
import { getUserLimiterStub, getJobCoordinatorStub } from '../do/do.helpers';
import { CreateJobSchema } from './jobs.validator';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// POST /jobs — Job 생성 + presigned URLs
app.post('/', async (c) => {
  const user = c.get('user');
  const userId = user.userId;

  // Validate request body
  let body: unknown;
  try {
    body = await c.req.json();
  } catch {
    return c.json(error(ERR.VALIDATION_FAILED, 'Invalid JSON body'), 400);
  }

  const parsed = CreateJobSchema.safeParse(body);
  if (!parsed.success) {
    return c.json(
      error(ERR.VALIDATION_FAILED, parsed.error.issues[0]?.message ?? 'Invalid request'),
      400,
    );
  }

  const { preset, item_count: itemCount } = parsed.data;

  // Get UserLimiter DO stub
  const userLimiterStub = getUserLimiterStub(c.env, userId);

  // [CRED-3] getUserState를 먼저 호출하여 plan별 maxItems 초과 시 400 + ERR.ITEM_LIMIT 반환
  const userStateResponse = await userLimiterStub.fetch('http://do/getUserState', {
    method: 'GET',
  });

  if (!userStateResponse.ok) {
    return c.json(error(ERR.INTERNAL_ERROR, 'User state not found'), 400);
  }

  const userState = await userStateResponse.json<UserLimiterState>();
  const maxItems = PLAN_LIMITS[userState.plan].maxItems;

  if (itemCount > maxItems) {
    return c.json(
      error(
        ERR.ITEM_LIMIT,
        `Item count exceeds plan limit: max ${maxItems} for ${userState.plan} plan`,
      ),
      400,
    );
  }

  // Reserve credits and concurrency slot (called AFTER itemCount validation)
  const jobId = crypto.randomUUID();
  const reserveResponse = await userLimiterStub.fetch('http://do/reserve', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ jobId, cost: itemCount }),
  });

  const reserveResult = await reserveResponse.json<{ reserved: boolean }>();

  if (!reserveResult.reserved) {
    if (userState.credits < itemCount) {
      return c.json(error(ERR.INSUFFICIENT_CREDITS, 'Insufficient credits'), 402);
    }
    return c.json(error(ERR.CONCURRENCY_LIMIT, 'Concurrency limit reached'), 429);
  }

  // Create job in JobCoordinatorDO
  const jobCoordinatorStub = getJobCoordinatorStub(c.env, jobId);
  await jobCoordinatorStub.fetch('http://do/create', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ jobId, userId, preset, totalItems: itemCount }),
  });

  // TODO: Generate R2 presigned upload URLs via jobs.service.ts
  return c.json(ok({ job_id: jobId, preset, item_count: itemCount, upload_urls: [] }), 201);
});

// POST /jobs/:id/confirm-upload
app.post('/:id/confirm-upload', async (c) => {
  const userId = c.get('user').userId;
  const jobId = c.req.param('id');

  const stub = getJobCoordinatorStub(c.env, jobId);

  const stateResponse = await stub.fetch('http://do/getStatus', { method: 'GET' });
  if (!stateResponse.ok) {
    return c.json(error(ERR.JOB_NOT_FOUND, 'Job not found'), 404);
  }

  const jobState = await stateResponse.json<JobCoordinatorState>();
  if (jobState.userId !== userId) {
    return c.json(error(ERR.JOB_FORBIDDEN, 'Access denied'), 403);
  }

  const markResponse = await stub.fetch('http://do/markUploaded', { method: 'POST' });
  if (!markResponse.ok) {
    const body = await markResponse.json<{ code?: string; message?: string }>();
    return c.json(
      error(body.code ?? ERR.INTERNAL_ERROR, body.message ?? 'Failed to mark uploaded'),
      400,
    );
  }

  return c.json(ok({ job_id: jobId }));
});

// POST /jobs/:id/execute
app.post('/:id/execute', async (c) => {
  const userId = c.get('user').userId;
  const jobId = c.req.param('id');

  const stub = getJobCoordinatorStub(c.env, jobId);

  const stateResponse = await stub.fetch('http://do/getStatus', { method: 'GET' });
  if (!stateResponse.ok) {
    return c.json(error(ERR.JOB_NOT_FOUND, 'Job not found'), 404);
  }

  const jobState = await stateResponse.json<JobCoordinatorState>();
  if (jobState.userId !== userId) {
    return c.json(error(ERR.JOB_FORBIDDEN, 'Access denied'), 403);
  }

  const markResponse = await stub.fetch('http://do/markQueued', { method: 'POST' });
  if (!markResponse.ok) {
    const body = await markResponse.json<{ code?: string; message?: string }>();
    return c.json(
      error(body.code ?? ERR.INTERNAL_ERROR, body.message ?? 'Failed to mark queued'),
      400,
    );
  }

  // TODO: Push to GPU_QUEUE after markQueued succeeds
  return c.json(ok({ job_id: jobId }));
});

// GET /jobs/:id
app.get('/:id', async (c) => {
  // TODO: getStatus + presigned download URLs
  return c.json(error(ERR.INTERNAL_ERROR, 'Not implemented'), 501);
});

// POST /jobs/:id/callback
app.post('/:id/callback', async (c) => {
  // TODO: [SEC-1] GPU_CALLBACK_SECRET verification + job existence check + onItemResult
  return c.json(error(ERR.INTERNAL_ERROR, 'Not implemented'), 501);
});

// POST /jobs/:id/cancel
app.post('/:id/cancel', async (c) => {
  const userId = c.get('user').userId;
  const jobId = c.req.param('id');

  const stub = getJobCoordinatorStub(c.env, jobId);

  const stateResponse = await stub.fetch('http://do/getStatus', { method: 'GET' });
  if (!stateResponse.ok) {
    return c.json(error(ERR.JOB_NOT_FOUND, 'Job not found'), 404);
  }

  const jobState = await stateResponse.json<JobCoordinatorState>();
  if (jobState.userId !== userId) {
    return c.json(error(ERR.JOB_FORBIDDEN, 'Access denied'), 403);
  }

  const cancelResponse = await stub.fetch('http://do/cancel', { method: 'POST' });
  if (!cancelResponse.ok) {
    const body = await cancelResponse.json<{ code?: string; message?: string }>();
    return c.json(
      error(body.code ?? ERR.INTERNAL_ERROR, body.message ?? 'Failed to cancel job'),
      400,
    );
  }

  return c.json(ok({ job_id: jobId }));
});

export default app;
