/**
 * S3 Edge — Full API on Cloudflare Workers (Hono)
 *
 * Flutter 앱의 유일한 API 서버.
 * Auth, CRUD, R2 저장, Supabase 연동, Backend 추론 프록시 모두 담당.
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';

import type { Env } from './types';
import type { AuthVariables } from './middleware/auth';
import { ok, error } from './utils/response';
import upload from './apiroutes/upload';
import segment from './apiroutes/segment';
import results from './apiroutes/results';

const app = new Hono<{ Bindings: Env; Variables: AuthVariables }>();

// Global middleware
app.use('*', logger());
app.use('*', cors()); // TODO: 프로덕션에서는 origin 제한

// Health check (no auth)
app.get('/health', (c) =>
  c.json(ok({ status: 'ok', timestamp: new Date().toISOString() })),
);

// API v1 apiroutes (auth required)
app.route('/api/v1/upload', upload);
app.route('/api/v1/segment', segment);
app.route('/api/v1', results);

// 404 fallback
app.notFound((c) => c.json(error('NOT_FOUND', `${c.req.method} ${c.req.path} not found`), 404));

// Global error handler
app.onError((err, c) => {
  console.error('Unhandled error:', err);
  return c.json(error('INTERNAL_ERROR', 'Internal server error'), 500);
});

export default app;
