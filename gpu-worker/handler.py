"""
Runpod Serverless Handler — Full Pipeline

Workers Queue에서 전체 job message를 받아서 pipeline.py로 처리.
segment → apply → R2 upload → Workers callback (per-item).

Input format (= GpuQueueMessage from Workers):
{
    "input": {
        "job_id": "...",
        "user_id": "...",
        "preset": "interior",
        "concepts": {"Floor": {"action": "recolor", "value": "#FF5733"}},
        "protect": ["Grout"],
        "items": [{"idx": 0, "input_key": "...", "output_key": "...", "preview_key": "..."}],
        "callback_url": "https://s3-workers.../jobs/{id}/callback",
        "batch_concurrency": 4
    }
}

Output: {"output": {"total_items": N, "successful_items": N, "failed_items": N, "errors": []}}
"""

import logging
import os
import runpod

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger(__name__)


def handler(job):
    """Runpod serverless handler — delegates to pipeline.process_job()."""
    try:
        job_input = job["input"]
        job_id = job_input.get("job_id", "unknown")
        logger.info(f"[Handler] Job {job_id} received — items: {len(job_input.get('items', []))}")

        from engine.pipeline import process_job
        result = process_job(job_input)

        logger.info(f"[Handler] Job {job_id} done — {result['successful_items']}/{result['total_items']} ok")
        return result

    except Exception as e:
        logger.error(f"[Handler] Job failed: {e}", exc_info=True)
        return {"error": str(e)}


if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
