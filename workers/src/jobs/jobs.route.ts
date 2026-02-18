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
import type {
  Env,
  AuthUser,
  GpuQueueMessage,
  JobCoordinatorState,
  JobItemState,
} from '../_shared/types';
import { pushToQueue } from './jobs.service';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// POST /jobs — TODO: implement

// POST /jobs/:id/confirm-upload — TODO: implement

// POST /jobs/:id/execute
app.post('/:id/execute', async (c) => {
  const user = c.var.user;
  const jobId = c.req.param('id');

  const body = await c.req.json() as {
    concepts: Record<string, { action: string; value: string }>;
    protect?: string[];
    ruleId?: string | null;
  };

  // Get the JobCoordinatorDO stub for this job
  const doId = c.env.JOB_COORDINATOR.idFromName(jobId);
  const doStub = c.env.JOB_COORDINATOR.get(doId);

  // 1. Transition job state: uploaded → queued (stores concepts/protect/ruleId)
  const markQueuedResp = await doStub.fetch('http://internal/mark-queued', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      conceptsJson: JSON.stringify(body.concepts),
      protectJson: JSON.stringify(body.protect ?? []),
      ruleId: body.ruleId ?? null,
    }),
  });

  if (!markQueuedResp.ok) {
    const err = await markQueuedResp.json() as { error: string };
    const httpStatus = err.error?.startsWith('INVALID_STATE_TRANSITION') ? 400 : 500;
    return c.json({ error: err.error }, httpStatus);
  }

  // 2. Read full state to build the GPU queue message
  const stateResp = await doStub.fetch('http://internal/state');
  if (!stateResp.ok) {
    return c.json({ error: 'Failed to read job state' }, 500);
  }

  const stateData = await stateResp.json() as {
    state: JobCoordinatorState;
    items: JobItemState[];
  } | null;

  if (!stateData) {
    return c.json({ error: 'Job not found' }, 404);
  }

  const { state, items } = stateData;

  // 3. Construct GPU queue message
  // callback_url uses request origin so it works across dev/prod environments
  const origin = new URL(c.req.url).origin;
  const callbackUrl = `${origin}/jobs/${jobId}/callback`;

  const queueMessage: GpuQueueMessage = {
    job_id: jobId,
    user_id: user.userId,
    preset: state.preset,
    concepts: body.concepts,
    protect: body.protect ?? [],
    items: items.map((item) => ({
      idx: item.idx,
      input_key: item.inputKey,
      // output_key / preview_key are destination paths written by the GPU worker
      output_key: `jobs/${jobId}/output/${item.idx}`,
      preview_key: `jobs/${jobId}/preview/${item.idx}`,
    })),
    callback_url: callbackUrl,
    idempotency_prefix: `${jobId}-item`,
    batch_concurrency: 3,
  };

  // 4. Push to GPU queue — deduplicationId prevents duplicate pushes within a 5-minute window
  //    Handles the case where /execute is retried due to a transient network error
  await pushToQueue(c.env.GPU_QUEUE, queueMessage, `execute-${jobId}`);

  return c.json({ ok: true, status: 'queued' });
});

// GET /jobs/:id — TODO: implement

// POST /jobs/:id/callback — TODO: implement

// POST /jobs/:id/cancel — TODO: implement

export default app;
