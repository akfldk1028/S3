"""
Segmenter — SAM3 Wrapper

TODO: Auto-Claude 구현
- load_model(model_path) → SAM3 model
- segment(image, concepts: list[str], protect: list[str]) → dict of masks
  - concept text → 해당 개념 마스크 생성
  - 동일 개념 여러 인스턴스 → 인스턴스 분리
  - 보호 대상 → 보호 마스크 (룰 적용 시 제외)
- SAM3: 848M params, 3.4GB, ~30ms/image (H200)
- 최소: RTX 4090 (16GB), CUDA 12.1+, Python 3.12+, PyTorch 2.7+
"""


class SAM3Segmenter:
    def __init__(self, model_path: str = "/models/sam3"):
        # TODO: load SAM3 model
        pass

    def segment(self, image, concepts: list[str], protect: list[str]) -> dict:
        """Return concept masks and protect masks."""
        # TODO: implement
        raise NotImplementedError
