"""
Runpod Serverless Handler — Full Pipeline

Lazy singleton: 첫 요청에서 SAM3 로드, 이후 모든 요청에서 재사용.
Workers Queue에서 전체 job message를 받아서 pipeline.py로 처리.
"""

import logging
import os

import runpod

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger(__name__)

# ─── Lazy singleton segmenter ─────────────────────────────────
_segmenter = None
_segmenter_loaded = False


def _get_segmenter():
    """첫 호출에서 SAM3 로드, 이후 캐시된 인스턴스 반환."""
    global _segmenter, _segmenter_loaded
    if not _segmenter_loaded:
        try:
            from engine.segmenter import SAM3Segmenter
            _segmenter = SAM3Segmenter()
            logger.info("[Handler] SAM3 모델 로드 완료")
        except Exception as e:
            logger.warning(f"[Handler] SAM3 로드 실패: {e}")
            _segmenter = None
        _segmenter_loaded = True
    return _segmenter


def handler(job):
    """Runpod serverless handler — delegates to pipeline.process_job()."""
    try:
        job_input = job["input"]
        job_id = job_input.get("job_id", "unknown")
        logger.info(f"[Handler] Job {job_id} received — items: {len(job_input.get('items', []))}")

        segmenter = _get_segmenter()

        from engine.pipeline import process_job
        result = process_job(job_input, segmenter=segmenter)

        logger.info(f"[Handler] Job {job_id} done — {result['successful_items']}/{result['total_items']} ok")
        return result

    except Exception as e:
        logger.error(f"[Handler] Job failed: {e}", exc_info=True)
        return {"error": str(e)}


if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
