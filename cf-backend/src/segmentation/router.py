"""Segmentation domain — API endpoints.

POST /api/v1/predict        — 단일 추론
POST /api/v1/predict/batch  — 배치 추론
GET  /api/v1/model/info     — 모델 정보
"""

from fastapi import APIRouter, Depends

from src.segmentation.dependencies import verify_api_key
from src.segmentation.schemas import (
    BatchPredictRequest,
    BatchPredictResponse,
    ModelInfoResponse,
    PredictRequest,
    PredictResponse,
)

router = APIRouter(prefix="/api/v1", tags=["segmentation"])


@router.post("/predict", response_model=PredictResponse)
async def predict(
    request: PredictRequest,
    _: str = Depends(verify_api_key),
):
    """SAM3 단일 추론 — 이미지 + 텍스트 프롬프트 → 마스크 + 라벨.

    TODO:
    1. StorageService.download_image(request.image_url)
    2. SAM3Predictor.predict(image, request.text_prompt)
    3. StorageService.upload_mask(mask, request.task_id)
    4. 결과 반환
    """
    raise NotImplementedError("SAM3 predict not yet implemented")


@router.post("/predict/batch", response_model=BatchPredictResponse)
async def predict_batch(
    request: BatchPredictRequest,
    _: str = Depends(verify_api_key),
):
    """SAM3 배치 추론 — 이미지 + 복수 프롬프트 → 복수 마스크.

    TODO: SAM3Predictor.predict_batch()
    """
    raise NotImplementedError("SAM3 batch predict not yet implemented")


@router.get("/model/info", response_model=ModelInfoResponse)
async def model_info(
    _: str = Depends(verify_api_key),
):
    """로드된 SAM3 모델 정보 조회."""
    return ModelInfoResponse(
        model_name="SAM3",
        model_version="1.0",
        parameters=848_000_000,
        weights_size_gb=3.4,
        device="cpu",  # TODO: 실제 디바이스
        dtype="float16",
    )
