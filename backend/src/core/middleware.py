"""Application middleware — CORS (Edge Worker 도메인만 허용)."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Edge Worker 도메인만 허용 (프로덕션)
ALLOWED_ORIGINS = [
    "https://s3-api.*.workers.dev",  # Edge Worker
]


def setup_middleware(app: FastAPI) -> None:
    """Register all middleware."""
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # TODO: 프로덕션에서는 ALLOWED_ORIGINS로 제한
        allow_credentials=True,
        allow_methods=["GET", "POST"],
        allow_headers=["Content-Type", "X-API-Key"],
    )
