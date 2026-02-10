/**
 * Results apiroutes — Full 구현
 *
 * GET /api/v1/tasks/:id   — 작업 상태 조회 (Supabase)
 * GET /api/v1/results      — 유저별 결과 목록 (pagination, Supabase)
 * GET /api/v1/results/:id  — 결과 상세 조회 (Supabase)
 */

import { Hono } from 'hono';
import { authMiddleware, type AuthVariables } from '../middleware/auth';
import {
  getSegmentationResult,
  listSegmentationResults,
} from '../services/supabase';
import { ok, error } from '../utils/response';
import type { Env } from '../types';

const app = new Hono<{ Bindings: Env; Variables: AuthVariables }>();

app.use('*', authMiddleware);

/** GET /api/v1/tasks/:id — 작업 상태 조회 */
app.get('/tasks/:id', async (c) => {
  const taskId = c.req.param('id');
  const user = c.get('user');

  const result = await getSegmentationResult(c.env, taskId, user.jwt);

  if (!result) {
    return c.json(error('NOT_FOUND', 'Task not found'), 404);
  }

  // RLS ensures user can only see own data, but double-check
  if (result.user_id !== user.userId) {
    return c.json(error('NOT_FOUND', 'Task not found'), 404);
  }

  return c.json(
    ok({
      task_id: result.id,
      status: result.status,
      result_id: result.status === 'done' ? result.id : undefined,
      error_message: result.status === 'error' ? (result.metadata as Record<string, unknown>)?.error_message : undefined,
      created_at: result.created_at,
      updated_at: result.updated_at,
    }),
  );
});

/** GET /api/v1/results — 결과 목록 조회 (paginated) */
app.get('/results', async (c) => {
  const user = c.get('user');
  const page = Math.max(1, Number(c.req.query('page') ?? '1'));
  const limit = Math.min(Math.max(1, Number(c.req.query('limit') ?? '20')), 100);
  const projectId = c.req.query('project_id');

  const { results, total } = await listSegmentationResults(c.env, user.jwt, {
    userId: user.userId,
    projectId: projectId || undefined,
    page,
    limit,
  });

  return c.json(
    ok({
      results: results.map((r) => ({
        id: r.id,
        source_image_url: r.source_image_url,
        mask_image_url: r.mask_image_url,
        text_prompt: r.text_prompt,
        status: r.status,
        created_at: r.created_at,
      })),
      total,
      page,
      limit,
    }),
  );
});

/** GET /api/v1/results/:id — 결과 상세 조회 */
app.get('/results/:id', async (c) => {
  const resultId = c.req.param('id');
  const user = c.get('user');

  const result = await getSegmentationResult(c.env, resultId, user.jwt);

  if (!result) {
    return c.json(error('NOT_FOUND', 'Result not found'), 404);
  }

  if (result.user_id !== user.userId) {
    return c.json(error('NOT_FOUND', 'Result not found'), 404);
  }

  return c.json(
    ok({
      id: result.id,
      project_id: result.project_id,
      source_image_url: result.source_image_url,
      mask_image_url: result.mask_image_url,
      text_prompt: result.text_prompt,
      labels: result.labels ?? [],
      metadata: result.metadata ?? {},
      status: result.status,
      created_at: result.created_at,
      updated_at: result.updated_at,
    }),
  );
});

export default app;
