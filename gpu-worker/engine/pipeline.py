"""
Pipeline — 전체 추론 파이프라인

흐름: R2 다운로드 → SAM3 segment → rule apply → 후처리 → R2 업로드 → Workers callback

TODO: Auto-Claude 구현
- process_job(job_message: dict) → None
  1. items 순회
  2. r2_io.download(input_key)
  3. segmenter.segment(image, concepts, protect)
  4. applier.apply_rules(image, masks, concepts)
  5. postprocess.finalize(result)
  6. r2_io.upload(output_key, result)
  7. callback.report(callback_url, idx, status, output_key)
- batch_concurrency 적용 (asyncio or ThreadPool)
"""


def process_job(job_message: dict) -> dict:
    """Process a single GPU job. Returns result summary."""
    # TODO: implement
    raise NotImplementedError
