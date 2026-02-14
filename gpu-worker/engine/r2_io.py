"""
R2 I/O — S3-compatible R2 업/다운로드

TODO: Auto-Claude 구현
- R2 endpoint + access key + secret key 환경변수
- download(key: str) → bytes (이미지 다운로드)
- upload(key: str, data: bytes, content_type: str) → None
- boto3 S3 호환 API 또는 httpx 직접 호출

R2 파일 키 규칙 (workflow.md 섹션 5.5):
  inputs/{userId}/{jobId}/{idx}.jpg
  outputs/{userId}/{jobId}/{idx}_result.png
  previews/{userId}/{jobId}/{idx}_thumb.jpg
"""

import os
import boto3
from botocore.exceptions import ClientError


class R2Client:
    def __init__(self):
        # Construct R2 endpoint URL from account ID
        account_id = os.getenv("R2_ACCOUNT_ID", "")
        self.endpoint = f"https://{account_id}.r2.cloudflarestorage.com" if account_id else ""
        self.access_key = os.getenv("R2_ACCESS_KEY_ID", "")
        self.secret_key = os.getenv("R2_SECRET_ACCESS_KEY", "")
        self.bucket = os.getenv("R2_BUCKET_NAME", "s3-storage")

        # Initialize boto3 S3 client with R2 endpoint
        self.s3_client = boto3.client(
            's3',
            endpoint_url=self.endpoint,
            aws_access_key_id=self.access_key,
            aws_secret_access_key=self.secret_key,
            region_name='auto',  # R2 uses 'auto' as region
        )

    def download(self, key: str) -> bytes:
        """Download file from R2 and return as bytes."""
        try:
            response = self.s3_client.get_object(Bucket=self.bucket, Key=key)
            return response['Body'].read()
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            raise RuntimeError(f"Failed to download {key} from R2: {error_code} - {str(e)}")

    def upload(self, key: str, data: bytes, content_type: str = "image/png") -> None:
        """Upload file to R2 with specified content type."""
        try:
            self.s3_client.put_object(
                Bucket=self.bucket,
                Key=key,
                Body=data,
                ContentType=content_type
            )
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            raise RuntimeError(f"Failed to upload {key} to R2: {error_code} - {str(e)}")
