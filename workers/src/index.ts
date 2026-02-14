/**
 * S3 Workers — Entry Point
 *
 * Hono app + DO exports + Queue consumer
 *
 * TODO: Auto-Claude 구현
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
import authRoute from './auth/auth.route';
import presetsRoute from './presets/presets.route';
import rulesRoute from './rules/rules.route';
import jobsRoute from './jobs/jobs.route';
import userRoute from './user/user.route';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// Global middleware
app.use('*', cors());
app.use('*', logger());
app.use('*', authMiddleware);

// Route mounts
app.route('/api/auth', authRoute);
app.route('/api/presets', presetsRoute);
app.route('/api/rules', rulesRoute);
app.route('/api/jobs', jobsRoute);
app.route('/api/user', userRoute);

// Health check
app.get('/health', (c) => {
  return c.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 404 handler
app.notFound((c) => {
  return c.json(
    {
      success: false,
      error: {
        code: 'NOT_FOUND',
        message: 'Route not found',
      },
    },
    404
  );
});

// Error handler
app.onError((err, c) => {
  console.error('Unhandled error:', err);
  return c.json(
    {
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: err.message || 'Internal server error',
      },
    },
    500
  );
});

export default {
  fetch: app.fetch,
  queue: async (batch: MessageBatch, env: Env) => {
    // TODO: dead-letter or retry logic
  },
};

export { UserLimiterDO } from './do/UserLimiterDO';
export { JobCoordinatorDO } from './do/JobCoordinatorDO';
