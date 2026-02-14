"""
Callback — Workers 콜백 POST

TODO: Auto-Claude 구현
- report(callback_url, idx, status, output_key?, preview_key?, error?, idempotency_key)
- POST to callback_url with JSON body
- GPU_CALLBACK_SECRET 헤더 포함
- timeout: CALLBACK_TIMEOUT_SEC (기본 10초)
- 실패 시 retry 1회
"""

import os
import hashlib
import time
import re
import httpx
from typing import Optional


CALLBACK_TIMEOUT = int(os.getenv("CALLBACK_TIMEOUT_SEC", "10"))


def _extract_job_id(callback_url: str) -> str:
    """Extract job_id from callback URL pattern /jobs/{jobId}/callback."""
    match = re.search(r'/jobs/([^/]+)/callback', callback_url)
    if not match:
        raise ValueError(f"Cannot extract job_id from callback_url: {callback_url}")
    return match.group(1)


def _generate_idempotency_key(job_id: str, idx: int, attempt: int = 1) -> str:
    """Generate deterministic idempotency key for callback deduplication."""
    payload = f"{job_id}:{idx}:{attempt}:{int(time.time() // 60)}"  # 1-min window
    return hashlib.sha256(payload.encode()).hexdigest()[:16]


def report(
    callback_url: str,
    idx: int,
    status: str,
    output_key: str | None = None,
    preview_key: str | None = None,
    error: str | None = None,
    idempotency_key: str = "",
) -> bool:
    """POST callback to Workers. Returns True on success."""
    gpu_callback_secret = os.getenv("GPU_CALLBACK_SECRET", "")

    # Generate idempotency key if not provided
    if not idempotency_key:
        job_id = _extract_job_id(callback_url)
        idempotency_key = _generate_idempotency_key(job_id, idx, attempt=1)

    # Prepare headers
    headers = {
        "X-GPU-Callback-Secret": gpu_callback_secret,
        "X-Idempotency-Key": idempotency_key,
        "Content-Type": "application/json",
    }

    # Prepare payload
    payload = {
        "idx": idx,
        "status": status,
    }

    # Add optional fields if provided
    if output_key is not None:
        payload["output_key"] = output_key
    if preview_key is not None:
        payload["preview_key"] = preview_key
    if error is not None:
        payload["error"] = error

    # Send POST request with retry logic
    max_retries = 1
    for attempt in range(max_retries + 1):
        try:
            with httpx.Client(timeout=CALLBACK_TIMEOUT) as client:
                response = client.post(callback_url, json=payload, headers=headers)
                response.raise_for_status()
                return True
        except httpx.HTTPError as e:
            if attempt < max_retries:
                # Retry once on failure
                time.sleep(1)
                continue
            else:
                # Log warning but don't raise - don't block pipeline on callback failure
                print(f"WARNING: Callback failed after {max_retries + 1} attempts: {str(e)}")
                return False

    return False
