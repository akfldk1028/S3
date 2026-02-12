"""Segmentation domain — FastAPI dependencies."""

from fastapi import HTTPException, Request, status

from src.config import settings


async def verify_api_key(request: Request) -> str:
    """X-API-Key 헤더 검증. Edge에서 보내는 API key."""
    api_key = request.headers.get("X-API-Key", "")
    if not settings.api_secret_key:
        return api_key  # 개발 모드: key 미설정 시 통과
    if api_key != settings.api_secret_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key",
        )
    return api_key


# TODO: SAM3 Predictor dependency
# async def get_predictor(request: Request) -> SAM3Predictor:
#     return request.app.state.predictor
