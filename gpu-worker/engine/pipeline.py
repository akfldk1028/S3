"""
Pipeline — 전체 추론 파이프라인

흐름: R2 다운로드 → SAM3 segment → rule apply → 후처리 → R2 업로드 → Workers callback

2-Stage Pipeline:
  Stage 1: Segment ALL concepts ONCE (expensive SAM3 operation)
  Stage 2: Apply rules per item using cached masks (fast operations)

Per-item callbacks after each upload.
Error handling per-item (partial job success).
Uses BATCH_CONCURRENCY for parallelism.
"""

import os
import io
import logging
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Optional

from PIL import Image

from .segmenter import SAM3Segmenter
from .applier import apply_rules
from .r2_io import R2Client
from .callback import report


# Configure logging
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger(__name__)

# Get batch concurrency from environment or job message
DEFAULT_BATCH_CONCURRENCY = int(os.getenv("BATCH_CONCURRENCY", "4"))


def process_job(job_message: dict) -> dict:
    """
    Process a single GPU job with 2-stage pipeline.

    Args:
        job_message: Job specification containing:
            - job_id: Job identifier
            - user_id: User identifier
            - preset: Domain preset (interior, seller, etc.)
            - concepts: Dict mapping concept names to rule definitions
                       Example: {"Floor": {"action": "recolor", "value": "#FF5733"}}
            - protect: List of concept names to protect (optional)
            - items: List of items to process, each with:
                - idx: Item index
                - input_key: R2 key for input image
                - output_key: R2 key for output image
                - preview_key: R2 key for preview thumbnail
            - callback_url: Workers callback URL
            - batch_concurrency: Max concurrent item processing (optional)

    Returns:
        dict: Result summary with:
            - total_items: Total number of items
            - successful_items: Number of successfully processed items
            - failed_items: Number of failed items
            - errors: List of error messages (if any)

    Example:
        >>> job_message = {
        ...     "job_id": "job_123",
        ...     "user_id": "u_abc",
        ...     "preset": "interior",
        ...     "concepts": {
        ...         "Floor": {"action": "recolor", "value": "#FF5733"}
        ...     },
        ...     "protect": ["Grout"],
        ...     "items": [
        ...         {
        ...             "idx": 0,
        ...             "input_key": "inputs/u_abc/job_123/0.jpg",
        ...             "output_key": "outputs/u_abc/job_123/0_result.png",
        ...             "preview_key": "previews/u_abc/job_123/0_thumb.jpg"
        ...         }
        ...     ],
        ...     "callback_url": "https://api.example.com/jobs/job_123/callback",
        ...     "batch_concurrency": 4
        ... }
        >>> result = process_job(job_message)
        >>> print(result)
        {'total_items': 1, 'successful_items': 1, 'failed_items': 0, 'errors': []}
    """
    job_id = job_message.get("job_id", "unknown")
    user_id = job_message.get("user_id", "unknown")
    concepts = job_message.get("concepts", {})
    protect = job_message.get("protect", [])
    items = job_message.get("items", [])
    callback_url = job_message.get("callback_url", "")
    batch_concurrency = job_message.get("batch_concurrency", DEFAULT_BATCH_CONCURRENCY)

    logger.info(f"Starting job {job_id} for user {user_id} with {len(items)} items")

    # Initialize result summary
    result_summary = {
        "total_items": len(items),
        "successful_items": 0,
        "failed_items": 0,
        "errors": []
    }

    # Early return if no items
    if not items:
        logger.warning(f"Job {job_id} has no items to process")
        return result_summary

    # Initialize R2 client
    r2_client = R2Client()

    # ====================
    # STAGE 1: Segment ALL concepts ONCE (expensive SAM3 operation)
    # ====================
    logger.info(f"Stage 1: Segmenting {len(concepts)} concepts + {len(protect)} protect concepts")

    # Download first image to use as reference for segmentation
    # (In a real implementation, we might want to segment per image if they differ significantly)
    first_item = items[0]
    try:
        first_image_bytes = r2_client.download(first_item["input_key"])
        first_image = Image.open(io.BytesIO(first_image_bytes))
    except Exception as e:
        error_msg = f"Failed to download first image for segmentation: {str(e)}"
        logger.error(error_msg)
        result_summary["errors"].append(error_msg)
        # If we can't get the first image, fail all items
        for item in items:
            _callback_failure(callback_url, item["idx"], error_msg)
            result_summary["failed_items"] += 1
        return result_summary

    # Initialize SAM3 segmenter
    try:
        segmenter = SAM3Segmenter()
        logger.info("SAM3 segmenter initialized successfully")
    except Exception as e:
        error_msg = f"Failed to initialize SAM3 segmenter: {str(e)}"
        logger.error(error_msg)
        result_summary["errors"].append(error_msg)
        # If segmenter fails, fail all items
        for item in items:
            _callback_failure(callback_url, item["idx"], error_msg)
            result_summary["failed_items"] += 1
        return result_summary

    # Segment all concepts
    all_masks = {}
    all_metadata = {}

    # Segment concepts that have rules
    for concept_name in concepts.keys():
        try:
            logger.info(f"Segmenting concept: {concept_name}")
            masks, metadata = segmenter.segment(first_image, concept_name)
            all_masks[concept_name] = masks
            all_metadata[concept_name] = metadata
            logger.info(f"  → Found {metadata['instance_count']} instances")
        except Exception as e:
            error_msg = f"Failed to segment concept '{concept_name}': {str(e)}"
            logger.warning(error_msg)
            result_summary["errors"].append(error_msg)
            # Continue with other concepts even if one fails
            all_masks[concept_name] = []
            all_metadata[concept_name] = {"concept": concept_name, "instance_count": 0, "scores": []}

    # Segment protect concepts and combine into single protect mask
    protect_mask = None
    if protect:
        logger.info(f"Segmenting {len(protect)} protect concepts")
        protect_masks_list = []
        for protect_concept in protect:
            try:
                logger.info(f"Segmenting protect concept: {protect_concept}")
                masks, metadata = segmenter.segment(first_image, protect_concept)
                if len(masks) > 0:
                    # Combine all instances of this protect concept
                    import numpy as np
                    combined_mask = np.maximum.reduce(masks) if len(masks) > 1 else masks[0]
                    protect_masks_list.append(combined_mask)
                    logger.info(f"  → Found {metadata['instance_count']} instances")
            except Exception as e:
                logger.warning(f"Failed to segment protect concept '{protect_concept}': {str(e)}")
                # Continue with other protect concepts

        # Combine all protect masks into one
        if protect_masks_list:
            import numpy as np
            protect_mask = np.maximum.reduce(protect_masks_list) if len(protect_masks_list) > 1 else protect_masks_list[0]
            logger.info(f"Combined {len(protect_masks_list)} protect masks")

    logger.info("Stage 1 complete: All concepts segmented")

    # ====================
    # STAGE 2: Apply rules per item using cached masks (with concurrency)
    # ====================
    logger.info(f"Stage 2: Processing {len(items)} items with batch_concurrency={batch_concurrency}")

    def process_single_item(item: dict) -> tuple[int, bool, Optional[str]]:
        """
        Process a single item. Returns (idx, success, error_message).

        Args:
            item: Item dict with idx, input_key, output_key, preview_key

        Returns:
            tuple: (idx, success: bool, error_message: Optional[str])
        """
        idx = item["idx"]
        input_key = item["input_key"]
        output_key = item["output_key"]
        preview_key = item.get("preview_key", "")

        try:
            logger.info(f"Processing item {idx}: {input_key}")

            # Download input image
            image_bytes = r2_client.download(input_key)
            image = Image.open(io.BytesIO(image_bytes))

            # Apply rules using cached masks
            result_image = apply_rules(image, all_masks, concepts, protect_mask)

            # Upload output image
            output_buffer = io.BytesIO()
            result_image.save(output_buffer, format="PNG")
            output_bytes = output_buffer.getvalue()
            r2_client.upload(output_key, output_bytes, content_type="image/png")
            logger.info(f"  → Uploaded output: {output_key}")

            # Generate and upload preview (low-res thumbnail)
            if preview_key:
                preview_image = result_image.copy()
                preview_image.thumbnail((400, 400))  # Max 400px on longest side
                preview_buffer = io.BytesIO()
                preview_image.save(preview_buffer, format="JPEG", quality=85)
                preview_bytes = preview_buffer.getvalue()
                r2_client.upload(preview_key, preview_bytes, content_type="image/jpeg")
                logger.info(f"  → Uploaded preview: {preview_key}")

            # Callback success
            success = report(
                callback_url=callback_url,
                idx=idx,
                status="completed",
                output_key=output_key,
                preview_key=preview_key if preview_key else None,
            )

            if success:
                logger.info(f"  → Callback sent successfully for item {idx}")
            else:
                logger.warning(f"  → Callback failed for item {idx} (but item processed successfully)")

            return (idx, True, None)

        except Exception as e:
            error_msg = f"Failed to process item {idx}: {str(e)}"
            logger.error(error_msg)

            # Callback failure
            report(
                callback_url=callback_url,
                idx=idx,
                status="failed",
                error=error_msg,
            )

            return (idx, False, error_msg)

    # Process items with concurrency
    with ThreadPoolExecutor(max_workers=batch_concurrency) as executor:
        # Submit all items for processing
        future_to_idx = {executor.submit(process_single_item, item): item["idx"] for item in items}

        # Collect results as they complete
        for future in as_completed(future_to_idx):
            idx, success, error_msg = future.result()

            if success:
                result_summary["successful_items"] += 1
            else:
                result_summary["failed_items"] += 1
                if error_msg:
                    result_summary["errors"].append(error_msg)

    logger.info(
        f"Job {job_id} complete: {result_summary['successful_items']}/{result_summary['total_items']} successful, "
        f"{result_summary['failed_items']} failed"
    )

    return result_summary


def _callback_failure(callback_url: str, idx: int, error_msg: str) -> None:
    """Helper function to send failure callback."""
    if callback_url:
        report(
            callback_url=callback_url,
            idx=idx,
            status="failed",
            error=error_msg,
        )
