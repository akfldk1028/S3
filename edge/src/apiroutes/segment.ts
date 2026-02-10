/**
 * Segment route — POST /api/v1/segment
 *
 * Full 구현:
 * 1. 요청 검증 (image_url, text_prompt)
 * 2. Supabase: 유저 크레딧 확인
 * 3. Supabase: segmentation_results INSERT (status: pending)
 * 4. Backend 프록시: POST /api/v1/predict (비동기, waitUntil)
 * 5. 즉시 응답: { task_id, status: 'pending' }
 */

import { Hono } from 'hono';
import { authMiddleware, type AuthVariables } from '../middleware/auth';
import { proxyToBackend } from '../services/vastai';
import { getUserCredits, createSegmentationResult } from '../services/supabase';
import { ok, error } from '../utils/response';
import { validateSegmentRequest } from '../utils/validation';
import type { Env } from '../types';

const app = new Hono<{ Bindings: Env; Variables: AuthVariables }>();

app.use('*', authMiddleware);

app.post('/', async (c) => {
  const user = c.get('user');

  // 1. Parse & validate request body
  const body = await c.req.json<{
    image_url?: string;
    text_prompt?: string;
    project_id?: string;
  }>();

  const validation = validateSegmentRequest(body);
  if (!validation.valid) {
    return c.json(error(validation.code, validation.message), validation.status);
  }

  // 2. Check user credits
  const userInfo = await getUserCredits(c.env, user.userId, user.jwt);
  if (!userInfo || userInfo.credits <= 0) {
    return c.json(error('INSUFFICIENT_CREDITS', 'Not enough credits'), 402);
  }

  // 3. Create task in Supabase (status: pending)
  const taskId = crypto.randomUUID();
  const created = await createSegmentationResult(c.env, user.jwt, {
    id: taskId,
    user_id: user.userId,
    project_id: body.project_id,
    source_image_url: body.image_url!,
    text_prompt: body.text_prompt!,
  });

  if (!created) {
    return c.json(error('INTERNAL_ERROR', 'Failed to create segmentation task'), 500);
  }

  // 4. Proxy to Backend (async — don't wait for inference)
  c.executionCtx.waitUntil(
    proxyToBackend(c.env, '/api/v1/predict', {
      image_url: body.image_url,
      text_prompt: body.text_prompt,
      user_id: user.userId,
      task_id: taskId,
    }),
  );

  // 5. Return immediately
  return c.json(ok({ task_id: taskId, status: 'pending' as const }), 202);
});

export default app;
