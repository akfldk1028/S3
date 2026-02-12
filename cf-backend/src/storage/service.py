"""R2 storage service — S3-compatible image/mask upload and download.

TODO: boto3 클라이언트로 R2 연동.
"""

import numpy as np


class StorageService:
    """Cloudflare R2 스토리지 (S3 호환)."""

    def __init__(self, endpoint: str, access_key: str, secret_key: str, bucket: str):
        self.endpoint = endpoint
        self.bucket = bucket
        # TODO: boto3.client("s3", endpoint_url=endpoint, ...)

    async def download_image(self, image_url: str) -> np.ndarray:
        """R2에서 이미지 다운로드 → numpy array. TODO"""
        raise NotImplementedError

    async def upload_mask(self, mask: np.ndarray, task_id: str) -> str:
        """마스크를 R2에 PNG로 업로드 → URL 반환. TODO"""
        raise NotImplementedError

    async def upload_image(self, image_bytes: bytes, filename: str, content_type: str) -> str:
        """원본 이미지 R2 업로드 → URL 반환. TODO"""
        raise NotImplementedError
