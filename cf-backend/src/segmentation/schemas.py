"""Segmentation domain — Pydantic schemas.

Matches: docs/contracts/api-contracts.md (Backend Internal API)
"""

from pydantic import BaseModel


class PredictRequest(BaseModel):
    image_url: str
    text_prompt: str
    user_id: str
    task_id: str


class PredictResponse(BaseModel):
    task_id: str
    mask_url: str
    labels: list[str]
    inference_time_ms: float
    confidence: float


class BatchPredictRequest(BaseModel):
    image_url: str
    prompts: list[str]
    user_id: str
    task_id: str


class BatchPredictResponse(BaseModel):
    task_id: str
    results: list[PredictResponse]
    total_inference_time_ms: float


class ModelInfoResponse(BaseModel):
    model_name: str
    model_version: str
    parameters: int
    weights_size_gb: float
    device: str
    dtype: str
