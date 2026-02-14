/**
 * R2 presigned URL 생성 — AWS SDK 사용
 *
 * R2 파일 키 규칙: workflow.md 섹션 5.5
 *   inputs/{userId}/{jobId}/{idx}.jpg
 *   outputs/{userId}/{jobId}/{idx}_result.png
 *   masks/{userId}/{jobId}/{idx}_{concept}.png
 *   previews/{userId}/{jobId}/{idx}_thumb.jpg
 */

import { S3Client, GetObjectCommand, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import type { Env } from './types';

export async function generatePresignedUrl(
  env: Env,
  bucket: string,
  key: string,
  method: 'GET' | 'PUT',
  expiresIn: number,
): Promise<string> {
  // S3Client 초기화 (R2 엔드포인트 사용)
  const s3Client = new S3Client({
    region: 'auto',
    endpoint: `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: env.R2_ACCESS_KEY_ID,
      secretAccessKey: env.R2_SECRET_ACCESS_KEY,
    },
  });

  // Command 생성 (GET/PUT에 따라)
  const command = method === 'PUT'
    ? new PutObjectCommand({ Bucket: bucket, Key: key })
    : new GetObjectCommand({ Bucket: bucket, Key: key });

  // Presigned URL 생성
  const presignedUrl = await getSignedUrl(s3Client, command, { expiresIn });

  return presignedUrl;
}
