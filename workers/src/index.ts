/**
 * S3 Workers — Entry Point
 *
 * Hono app + DO exports + Queue consumer
 *
 * - Hono<{ Bindings: Env; Variables: { user: AuthUser } }>
 * - Global middleware: cors, logger, auth
 * - Route mounts: auth, presets, rules, jobs, user
 * - Health check: GET /health
 * - 404 + error handler
 * - Queue consumer (dead-letter / retry)
 * - DO class exports
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import type { Env, AuthUser } from './_shared/types';
import { authMiddleware } from './middleware/auth.middleware';
import { ok, error } from './_shared/response';
import { ERR } from './_shared/errors';

// Import route handlers
import authRoute from './auth/auth.route';
import presetsRoute from './presets/presets.route';
import rulesRoute from './rules/rules.route';
import jobsRoute from './jobs/jobs.route';
import userRoute from './user/user.route';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

<<<<<<< HEAD
// Global middleware
app.use('*', cors());
=======
// ─── CORS Allowlist ──────────────────────────────────────
// 명시적 origin 허용 목록 — 와일드카드(*) 사용 금지
// credentials: true (JWT Authorization 헤더) 사용 시 * 불가 (브라우저 보안 요구사항)
const ALLOWED_ORIGINS = [
  'http://localhost:8080',                          // Flutter web dev
  'http://localhost:3000',                          // 로컬 Workers dev (self)
  'https://s3-workers.clickaround8.workers.dev',   // CF Workers prod
  // 프로덕션 Flutter Web 도메인이 생기면 여기 추가
];

// Global middleware
app.use('*', cors({
  origin: ALLOWED_ORIGINS,
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));
>>>>>>> auto-claude/025-workers-cors-일관성-cors
app.use('*', logger());
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
app.route('/user', userRoute);

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
  queue: async (batch: MessageBatch, env: Env) => {
    // TODO: dead-letter or retry logic
  },
};

export { UserLimiterDO } from './do/UserLimiterDO';
export { JobCoordinatorDO } from './do/JobCoordinatorDO';
