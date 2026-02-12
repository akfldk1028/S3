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


CALLBACK_TIMEOUT = int(os.getenv("CALLBACK_TIMEOUT_SEC", "10"))


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
    # TODO: implement
    raise NotImplementedError
