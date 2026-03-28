"""
Test Handler — Pipeline E2E without SAM3

R2에서 이미지 다운 → 빨간 오버레이 적용 → R2 업로드 → Workers callback.
SAM3 없이 파이프라인 전체를 검증하는 용도.
"""

import io
import logging
import os

import runpod
from PIL import Image, ImageDraw

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger(__name__)


def handler(job):
    """Runpod serverless handler — dummy processing (no SAM3)."""
    try:
        job_input = job["input"]
        job_id = job_input.get("job_id", "unknown")
        items = job_input.get("items", [])
        callback_url = job_input.get("callback_url", "")
        concepts = job_input.get("concepts", {})

        logger.info(f"[TestHandler] Job {job_id} — {len(items)} items, concepts: {list(concepts.keys())}")

        from engine.r2_io import R2Client
        from engine.callback import report

        r2 = R2Client()

        successful = 0
        failed = 0
        errors = []

        for item in items:
            idx = item["idx"]
            input_key = item["input_key"]
            output_key = item["output_key"]
            preview_key = item.get("preview_key", "")

            try:
                # 1. Download from R2
                logger.info(f"  [item {idx}] Downloading {input_key}")
                image_bytes = r2.download(input_key)
                image = Image.open(io.BytesIO(image_bytes))
                logger.info(f"  [item {idx}] Downloaded {image.size}")

                # 2. Dummy processing — apply colored overlay for each concept
                result = image.copy().convert("RGBA")
                overlay = Image.new("RGBA", result.size, (0, 0, 0, 0))
                draw = ImageDraw.Draw(overlay)

                colors = {"Floor": (255, 87, 51, 80), "Wall": (51, 87, 255, 80),
                          "Tile": (51, 255, 87, 80), "Ceiling": (255, 255, 51, 80)}

                for i, (concept, rule) in enumerate(concepts.items()):
                    color = colors.get(concept, (200, 200, 200, 80))
                    h = result.size[1]
                    w = result.size[0]
                    y0 = int(h * i / max(len(concepts), 1))
                    y1 = int(h * (i + 1) / max(len(concepts), 1))
                    draw.rectangle([0, y0, w, y1], fill=color)
                    logger.info(f"  [item {idx}] Applied dummy rule for '{concept}': {rule}")

                result = Image.alpha_composite(result, overlay).convert("RGB")

                # 3. Upload output to R2
                out_buf = io.BytesIO()
                result.save(out_buf, format="PNG")
                r2.upload(output_key, out_buf.getvalue(), content_type="image/png")
                logger.info(f"  [item {idx}] Uploaded output: {output_key}")

                # 4. Upload preview
                if preview_key:
                    preview = result.copy()
                    preview.thumbnail((400, 400))
                    prev_buf = io.BytesIO()
                    preview.save(prev_buf, format="JPEG", quality=85)
                    r2.upload(preview_key, prev_buf.getvalue(), content_type="image/jpeg")

                # 5. Callback success
                report(callback_url=callback_url, idx=idx, status="done",
                       output_key=output_key, preview_key=preview_key or None)
                successful += 1
                logger.info(f"  [item {idx}] Done!")

            except Exception as e:
                error_msg = f"Item {idx} failed: {str(e)}"
                logger.error(error_msg)
                report(callback_url=callback_url, idx=idx, status="failed", error=error_msg)
                failed += 1
                errors.append(error_msg)

        result = {
            "total_items": len(items),
            "successful_items": successful,
            "failed_items": failed,
            "errors": errors,
            "mode": "test_handler_no_sam3",
        }
        logger.info(f"[TestHandler] Job {job_id} done: {successful}/{len(items)} ok")
        return result

    except Exception as e:
        logger.error(f"[TestHandler] Job failed: {e}", exc_info=True)
        return {"error": str(e)}


if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
