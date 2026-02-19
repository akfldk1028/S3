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
  queue: async (batch: MessageBatch, env: Env) => {
    // TODO: dead-letter or retry logic
  },
};

export { UserLimiterDO } from './do/UserLimiterDO';
export { JobCoordinatorDO } from './do/JobCoordinatorDO';
