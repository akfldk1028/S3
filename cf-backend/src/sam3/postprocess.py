"""Mask post-processing utilities.

TODO: SAM3 추론 결과 마스크의 후처리.
"""

import numpy as np


def threshold_mask(mask: np.ndarray, threshold: float = 0.5) -> np.ndarray:
    """확률 마스크 → 이진 마스크."""
    return ((mask > threshold) * 255).astype(np.uint8)


def resize_mask(mask: np.ndarray, target_size: tuple[int, int]) -> np.ndarray:
    """마스크를 원본 이미지 크기로 리사이즈. TODO: cv2/PIL"""
    raise NotImplementedError


def extract_labels(raw_output: dict) -> list[str]:
    """SAM3 raw output에서 라벨 추출. TODO: SAM3 출력 형식에 맞게"""
    raise NotImplementedError
