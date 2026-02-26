"""
Runpod Serverless Handler for SAM3 GPU Worker

Receives segmentation requests, processes with SAM3, returns masks.

Request format:
{
    "input": {
        "image_url": "https://...",  # Image URL to segment
        "concepts": ["wall", "door"],  # Concepts to segment
        "confidence_threshold": 0.5   # Optional, default 0.5
    }
}

Response format:
{
    "output": {
        "results": {
            "wall": {
                "instance_count": 2,
                "masks_base64": ["...", "..."],  # Base64 encoded PNG masks
                "scores": [0.95, 0.87]
            },
            ...
        },
        "image_size": [1920, 1080]
    }
}
"""

import os
import io
import base64
import runpod
import httpx
import numpy as np
from PIL import Image

# Lazy load segmenter to avoid loading model on cold start inspection
_segmenter = None


def get_segmenter():
    """Lazy load SAM3 segmenter (singleton pattern)."""
    global _segmenter
    if _segmenter is None:
        from engine.segmenter import SAM3Segmenter

        confidence = float(os.getenv("CONFIDENCE_THRESHOLD", "0.5"))
        _segmenter = SAM3Segmenter(confidence_threshold=confidence)
    return _segmenter


def download_image(url: str) -> Image.Image:
    """Download image from URL and return as PIL Image."""
    response = httpx.get(url, follow_redirects=True, timeout=30.0)
    response.raise_for_status()
    return Image.open(io.BytesIO(response.content)).convert("RGB")


def mask_to_base64_png(mask: np.ndarray) -> str:
    """Convert numpy mask to base64 encoded PNG."""
    # Convert boolean/float mask to uint8 (0 or 255)
    if mask.dtype == bool:
        mask_uint8 = (mask * 255).astype(np.uint8)
    elif mask.dtype in [np.float32, np.float64]:
        mask_uint8 = (mask * 255).astype(np.uint8)
    else:
        mask_uint8 = mask.astype(np.uint8)

    # Create grayscale image from mask
    mask_image = Image.fromarray(mask_uint8, mode="L")

    # Encode to PNG bytes
    buffer = io.BytesIO()
    mask_image.save(buffer, format="PNG")
    buffer.seek(0)

    # Return base64 encoded string
    return base64.b64encode(buffer.read()).decode("utf-8")


def handler(job):
    """
    Runpod serverless handler function.

    Args:
        job: Runpod job object with input data

    Returns:
        dict with segmentation results or error message
    """
    try:
        job_input = job["input"]

        # Validate required fields
        if "image_url" not in job_input:
            return {"error": "Missing required field: image_url"}
        if "concepts" not in job_input:
            return {"error": "Missing required field: concepts"}

        image_url = job_input["image_url"]
        concepts = job_input["concepts"]

        # Optional confidence threshold override
        if "confidence_threshold" in job_input:
            os.environ["CONFIDENCE_THRESHOLD"] = str(job_input["confidence_threshold"])

        # Download image
        print(f"Downloading image from {image_url}...")
        image = download_image(image_url)
        print(f"Image downloaded: {image.size}")

        # Get segmenter (lazy load)
        segmenter = get_segmenter()

        # Segment for each concept
        results = {}
        for concept in concepts:
            print(f"Segmenting concept: {concept}")
            masks, metadata = segmenter.segment(image, concept)

            # Convert masks to base64 PNG
            masks_base64 = [mask_to_base64_png(m) for m in masks]

            results[concept] = {
                "instance_count": metadata["instance_count"],
                "masks_base64": masks_base64,
            }

            # Add scores if available
            if "scores" in metadata:
                results[concept]["scores"] = metadata["scores"]

        # Return results
        return {
            "output": {
                "results": results,
                "image_size": list(image.size),
            }
        }

    except httpx.HTTPError as e:
        return {"error": f"Failed to download image: {str(e)}"}
    except FileNotFoundError as e:
        return {"error": f"Model file not found: {str(e)}"}
    except Exception as e:
        return {"error": f"Segmentation failed: {str(e)}"}


# Start Runpod serverless worker
if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
