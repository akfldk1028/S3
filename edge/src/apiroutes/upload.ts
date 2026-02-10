/**
 * Upload route — POST /api/v1/upload
 *
 * Full 구현: 이미지 → 검증 → R2 저장 → image_url 반환.
 * Edge가 R2 업로드를 직접 처리 (Backend 관여 없음).
 */

import { Hono } from 'hono';
import { authMiddleware, type AuthVariables } from '../middleware/auth';
import { uploadToR2, generateR2Key, getR2PublicUrl } from '../services/r2';
import { ok, error } from '../utils/response';
import { validateUploadFile } from '../utils/validation';
import type { Env } from '../types';

const app = new Hono<{ Bindings: Env; Variables: AuthVariables }>();

app.use('*', authMiddleware);

app.post('/', async (c) => {
  const user = c.get('user');

  // 1. Parse multipart form data
  const formData = await c.req.parseBody();
  const file = formData['file'];

  if (!(file instanceof File)) {
    return c.json(error('INVALID_REQUEST', 'File field is required (multipart/form-data)'), 400);
  }

  // 2. Validate file
  const validation = validateUploadFile(file);
  if (!validation.valid) {
    return c.json(error(validation.code, validation.message), validation.status);
  }

  // 3. Upload to R2
  const imageId = crypto.randomUUID();
  const key = generateR2Key(user.userId, 'uploads', imageId);

  await uploadToR2(c.env.R2, key, file.stream(), file.type);

  // 4. Return image URL
  const imageUrl = getR2PublicUrl(c.env, key);

  return c.json(
    ok({
      image_id: imageId,
      image_url: imageUrl,
      size_bytes: file.size,
      content_type: file.type,
    }),
    200,
  );
});

export default app;
