/**
 * Jobs Route — 7 endpoints (1 list + 6 pipeline)
 *
 * - GET  /jobs                    → Job 목록 (D1)
 * - POST /jobs                    → Job 생성 + presigned URLs
 * - POST /jobs/:id/confirm-upload → 업로드 완료 (created → uploaded)
 * - POST /jobs/:id/execute        → 룰 적용 실행 (uploaded → queued + Queue push)
 * - GET  /jobs/:id                → 상태/진행률 + download URLs
 * - POST /jobs/:id/callback       → GPU Worker 콜백 (GPU_CALLBACK_SECRET 검증)
 * - POST /jobs/:id/cancel         → 취소 + 크레딧 환불
 */

import { Hono } from 'hono';
import type { Env, AuthUser, GpuQueueMessage } from '../_shared/types';
import { authMiddleware } from '../middleware/auth.middleware';
import { ok, error } from '../_shared/response';
import { ERR } from '../_shared/errors';
import { CreateJobSchema, ExecuteJobSchema, CallbackSchema } from './jobs.validator';
import { generateUploadUrls, generateDownloadUrls, pushToQueue } from './jobs.service';
import type { UserLimiterDO } from '../do/UserLimiterDO';
import type { JobCoordinatorDO } from '../do/JobCoordinatorDO';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// ─── GET /jobs — list jobs for authenticated user ─────────────────────────────

app.get('/', authMiddleware, async (c) => {
  const user = c.get('user');

  const { results } = await c.env.DB.prepare(
    `SELECT job_id, status, preset, created_at, progress_done, progress_failed, progress_total
     FROM jobs_log
     WHERE user_id = ?
     ORDER BY created_at DESC
     LIMIT 50`,
  ).bind(user.userId).all();

  const jobs = (results ?? []).map((row: any) => ({
    job_id: row.job_id,
    status: row.status,
    preset: row.preset,
    created_at: row.created_at,
    progress: {
      done: row.progress_done ?? 0,
      failed: row.progress_failed ?? 0,
      total: row.progress_total ?? 0,
    },
  }));

  return c.json(ok(jobs));
});

// ─── POST /jobs — Job 생성 + presigned URLs ───────────────────────────────────

