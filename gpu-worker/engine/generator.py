"""
Generator — Gemini API Inpaint

SAM3 마스크 영역에 프롬프트 기반 AI 질감/패턴 생성.
google-genai SDK의 Imagen 3.0 edit_image API 사용.
"""

import io
import os
import logging

import numpy as np
from PIL import Image
from google import genai
from google.genai import types

logger = logging.getLogger(__name__)

IMAGEN_MODEL = os.getenv("IMAGEN_MODEL", "imagen-3.0-capability-001")


def _mask_to_image(mask: np.ndarray) -> Image.Image:
    if mask.dtype in [np.float32, np.float64]:
        mask_uint8 = (mask * 255).astype(np.uint8)
    elif mask.dtype == bool:
        mask_uint8 = (mask.astype(np.uint8) * 255)
    else:
        mask_uint8 = mask.astype(np.uint8)
    return Image.fromarray(mask_uint8, mode="L")


def _image_to_bytes(image: Image.Image, fmt: str = "PNG") -> bytes:
    buf = io.BytesIO()
    image.save(buf, format=fmt)
    return buf.getvalue()


def generate_inpaint(
    image: Image.Image,
    mask: np.ndarray,
    prompt: str,
    api_key: str,
) -> Image.Image:
    """
    Gemini API(Imagen)로 마스크 영역 inpaint.

    Args:
        image: 원본 PIL Image (RGB)
        mask: SAM3 마스크 (H x W), 흰색=편집 영역
        prompt: "화이트 대리석 질감" 등
        api_key: Gemini API key

    Returns:
        결과 PIL Image
    """
    logger.info(f"[Generator] inpaint prompt='{prompt}' mask_shape={mask.shape}")

    client = genai.Client(api_key=api_key)

    image_rgb = image.convert("RGB")
    image_bytes = _image_to_bytes(image_rgb, "JPEG")

    mask_image = _mask_to_image(mask)
    if mask_image.size != image_rgb.size:
        mask_image = mask_image.resize(image_rgb.size, Image.NEAREST)
    mask_bytes = _image_to_bytes(mask_image, "PNG")

    raw_ref = types.RawReferenceImage(
        reference_id=1,
        reference_image=types.Image(
            image_bytes=image_bytes,
            mime_type="image/jpeg",
        ),
    )

    mask_ref = types.MaskReferenceImage(
        reference_id=2,
        reference_image=types.Image(
            image_bytes=mask_bytes,
            mime_type="image/png",
        ),
        config=types.MaskReferenceConfig(
            mask_mode="MASK_MODE_USER_PROVIDED",
            mask_dilation=0.01,
        ),
    )

    response = client.models.edit_image(
        model=IMAGEN_MODEL,
        prompt=prompt,
        reference_images=[raw_ref, mask_ref],
        config=types.EditImageConfig(
            edit_mode="EDIT_MODE_INPAINT_INSERTION",
            number_of_images=1,
        ),
    )

    if not response.generated_images:
        raise RuntimeError(f"Gemini API returned no images for prompt: {prompt}")

    result_bytes = response.generated_images[0].image.image_bytes
    result_image = Image.open(io.BytesIO(result_bytes)).convert("RGB")

    logger.info(f"[Generator] inpaint done — result size={result_image.size}")
    return result_image
