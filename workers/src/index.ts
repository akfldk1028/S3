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
import authRoutes from './auth/auth.route';
import presetsRoutes from './presets/presets.route';
import rulesRoutes from './rules/rules.route';
import jobsRoutes from './jobs/jobs.route';
import userRoutes from './user/user.route';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// Global middleware
app.use('*', cors());
app.use('*', logger());
app.use('*', authMiddleware);

// Health check (public, skipped by auth middleware)
app.get('/health', (c) => {
  return c.json(ok({ status: 'healthy', timestamp: new Date().toISOString() }));
});

// Mount route handlers
app.route('/auth', authRoutes);
app.route('/presets', presetsRoutes);
app.route('/rules', rulesRoutes);
app.route('/jobs', jobsRoutes);
app.route('/user', userRoutes);

// 404 handler
app.notFound((c) => {
  return c.json(error(ERR.NOT_FOUND, 'Route not found'), 404);
});

// Global error handler
app.onError((err, c) => {
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
