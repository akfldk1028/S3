/**
 * R2 presigned URL 생성 — aws4fetch 사용
 *
 * TODO: Auto-Claude 구현
 * - generatePresignedUrl(bucket, key, method, expiresIn) → URL string
 * - AwsClient from aws4fetch
 * - R2 파일 키 규칙: workflow.md 섹션 5.5
 *   inputs/{userId}/{jobId}/{idx}.jpg
 *   outputs/{userId}/{jobId}/{idx}_result.png
 *   masks/{userId}/{jobId}/{idx}_{concept}.png
 *   previews/{userId}/{jobId}/{idx}_thumb.jpg
 */

export async function generatePresignedUrl(
  bucket: string,
  key: string,
  method: 'GET' | 'PUT',
  expiresIn: number,
): Promise<string> {
  // TODO: implement with aws4fetch AwsClient
  throw new Error('Not implemented');
}
