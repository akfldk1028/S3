"""SAM3 model configuration."""

from dataclasses import dataclass


@dataclass
class SAM3Config:
    weights_path: str = "/app/weights/sam3.pt"
    device: str = "cuda"
    dtype: str = "float16"
    model_name: str = "SAM3"
    model_version: str = "1.0"
    parameters: int = 848_000_000
    weights_size_gb: float = 3.4
    max_image_size: int = 1024
    mask_threshold: float = 0.5

    @classmethod
    def from_settings(cls, settings) -> "SAM3Config":
        return cls(
            weights_path=settings.sam3_weights_path,
            device=settings.sam3_device,
        )