app.post('/', authMiddleware, async (c) => {
  const user = c.get('user');

  const body = await c.req.json();
  const parsed = CreateJobSchema.safeParse(body);
  if (!parsed.success) {
    return c.json(error(ERR.VALIDATION_FAILED, 'Invalid request body'), 400);
  }

  const { preset, item_count } = parsed.data;

  try {
    // D1에서 plan 조회
    const userRow = await c.env.DB
      .prepare('SELECT plan FROM users WHERE id = ?')
      .bind(user.userId)
      .first<{ plan: 'free' | 'pro' }>();
    const plan = userRow?.plan ?? 'free';

    // UserLimiterDO: init + reserve
    const limiterNs = c.env.USER_LIMITER as unknown as DurableObjectNamespace<UserLimiterDO>;
    const limiterStub = limiterNs.get(limiterNs.idFromName(user.userId));
    await limiterStub.init(user.userId, plan);

    const jobId = crypto.randomUUID();
    const reservation = await limiterStub.reserve(jobId, item_count);

    if (!reservation.allowed) {
      const reasonMap: Record<string, { code: string; msg: string }> = {
        concurrency_limit: { code: ERR.CONCURRENCY_LIMIT, msg: 'Too many concurrent jobs' },
        item_limit: { code: ERR.ITEM_LIMIT, msg: 'Item count exceeds plan limit' },
        insufficient_credits: { code: ERR.INSUFFICIENT_CREDITS, msg: 'Not enough credits' },
      };
      const r = reasonMap[reservation.reason ?? ''] ?? { code: ERR.INSUFFICIENT_CREDITS, msg: 'Reserve denied' };
      return c.json(error(r.code, r.msg), 403);
    }

    // JobCoordinatorDO: create
    const coordNs = c.env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
    const coordStub = coordNs.get(coordNs.idFromName(jobId));
    await coordStub.create(jobId, user.userId, preset, item_count);

    // Generate presigned upload URLs
    const presigned_urls = await generateUploadUrls(c.env, user.userId, jobId, item_count);

    return c.json(ok({ job_id: jobId, presigned_urls }), 201);
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

// ─── POST /jobs/:id/confirm-upload ────────────────────────────────────────────

app.post('/:id/confirm-upload', authMiddleware, async (c) => {
  const jobId = c.req.param('id');

  try {
    const coordNs = c.env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
    const coordStub = coordNs.get(coordNs.idFromName(jobId));
    const result = await coordStub.confirmUpload();

    if (!result.success) {
      return c.json(error(ERR.JOB_INVALID_TRANSITION, 'Cannot confirm upload in current state'), 400);
    }

    return c.json(ok({ confirmed: true }));
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

// ─── POST /jobs/:id/execute ───────────────────────────────────────────────────

app.post('/:id/execute', authMiddleware, async (c) => {
  const user = c.get('user');
  const jobId = c.req.param('id');

  const body = await c.req.json();
  const parsed = ExecuteJobSchema.safeParse(body);
  if (!parsed.success) {
    return c.json(error(ERR.VALIDATION_FAILED, 'Invalid request body'), 400);
  }

  const { concepts, protect, rule_id } = parsed.data;

  try {
    const coordNs = c.env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
    const coordStub = coordNs.get(coordNs.idFromName(jobId));

    // Mark queued (uploaded → queued)
    const result = await coordStub.markQueued(
      JSON.stringify(concepts),
      JSON.stringify(protect),
      rule_id,
    );

    if (!result.success) {
      return c.json(error(ERR.JOB_INVALID_TRANSITION, 'Cannot execute in current state'), 400);
    }

    // Get job state for queue message
    const status = await coordStub.getStatus();
    if (!status) {
      return c.json(error(ERR.JOB_NOT_FOUND, 'Job not found'), 404);
    }

    // Build items array for GPU queue message
    const items = [];
    for (let idx = 0; idx < status.state.totalItems; idx++) {
      items.push({
        idx,
        input_key: `inputs/${user.userId}/${jobId}/${idx}.jpg`,
        output_key: `outputs/${user.userId}/${jobId}/${idx}_result.png`,
        preview_key: `previews/${user.userId}/${jobId}/${idx}_thumb.jpg`,
      });
    }

    const callbackUrl = new URL(c.req.url);
    callbackUrl.pathname = `/jobs/${jobId}/callback`;

    const queueMessage: GpuQueueMessage = {
      job_id: jobId,
      user_id: user.userId,
      preset: status.state.preset,
      concepts,
      protect,
      items,
      callback_url: callbackUrl.toString(),
      idempotency_prefix: `${jobId}-`,
      batch_concurrency: 4,
    };

    await pushToQueue(c.env.GPU_QUEUE, queueMessage, jobId);

    return c.json(ok({ queued: true }), 202);
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

// ─── GET /jobs/:id — 상태/진행률 ──────────────────────────────────────────────

app.get('/:id', authMiddleware, async (c) => {
  const user = c.get('user');
  const jobId = c.req.param('id');

  try {
    const coordNs = c.env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
    const coordStub = coordNs.get(coordNs.idFromName(jobId));
    const status = await coordStub.getStatus();

    if (!status) {
      return c.json(error(ERR.JOB_NOT_FOUND, 'Job not found'), 404);
    }

    if (status.state.userId !== user.userId) {
      return c.json(error(ERR.JOB_FORBIDDEN, 'Access denied'), 403);
    }

    // Generate download URLs for completed items
    const doneItems = status.items.filter((i) => i.status === 'done' && i.outputKey);
    const downloadUrls = doneItems.length > 0
      ? await generateDownloadUrls(c.env, user.userId, jobId, doneItems)
      : [];

    return c.json(ok({
      job: {
        job_id: status.state.jobId,
        user_id: status.state.userId,
        status: status.state.status,
        preset: status.state.preset,
        total_items: status.state.totalItems,
        done_items: status.state.doneItems,
        failed_items: status.state.failedItems,
        items: status.items.map((i) => ({
          idx: i.idx,
          status: i.status,
          ...(i.error ? { error: i.error } : {}),
        })),
        download_urls: downloadUrls,
      },
    }));
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

// ─── POST /jobs/:id/callback — GPU Worker 콜백 ───────────────────────────────

app.post('/:id/callback', async (c) => {
  // GPU_CALLBACK_SECRET 검증 (NOT JWT)
  const secret = c.req.header('X-Callback-Secret');
  if (!secret || secret !== c.env.GPU_CALLBACK_SECRET) {
    return c.json(error(ERR.CALLBACK_UNAUTHORIZED, 'Invalid callback secret'), 401);
  }

  const jobId = c.req.param('id');

  const body = await c.req.json();
  const parsed = CallbackSchema.safeParse(body);
  if (!parsed.success) {
    return c.json(error(ERR.VALIDATION_FAILED, 'Invalid callback payload'), 400);
  }

  try {
    const coordNs = c.env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
    const coordStub = coordNs.get(coordNs.idFromName(jobId));
    const result = await coordStub.onItemResult(parsed.data);

    return c.json(ok({ processed: !result.duplicate }));
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

// ─── POST /jobs/:id/cancel ────────────────────────────────────────────────────

app.post('/:id/cancel', authMiddleware, async (c) => {
  const user = c.get('user');
  const jobId = c.req.param('id');

  try {
    const coordNs = c.env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
    const coordStub = coordNs.get(coordNs.idFromName(jobId));

    // Verify ownership
    const status = await coordStub.getStatus();
    if (!status) {
      return c.json(error(ERR.JOB_NOT_FOUND, 'Job not found'), 404);
    }
    if (status.state.userId !== user.userId) {
      return c.json(error(ERR.JOB_FORBIDDEN, 'Access denied'), 403);
    }

    const result = await coordStub.cancel();
    if (!result.success) {
      return c.json(error(ERR.JOB_INVALID_TRANSITION, 'Cannot cancel in current state'), 400);
    }

    // Rollback credits via UserLimiterDO
    const userRow = await c.env.DB
      .prepare('SELECT plan FROM users WHERE id = ?')
      .bind(user.userId)
      .first<{ plan: 'free' | 'pro' }>();
    const plan = userRow?.plan ?? 'free';

    const limiterNs = c.env.USER_LIMITER as unknown as DurableObjectNamespace<UserLimiterDO>;
    const limiterStub = limiterNs.get(limiterNs.idFromName(user.userId));
    await limiterStub.init(user.userId, plan);
    await limiterStub.rollback(jobId);

    return c.json(ok({ canceled: true }));
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

export default app;
