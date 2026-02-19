/**
 * Jobs Service — R2 presigned URL 생성, Queue push
 */

import type { Env, GpuQueueMessage, JobItemState } from '../_shared/types';
import { generatePresignedUrl } from '../_shared/r2';

export async function generateUploadUrls(
  env: Env,
  userId: string,
  jobId: string,
  itemCount: number,
): Promise<Array<{ idx: number; url: string; key: string }>> {
  const urls = [];
  for (let idx = 0; idx < itemCount; idx++) {
    const key = `inputs/${userId}/${jobId}/${idx}.jpg`;
    const url = await generatePresignedUrl(env, env.R2_BUCKET_NAME, key, 'PUT', 3600);
    urls.push({ idx, url, key });
  }
  return urls;
}

export async function generateDownloadUrls(
  env: Env,
  userId: string,
  jobId: string,
  items: JobItemState[],
): Promise<Array<{ idx: number; output_url: string | null; preview_url: string | null }>> {
  const results = [];
  for (const item of items) {
    let output_url: string | null = null;
    let preview_url: string | null = null;
    if (item.outputKey) {
      output_url = await generatePresignedUrl(env, env.R2_BUCKET_NAME, item.outputKey, 'GET', 3600);
    }
    if (item.previewKey) {
      preview_url = await generatePresignedUrl(env, env.R2_BUCKET_NAME, item.previewKey, 'GET', 3600);
    }
    results.push({ idx: item.idx, output_url, preview_url });
  }
  return results;
}

export async function pushToQueue(
  queue: Queue<GpuQueueMessage>,
  message: GpuQueueMessage,
  deduplicationId?: string,
): Promise<void> {
  await queue.send(message, {
    contentType: 'json',
    ...(deduplicationId ? { deduplicationId } : {}),
  });
}
