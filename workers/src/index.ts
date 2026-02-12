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
import type { Env, AuthUser } from './_shared/types';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// TODO: middleware, routes, error handlers

export default {
  fetch: app.fetch,
  queue: async (batch: MessageBatch, env: Env) => {
    // TODO: dead-letter or retry logic
  },
};

export { UserLimiterDO } from './do/UserLimiterDO';
export { JobCoordinatorDO } from './do/JobCoordinatorDO';
