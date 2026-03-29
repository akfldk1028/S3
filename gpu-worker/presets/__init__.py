"""S3 GPU Worker — 도메인별 concept → SAM3 프롬프트 매핑"""

from .interior import INTERIOR_CONCEPTS
from .seller import SELLER_CONCEPTS

_PRESET_MAP = {
    "interior": INTERIOR_CONCEPTS,
    "seller": SELLER_CONCEPTS,
}


def get_prompt(preset: str, concept_name: str) -> str:
    """concept 이름을 SAM3 텍스트 프롬프트로 변환.

    예: get_prompt("interior", "Floor") → "floor surface"
    매핑 없으면 원시 이름 반환 (fallback).
    """
    concepts = _PRESET_MAP.get(preset, {})
    entry = concepts.get(concept_name)
    if entry and "prompt" in entry:
        return entry["prompt"]
    return concept_name
