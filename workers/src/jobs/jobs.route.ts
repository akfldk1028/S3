/**
 * Jobs Route — 6 endpoints
 *
 * - POST /jobs → Job 생성 + presigned URLs (UserLimiterDO.reserve → JobCoordinatorDO.create → R2 presigned)
 * - POST /jobs/:id/confirm-upload → 업로드 완료 (JobCoordinatorDO.confirmUpload)
 * - POST /jobs/:id/execute → 룰 적용 실행 (JobCoordinatorDO.markQueued → Queue push)
 * - GET /jobs/:id → 상태/진행률 (JobCoordinatorDO.getStatus → presigned download URLs)
 * - POST /jobs/:id/callback → GPU 콜백 (GPU_CALLBACK_SECRET 검증 → JobCoordinatorDO.onItemResult)
 * - POST /jobs/:id/cancel → 취소 (JobCoordinatorDO.cancel)
 */

import { Hono } from 'hono';
<<<<<<< HEAD
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
=======
import type { Env, AuthUser, CallbackPayload } from '../_shared/types';
import { ok, error } from '../_shared/response';
import { ERR } from '../_shared/errors';
import type { UserLimiterDO } from '../do/UserLimiterDO';
import type { JobCoordinatorDO } from '../do/JobCoordinatorDO';
import { generateUploadUrls, pushToQueue } from './jobs.service';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// ─── POST /jobs ──────────────────────────────────────────────────────────────
// Job 생성 + presigned PUT URLs 반환

