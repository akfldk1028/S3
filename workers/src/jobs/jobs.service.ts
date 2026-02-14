/**
 * Jobs Service — R2 presigned URL 생성, Queue push
 *
 * TODO: Auto-Claude 구현
 * - generateUploadUrls(userId, jobId, itemCount) → presigned PUT URLs
 * - generateDownloadUrls(userId, jobId, items) → presigned GET URLs
 * - pushToQueue(queue, message: GpuQueueMessage) → void
 */

import type { GpuQueueMessage, Env } from '../_shared/types';
import { generatePresignedUrl } from '../_shared/r2';

export async function generateUploadUrls(
  env: Env,
  userId: string,
  jobId: string,
  itemCount: number,
): Promise<Array<{ idx: number; url: string; key: string }>> {
  const urls: Array<{ idx: number; url: string; key: string }> = [];

  for (let idx = 0; idx < itemCount; idx++) {
    // R2 키 규칙: inputs/{userId}/{jobId}/{idx}.jpg
    const key = `inputs/${userId}/${jobId}/${idx}.jpg`;

    // Presigned PUT URL 생성 (1시간 유효)
    const url = await generatePresignedUrl(
      env,
      env.R2_BUCKET_NAME,
      key,
      'PUT',
      3600, // 1 hour expiration
    );

    urls.push({ idx, url, key });
  }

  return urls;
}

export async function pushToQueue(
  queue: Queue<GpuQueueMessage>,
  message: GpuQueueMessage,
): Promise<void> {
  // TODO: implement
  throw new Error('Not implemented');
}
