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

import os
import torch
from transformers import Sam3Processor, Sam3Model


class SAM3Segmenter:
    def __init__(self, model_path: str = "/models/sam3"):
        """
        Initialize SAM3 segmenter with model loaded from HuggingFace Hub.

        Args:
            model_path: Cache directory for model weights (default: /models/sam3)
                       Can be overridden by MODEL_CACHE_DIR env variable.

        Raises:
            ValueError: If HF_TOKEN is not set or SAM3 access not approved
            RuntimeError: If model loading fails
        """
        # Use MODEL_CACHE_DIR env variable if set, otherwise use model_path parameter
        cache_dir = os.getenv("MODEL_CACHE_DIR", model_path)

        # Auto-detect device (CUDA if available, fallback to CPU)
        self.device = "cuda" if torch.cuda.is_available() else "cpu"

        # Get HuggingFace token (REQUIRED - SAM3 is a gated model)
        hf_token = os.getenv("HF_TOKEN")
        if not hf_token:
            raise ValueError(
                "HF_TOKEN environment variable is required. "
                "SAM3 is a gated model - get token from https://huggingface.co/settings/tokens "
                "and request access at https://huggingface.co/facebook/sam3"
            )

        try:
            # Load SAM3 processor from HuggingFace Hub
            self.processor = Sam3Processor.from_pretrained(
                "facebook/sam3",
                token=hf_token,
                cache_dir=cache_dir,
            )

            # Load SAM3 model from HuggingFace Hub and move to device
            self.model = Sam3Model.from_pretrained(
                "facebook/sam3",
                token=hf_token,
                cache_dir=cache_dir,
            ).to(self.device)

        except Exception as e:
            raise RuntimeError(
                f"Failed to load SAM3 model from HuggingFace Hub. "
                f"Ensure HF_TOKEN is valid and you have access to facebook/sam3. "
                f"Error: {str(e)}"
            )

    def segment(self, image, concept_text: str):
        """
        Segment image by concept text, return instance masks + metadata.

        Args:
            image: PIL Image to segment
            concept_text: Text description of concept to segment (e.g., "wall", "door")

        Returns:
            tuple[list[np.ndarray], dict]:
                - List of instance masks (each mask is H x W array)
                - Metadata dict with concept, instance_count, and scores

        Example:
            >>> segmenter = SAM3Segmenter()
            >>> masks, metadata = segmenter.segment(image, "window")
            >>> print(metadata)
            {'concept': 'window', 'instance_count': 3, 'scores': [0.95, 0.89, 0.87]}
        """
        import numpy as np

        # Prepare inputs using SAM3 processor
        inputs = self.processor(
            images=image,
            text=concept_text,
            return_tensors="pt",
        ).to(self.device)

        # Run inference (no gradient computation needed)
        with torch.no_grad():
            outputs = self.model(**inputs)

        # Extract instance masks (SAM3 returns per-instance segmentation)
        # Shape: [num_instances, H, W]
        masks = outputs.pred_masks.cpu().numpy()

        # Build metadata dict
        metadata = {
            "concept": concept_text,
            "instance_count": len(masks),
            "scores": outputs.iou_scores.cpu().numpy().tolist(),
        }

        return masks, metadata