app.post('/', async (c) => {
  const user = c.get('user');
  const body = await c.req.json<{ preset: string; item_count: number }>();
  const { preset, item_count } = body;

  if (!preset) {
    return c.json(error(ERR.INVALID_PRESET, 'preset is required'), 400);
  }

  if (!item_count || item_count < 1) {
    return c.json(error(ERR.INVALID_ITEM_COUNT, 'item_count must be at least 1'), 400);
  }

  const jobId = crypto.randomUUID();

  try {
    // 1. Reserve credits + concurrency slot
    const limiterNs = c.env.USER_LIMITER as unknown as DurableObjectNamespace<UserLimiterDO>;
    const limiterStub = limiterNs.get(limiterNs.idFromName(user.userId));
    const reservation = await limiterStub.reserve(jobId, item_count);

    if (!reservation.allowed) {
      const reason = reservation.reason ?? 'limit_exceeded';
      if (reason === 'insufficient_credits') {
        return c.json(error(ERR.INSUFFICIENT_CREDITS, 'Insufficient credits for this job'), 402);
      }
      if (reason === 'concurrency_limit') {
        return c.json(error(ERR.CONCURRENCY_LIMIT, 'Concurrent job limit reached'), 429);
      }
      if (reason === 'item_limit') {
        return c.json(error(ERR.ITEM_LIMIT, 'Item count exceeds plan limit'), 400);
      }
      return c.json(error(ERR.INSUFFICIENT_CREDITS, 'Resource limit exceeded'), 403);
    }

    // 2. Initialize job coordinator DO
    const coordNs = c.env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
    const coordStub = coordNs.get(coordNs.idFromName(jobId));
    await coordStub.create(jobId, user.userId, preset, item_count);

    // 3. Generate presigned R2 upload URLs
    const uploadUrls = await generateUploadUrls(user.userId, jobId, item_count);

    return c.json(ok({ jobId, urls: uploadUrls }), 201);
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

// ─── POST /jobs/:id/confirm-upload ──────────────────────────────────────────
// 업로드 완료 신호 → created → uploaded FSM 전환

app.post('/:id/confirm-upload', async (c) => {
  const jobId = c.req.param('id');

  try {
    const coordNs = c.env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
    const coordStub = coordNs.get(coordNs.idFromName(jobId));
    const result = await coordStub.confirmUpload();

    if (!result.success) {
      return c.json(
        error(ERR.JOB_INVALID_TRANSITION, 'Cannot confirm upload in current job state'),
        409,
      );
    }

    return c.json(ok({ jobId, status: 'uploaded' }));
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

// ─── POST /jobs/:id/execute ──────────────────────────────────────────────────
// 룰 적용 실행 → uploaded → queued FSM 전환 + GPU Queue push

app.post('/:id/execute', async (c) => {
  const user = c.get('user');
  const jobId = c.req.param('id');
  const body = await c.req.json<{
    concepts: Record<string, { action: string; value: string }>;
    protect: string[];
    rule_id?: string;
    output_template?: string;
  }>();

  try {
    const coordNs = c.env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
    const coordStub = coordNs.get(coordNs.idFromName(jobId));

    // 1. Get current job state (for preset + items)
    const status = await coordStub.getStatus();
    if (!status) {
      return c.json(error(ERR.JOB_NOT_FOUND, 'Job not found'), 404);
    }

    // 2. Transition to queued + store rule params
    const result = await coordStub.markQueued(
      JSON.stringify(body.concepts ?? {}),
      JSON.stringify(body.protect ?? []),
      body.rule_id,
    );

    if (!result.success) {
      return c.json(
        error(ERR.JOB_INVALID_TRANSITION, 'Cannot execute job in current state'),
        409,
      );
    }

    // 3. Push to GPU queue
    await pushToQueue(c.env.GPU_QUEUE, {
      job_id: jobId,
      user_id: user.userId,
      preset: body.output_template ?? status.state.preset,
      concepts: body.concepts ?? {},
      protect: body.protect ?? [],
      items: status.items.map((item) => ({
        idx: item.idx,
        input_key: `inputs/${user.userId}/${jobId}/${item.idx}.jpg`,
        output_key: `outputs/${user.userId}/${jobId}/${item.idx}_result.png`,
        preview_key: `previews/${user.userId}/${jobId}/${item.idx}_thumb.jpg`,
      })),
      callback_url: `https://s3-workers.clickaround8.workers.dev/jobs/${jobId}/callback`,
      idempotency_prefix: `${jobId}-`,
      batch_concurrency: 1,
    });

    return c.json(ok({ jobId, status: 'queued' }));
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

// ─── GET /jobs/:id ───────────────────────────────────────────────────────────
// 상태 조회 + 완료 항목 presigned GET URLs

app.get('/:id', async (c) => {
  const jobId = c.req.param('id');

  try {
    const coordNs = c.env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
    const coordStub = coordNs.get(coordNs.idFromName(jobId));
    const result = await coordStub.getStatus();

    if (!result) {
      return c.json(error(ERR.JOB_NOT_FOUND, 'Job not found'), 404);
    }

    return c.json(ok({ job: result.state, items: result.items }));
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

// ─── POST /jobs/:id/callback ─────────────────────────────────────────────────
// GPU 콜백 — GPU_CALLBACK_SECRET 헤더 검증 후 결과 기록

app.post('/:id/callback', async (c) => {
  const jobId = c.req.param('id');

  // Verify GPU callback secret (no auth middleware — uses shared secret)
  const secret = c.req.header('X-Callback-Secret');
  if (!secret || secret !== c.env.GPU_CALLBACK_SECRET) {
    return c.json(error(ERR.CALLBACK_UNAUTHORIZED, 'Invalid callback secret'), 401);
  }

  const body = await c.req.json<CallbackPayload>();

  try {
    const coordNs = c.env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
    const coordStub = coordNs.get(coordNs.idFromName(jobId));
    const result = await coordStub.onItemResult(body);

    return c.json(ok({ success: result.success, duplicate: result.duplicate }));
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

// ─── POST /jobs/:id/cancel ───────────────────────────────────────────────────
// 취소 — non-terminal 상태에서만 가능

app.post('/:id/cancel', async (c) => {
  const jobId = c.req.param('id');

  try {
    const coordNs = c.env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
    const coordStub = coordNs.get(coordNs.idFromName(jobId));
    const result = await coordStub.cancel();

    if (!result.success) {
      return c.json(
        error(ERR.JOB_INVALID_TRANSITION, 'Cannot cancel job in current state'),
        409,
      );
    }

    return c.json(ok({ jobId, canceled: true }));
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});
>>>>>>> auto-claude/025-workers-cors-일관성-cors

export default app;
