"""
Segmenter — SAM3 Wrapper

SAM3 (Segment Anything Model 3) wrapper for text-based image segmentation.
- load_model() → SAM3 model
- segment(image, concept_text) → masks + metadata
- SAM3: 848M params, 3.4GB, ~30ms/image (H200)
- 최소: RTX 4090 (24GB), CUDA 12.6+, Python 3.12+, PyTorch 2.7+
"""

import os
import torch
import numpy as np
from PIL import Image
from typing import Optional

# SAM3 imports (from facebook/sam3 repo, not transformers)
from sam3 import build_sam3_image_model
from sam3.model.sam3_image_processor import Sam3Processor


class SAM3Segmenter:
    def __init__(
        self,
        checkpoint_path: Optional[str] = None,
        bpe_path: Optional[str] = None,
        confidence_threshold: float = 0.5,
    ):
        """
        Initialize SAM3 segmenter.

        Args:
            checkpoint_path: Path to SAM3 checkpoint file (sam3.pt)
                            Default: /models/sam3.pt or MODEL_CHECKPOINT env
            bpe_path: Path to BPE vocab file (bpe_simple_vocab_16e6.txt.gz)
                     Default: /app/sam3/sam3/assets/bpe_simple_vocab_16e6.txt.gz or BPE_PATH env
            confidence_threshold: Minimum confidence score for masks (default: 0.5)

        Raises:
            FileNotFoundError: If checkpoint or bpe file not found
            RuntimeError: If model loading fails
        """
        # Resolve paths from env or defaults
        self.checkpoint_path = checkpoint_path or os.getenv(
            "MODEL_CHECKPOINT", "/models/sam3.pt"
        )
        self.bpe_path = bpe_path or os.getenv(
            "BPE_PATH", "/app/sam3/sam3/assets/bpe_simple_vocab_16e6.txt.gz"
        )
        self.confidence_threshold = confidence_threshold

        # Validate files exist
        if not os.path.exists(self.checkpoint_path):
            raise FileNotFoundError(
                f"SAM3 checkpoint not found: {self.checkpoint_path}. "
                f"Set MODEL_CHECKPOINT env or mount volume to /models"
            )
        if not os.path.exists(self.bpe_path):
            raise FileNotFoundError(
                f"BPE vocab file not found: {self.bpe_path}. "
                f"Set BPE_PATH env or ensure SAM3 repo is cloned"
            )

        # Enable TF32 for faster computation on Ampere+ GPUs
        torch.backends.cuda.matmul.allow_tf32 = True
        torch.backends.cudnn.allow_tf32 = True

        # Load model
        try:
            print(f"Loading SAM3 model from {self.checkpoint_path}...")
            self.model = build_sam3_image_model(
                bpe_path=self.bpe_path,
                checkpoint_path=self.checkpoint_path,
            )
            print("SAM3 model loaded successfully!")

            # Create processor
            self.processor = Sam3Processor(
                self.model,
                confidence_threshold=self.confidence_threshold,
            )

        except Exception as e:
            raise RuntimeError(f"Failed to load SAM3 model: {str(e)}")

    def segment(self, image: Image.Image, concept_text: str) -> tuple[list[np.ndarray], dict]:
        """
        Segment image by concept text, return instance masks + metadata.

        Args:
            image: PIL Image to segment
            concept_text: Text description of concept to segment (e.g., "wall", "door", "window")

        Returns:
            tuple[list[np.ndarray], dict]:
                - List of instance masks (each mask is H x W boolean array)
                - Metadata dict with concept, instance_count, and inference info

        Example:
            >>> segmenter = SAM3Segmenter()
            >>> masks, metadata = segmenter.segment(image, "window")
            >>> print(metadata)
            {'concept': 'window', 'instance_count': 3, 'image_size': (1920, 1080)}
        """
        # Set image
        state = self.processor.set_image(image)

        # Set text prompt and run inference
        state = self.processor.set_text_prompt(state=state, prompt=concept_text)

        # Extract masks from state
        masks_list = []
        if "masks" in state and state["masks"] is not None:
            # Convert masks to numpy arrays
            raw_masks = state["masks"]
            if isinstance(raw_masks, torch.Tensor):
                raw_masks = raw_masks.cpu().numpy()

            # Handle different mask shapes: [batch, num_masks, H, W] or [num_masks, H, W] or [H, W]
            if len(raw_masks.shape) == 4:
                # [batch, num_masks, H, W] → extract each mask
                for b in range(raw_masks.shape[0]):
                    for m in range(raw_masks.shape[1]):
                        masks_list.append(raw_masks[b, m])
            elif len(raw_masks.shape) == 3:
                masks_list = [raw_masks[i] for i in range(raw_masks.shape[0])]
            elif len(raw_masks.shape) == 2:
                masks_list = [raw_masks]

        # Build metadata
        metadata = {
            "concept": concept_text,
            "instance_count": len(masks_list),
            "image_size": image.size,
            "confidence_threshold": self.confidence_threshold,
        }

        # Add scores if available
        if "scores" in state and state["scores"] is not None:
            scores = state["scores"]
            if isinstance(scores, torch.Tensor):
                scores = scores.cpu().numpy().tolist()
            metadata["scores"] = scores

        return masks_list, metadata

    def segment_multiple(
        self, image: Image.Image, concepts: list[str]
    ) -> dict[str, tuple[list[np.ndarray], dict]]:
        """
        Segment image for multiple concepts.

        Args:
            image: PIL Image to segment
            concepts: List of concept texts (e.g., ["wall", "door", "window"])

        Returns:
            dict mapping concept -> (masks, metadata)

        Example:
            >>> results = segmenter.segment_multiple(image, ["wall", "door"])
            >>> wall_masks, wall_meta = results["wall"]
        """
        results = {}
        for concept in concepts:
            masks, metadata = self.segment(image, concept)
            results[concept] = (masks, metadata)
        return results
