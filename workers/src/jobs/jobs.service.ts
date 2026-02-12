/**
 * Jobs Service — R2 presigned URL 생성, Queue push
 *
 * TODO: Auto-Claude 구현
 * - generateUploadUrls(userId, jobId, itemCount) → presigned PUT URLs
 * - generateDownloadUrls(userId, jobId, items) → presigned GET URLs
 * - pushToQueue(queue, message: GpuQueueMessage) → void
 */

import type { GpuQueueMessage } from '../_shared/types';

export async function generateUploadUrls(
  userId: string,
  jobId: string,
  itemCount: number,
): Promise<Array<{ idx: number; url: string; key: string }>> {
  // TODO: implement
  throw new Error('Not implemented');
}

export async function pushToQueue(
  queue: Queue<GpuQueueMessage>,
  message: GpuQueueMessage,
): Promise<void> {
  // TODO: implement
  throw new Error('Not implemented');
}
