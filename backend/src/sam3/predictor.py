"""SAM3 Predictor — model loading and inference.

TODO: SAM3 라이브러리 import 및 실제 추론 구현.
"""

from dataclasses import dataclass

import numpy as np

from src.sam3.config import SAM3Config


@dataclass
class PredictResult:
    """Single prediction result."""
    mask: np.ndarray       # H x W binary mask
    labels: list[str]
    confidence: float
    inference_time_ms: float


class SAM3Predictor:
    """SAM3 모델 래퍼 — 로드, 추론, 배치 추론."""

    def __init__(self, config: SAM3Config):
        self.config = config
        self.model = None
        self._loaded = False

    @property
    def is_loaded(self) -> bool:
        return self._loaded

    async def load(self) -> None:
        """모델 가중치 로드. 앱 시작(lifespan) 시 1회 호출.

        TODO: sam3 라이브러리로 모델 로드 + GPU 배치
        """
        pass

    async def predict(self, image: np.ndarray, text_prompt: str) -> PredictResult:
        """단일 이미지 + 텍스트 프롬프트 → 마스크 + 라벨.

        TODO: 이미지 전처리 → SAM3 추론 → 후처리
        """
        raise NotImplementedError

    async def predict_batch(self, image: np.ndarray, prompts: list[str]) -> list[PredictResult]:
        """단일 이미지 + 복수 프롬프트 → 복수 마스크.

        TODO: 이미지 인코딩 1회 → 프롬프트별 디코딩 N회
        """
        raise NotImplementedError

    async def unload(self) -> None:
        """모델 언로드 + GPU 메모리 해제."""
        self.model = None
        self._loaded = False
