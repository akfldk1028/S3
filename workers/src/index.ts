/**
 * S3 Workers — Entry Point
 *
 * Hono app + DO exports + Queue consumer
 *
 * - Hono<{ Bindings: Env; Variables: { user: AuthUser } }>
 * - Global middleware: cors, logger, auth
 * - Route mounts: auth, presets, rules, jobs, me
 * - Health check: GET /health
 * - 404 + error handler
 * - Queue consumer (dead-letter / retry)
 * - DO class exports
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';

import type { Env, AuthUser, GpuQueueMessage } from './_shared/types';
import { authMiddleware } from './middleware/auth.middleware';
import { ok, error } from './_shared/response';
import { ERR } from './_shared/errors';
import { generatePresignedUrl } from './_shared/r2';
import type { JobCoordinatorDO } from './do/JobCoordinatorDO';

// Import route handlers
import authRoute from './auth/auth.route';
import presetsRoute from './presets/presets.route';
import rulesRoute from './rules/rules.route';
import jobsRoute from './jobs/jobs.route';
import userRoute from './user/user.route';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// ─── CORS ────────────────────────────────────────────────
// localhost 모든 포트 허용 (Flutter web dev는 랜덤 포트 사용)
// 프로덕션 도메인 추가 시 PROD_ORIGINS에 추가
const PROD_ORIGINS = [
  'https://s3-workers.clickaround8.workers.dev',
  // 프로덕션 Flutter Web 도메인이 생기면 여기 추가
];

// Global middleware
app.use('*', cors({
  origin: (origin) => {
    if (!origin) return PROD_ORIGINS[0];
    if (origin.startsWith('http://localhost:')) return origin;
    if (PROD_ORIGINS.includes(origin)) return origin;
    return null;
  },
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));
// GET polling 로그 제외 — POST/PUT/DELETE만 로깅
app.use('*', async (c, next) => {
  if (c.req.method !== 'GET') {
    console.log(`[API] ${c.req.method} ${c.req.path}`);
  }
  await next();
  if (c.req.method !== 'GET' || c.res.status >= 400) {
    console.log(`[API] ${c.req.method} ${c.req.path} → ${c.res.status}`);
  }
});
app.use('*', authMiddleware);

// Health check (public, skipped by auth middleware)
app.get('/health', (c) => {
  return c.json(ok({ status: 'healthy', timestamp: new Date().toISOString() }));
});

// Mount route handlers
app.route('/auth', authRoute);
app.route('/presets', presetsRoute);
app.route('/rules', rulesRoute);
app.route('/jobs', jobsRoute);
app.route('/me', userRoute);

// 404 handler
app.notFound((c) => {
  return c.json(error(ERR.NOT_FOUND, 'Route not found'), 404);
});

// Global error handler
app.onError((err, c) => {
  console.error('Unhandled error:', err);
  const message = err instanceof Error ? err.message : 'Internal server error';
  return c.json(error(ERR.INTERNAL_ERROR, message), 500);
});

export default {
  fetch: app.fetch,
  queue: async (batch: MessageBatch<GpuQueueMessage>, env: Env) => {
    for (const msg of batch.messages) {
      try {
        const { items, concepts, job_id } = msg.body;
        const conceptNames = Object.keys(concepts);
        console.log(`[Queue] Job ${job_id} 시작 — items: ${items.length}, concepts: [${conceptNames}]`);

        // DO stub for progress updates
        const coordNs = env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
        const coordStub = coordNs.get(coordNs.idFromName(job_id));

        for (const item of items) {
          try {
            // 1. R2 presigned download URL 생성
            const imageUrl = await generatePresignedUrl(
              env, env.R2_BUCKET_NAME, item.input_key, 'GET', 3600,
            );
            console.log(`[Queue] Job ${job_id} item ${item.idx} — R2 URL 생성 완료`);

            // 2. Runpod에 비동기 전송
            const runRes = await fetch(
              `https://api.runpod.ai/v2/${env.RUNPOD_ENDPOINT_ID}/run`,
              {
                method: 'POST',
                headers: {
                  'Authorization': `Bearer ${env.RUNPOD_API_KEY}`,
                  'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                  input: { image_url: imageUrl, concepts: conceptNames },
                }),
              },
            );
            if (!runRes.ok) throw new Error(`Runpod ${runRes.status}`);
            const { id: rpJobId } = await runRes.json() as { id: string };
            console.log(`[Queue] Job ${job_id} item ${item.idx} — Runpod 전송 완료 (rpId: ${rpJobId})`);

            // 3. Polling — 완료될 때까지 15초 간격으로 확인 (최대 10분)
            //    CF Workers subrequest 제한(50회)에 맞춤
            let gpuResult: any = null;
            const pollStart = Date.now();
            for (let i = 0; i < 40; i++) {
              await new Promise(resolve => setTimeout(resolve, 15000));

              const sRes = await fetch(
                `https://api.runpod.ai/v2/${env.RUNPOD_ENDPOINT_ID}/status/${rpJobId}`,
                { headers: { 'Authorization': `Bearer ${env.RUNPOD_API_KEY}` } },
              );
              const sData = await sRes.json() as any;

              if (sData.status === 'COMPLETED') {
                const elapsed = ((Date.now() - pollStart) / 1000).toFixed(1);
                console.log(`[Queue] Job ${job_id} item ${item.idx} — GPU 완료 (${elapsed}s, execTime: ${sData.executionTime}ms)`);
                gpuResult = sData.output;
                break;
              }
              if (sData.status === 'FAILED') {
                console.error(`[Queue] Job ${job_id} item ${item.idx} — GPU 실패: ${sData.error}`);
                throw new Error(sData.error || 'GPU processing failed');
              }
              if (i % 6 === 5) {
                const elapsed = ((Date.now() - pollStart) / 1000).toFixed(0);
                console.log(`[Queue] Job ${job_id} item ${item.idx} — polling ${elapsed}s... (status: ${sData.status})`);
              }
            }
            if (!gpuResult) throw new Error('GPU processing timed out');

            // 4. 결과를 R2에 저장
            await env.R2.put(item.output_key, JSON.stringify(gpuResult));
            console.log(`[Queue] Job ${job_id} item ${item.idx} — R2 저장 완료 (${item.output_key})`);

            // 5. DO에 성공 보고 → progress 업데이트
            await coordStub.onItemResult({
              idx: item.idx,
              status: 'done',
              output_key: item.output_key,
              preview_key: item.preview_key,
              idempotency_key: `${job_id}-${item.idx}`,
            });
            console.log(`[Queue] Job ${job_id} item ${item.idx} — done 보고 완료`);
          } catch (itemErr) {
            console.error(`[Queue] Job ${job_id} item ${item.idx} 실패: ${itemErr}`);
            // 개별 item 실패 보고
            await coordStub.onItemResult({
              idx: item.idx,
              status: 'failed',
              error: String(itemErr),
              idempotency_key: `${job_id}-${item.idx}`,
            });
          }
        }

        msg.ack();
      } catch (e) {
        console.error(`[Queue] Message failed: ${e}`);
        msg.retry();
      }
    }
  },
};

export { UserLimiterDO } from './do/UserLimiterDO';
export { JobCoordinatorDO } from './do/JobCoordinatorDO';
