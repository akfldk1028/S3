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


class R2Client:
    def __init__(self):
        self.endpoint = os.getenv("STORAGE_S3_ENDPOINT", "")
        self.access_key = os.getenv("STORAGE_ACCESS_KEY", "")
        self.secret_key = os.getenv("STORAGE_SECRET_KEY", "")
        self.bucket = os.getenv("STORAGE_BUCKET", "s3-images")

    def download(self, key: str) -> bytes:
        # TODO: implement
        raise NotImplementedError

    def upload(self, key: str, data: bytes, content_type: str = "image/png") -> None:
        # TODO: implement
        raise NotImplementedError
