"""Segmentation domain — SAM3 추론 파이프라인.

추론 전용 비즈니스 로직:
1. R2에서 이미지 다운로드 (storage/service.py)
2. SAM3 추론 (sam3/predictor.py)
3. 마스크 R2 업로드 (storage/service.py)
4. Supabase segmentation_results UPDATE (status: done)
5. 결과 반환 (mask_url, labels, confidence)
"""


class SegmentationService:
    """SAM3 추론 파이프라인 오케스트레이션."""

    def __init__(self, predictor, storage, task_service):
        self.predictor = predictor
        self.storage = storage
        self.tasks = task_service

    async def run_prediction(
        self, image_url: str, text_prompt: str, task_id: str, user_id: str,
    ):
        """단일 추론 파이프라인.

        TODO:
        1. await self.tasks.update_status(task_id, "processing")
        2. image = await self.storage.download_image(image_url)
        3. result = await self.predictor.predict(image, text_prompt)
        4. mask_url = await self.storage.upload_mask(result.mask, task_id)
        5. await self.tasks.update_result(task_id, mask_url, result.labels, {
               "inference_time_ms": result.time_ms,
               "confidence": result.confidence,
               "model_version": self.predictor.version,
           })
        6. return { mask_url, labels, inference_time_ms, confidence }
        """
        raise NotImplementedError

    async def run_batch_prediction(
        self, image_url: str, prompts: list[str], task_id: str, user_id: str,
    ):
        """배치 추론 파이프라인.

        TODO:
        1. await self.tasks.update_status(task_id, "processing")
        2. image = await self.storage.download_image(image_url)
        3. results = await self.predictor.predict_batch(image, prompts)
        4. 각 결과에 대해 마스크 업로드 + DB 업데이트
        5. 결과 리스트 반환
        """
        raise NotImplementedError
