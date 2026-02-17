/**
 * S3 Workers — Entry Point
 *
 * Hono app + DO exports + Queue consumer
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import type { Env, AuthUser } from './_shared/types';

// ─── CORS Allowlist ──────────────────────────────────────
// 명시적 origin 허용 목록 — 와일드카드(*) 사용 금지
// credentials: true (JWT Authorization 헤더) 사용 시 * 불가 (브라우저 보안 요구사항)
const ALLOWED_ORIGINS = [
  'http://localhost:8080',                          // Flutter web dev
  'http://localhost:3000',                          // 로컬 Workers dev (self)
  'https://s3-workers.clickaround8.workers.dev',   // CF Workers prod
  // 프로덕션 Flutter Web 도메인이 생기면 여기 추가
];

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// ─── Global Middleware ───────────────────────────────────
app.use('*', cors({
  origin: ALLOWED_ORIGINS,
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));

// TODO: logger middleware
// TODO: auth middleware

// TODO: Route mounts — auth, presets, rules, jobs, user

// TODO: Health check: GET /health

// TODO: 404 + error handler

export default {
  fetch: app.fetch,
  queue: async (batch: MessageBatch, env: Env) => {
    // TODO: dead-letter or retry logic
  },
};

export { UserLimiterDO } from './do/UserLimiterDO';
export { JobCoordinatorDO } from './do/JobCoordinatorDO';
