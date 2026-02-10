/**
 * R2 Storage service — Cloudflare R2 helper functions.
 *
 * Edge가 R2 업로드/다운로드를 직접 처리.
 */

import type { Env } from '../types';

/** R2에 파일 업로드 */
export async function uploadToR2(
  r2: R2Bucket,
  key: string,
  data: ReadableStream | ArrayBuffer,
  contentType: string,
): Promise<void> {
  await r2.put(key, data, {
    httpMetadata: { contentType },
  });
}

/** R2에서 파일 조회 */
export async function getFromR2(
  r2: R2Bucket,
  key: string,
): Promise<R2ObjectBody | null> {
  return r2.get(key);
}

/** R2 key 생성: {type}/{userId}/{id} */
export function generateR2Key(
  userId: string,
  type: 'uploads' | 'masks',
  id: string,
): string {
  return `${type}/${userId}/${id}`;
}

/** R2 public URL 생성 (custom domain 또는 R2 public access) */
export function getR2PublicUrl(env: Env, key: string): string {
  // TODO: 프로덕션에서는 custom domain 사용
  // return `https://r2.your-domain.com/${key}`;
  return `${env.SUPABASE_URL}/storage/v1/object/public/${key}`;
}
