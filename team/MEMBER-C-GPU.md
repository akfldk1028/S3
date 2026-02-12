# 팀원 C: GPU Worker — SAM3 Engine + Pipeline + Adapters

> **담당**: GPU Worker 전체 (SAM3 추론, 룰 적용, R2 I/O, 콜백, Docker)
> **브랜치**: `feat/gpu-engine`
> **완전 독립**: Workers/Frontend와 무관하게 작업 가능

---

## 프로젝트 컨텍스트 (필독)

S3는 "도메인 팔레트 엔진 기반 세트 생산 앱"이다.
- **GPU Worker = "근육"**: SAM3 segment + rule apply 2단계 추론
- **입력**: Queue 메시지 (JSON) → R2에서 이미지 다운로드
- **출력**: 결과 이미지 R2 업로드 → Workers callback (HTTP POST)
- **플랫폼**: Runpod Serverless (MVP), adapter 패턴으로 교체 가능
- **SSoT**: `workflow.md` — 섹션 7(Queue 메시지), 섹션 8(GPU Worker)

---

## 담당 파일 (전체 gpu-worker/)

```
gpu-worker/
├── main.py                   ← [구현] 어댑터 선택 진입점
├── engine/
│   ├── __init__.py            ← [완성]
│   ├── pipeline.py            ← [구현] 전체 파이프라인 오케스트레이션
│   ├── segmenter.py           ← [구현] SAM3 모델 로드 + 추론
│   ├── applier.py             ← [구현] 마스크 기반 룰 적용
│   ├── postprocess.py         ← [구현] PNG/JPEG 변환, 썸네일
│   ├── r2_io.py               ← [구현] R2 업/다운로드 (boto3)
│   └── callback.py            ← [구현] Workers POST 콜백 + 재시도
├── adapters/
│   ├── __init__.py            ← [완성]
│   ├── runpod_serverless.py   ← [구현] Runpod handler (MVP)
│   └── queue_pull.py          ← [나중] v2 폴링 어댑터
├── presets/
│   ├── __init__.py            ← [완성]
│   ├── interior.py            ← [완성] 인테리어 concept 매핑
│   └── seller.py              ← [완성] 셀러 concept 매핑
├── tests/
│   ├── test_pipeline.py       ← [구현] 파이프라인 테스트
│   └── test_segmenter.py      ← [구현] Segmenter 테스트
├── Dockerfile                 ← [완성] CUDA 12.6 + Python 3.12
├── requirements.txt           ← [완성] 의존성 목록
└── .env.example               ← [완성] 환경변수 템플릿
```

---

## Queue 메시지 계약 (Workers → GPU Worker)

> 이 JSON이 GPU Worker의 유일한 입력이다. `workflow.md` 섹션 7 참조.

```json
{
  "job_id": "job_123",
  "user_id": "u_abc",
  "preset": "interior",
  "concepts": {
    "Floor": { "action": "recolor", "value": "oak_a" },
    "Wall": { "action": "recolor", "value": "offwhite_b" }
  },
  "protect": ["Grout", "Frame_Molding", "Glass_highlight"],
  "items": [
    {
      "idx": 0,
      "input_key": "inputs/u_abc/job_123/0.jpg",
      "output_key": "outputs/u_abc/job_123/0_result.png",
      "preview_key": "previews/u_abc/job_123/0_thumb.jpg"
    }
  ],
  "callback_url": "https://s3-api.example.workers.dev/jobs/job_123/callback",
  "idempotency_prefix": "job_123",
  "batch_concurrency": 4
}
```

---

## 구현 순서

### Step 1: R2 I/O (r2_io.py) — 스토리지 연결

```python
# boto3로 S3 호환 API 사용 (R2 = S3 compatible)

import boto3
from botocore.config import Config

class R2Client:
    def __init__(self):
        self.client = boto3.client(
            's3',
            endpoint_url=os.environ['STORAGE_S3_ENDPOINT'],
            aws_access_key_id=os.environ['STORAGE_ACCESS_KEY'],
            aws_secret_access_key=os.environ['STORAGE_SECRET_KEY'],
            region_name='auto',
        )
        self.bucket = os.environ['STORAGE_BUCKET']

    def download(self, key: str, local_path: str) -> None:
        self.client.download_file(self.bucket, key, local_path)

    def upload(self, local_path: str, key: str, content_type: str = 'image/png') -> None:
        self.client.upload_file(local_path, self.bucket, key,
            ExtraArgs={'ContentType': content_type})

    def download_bytes(self, key: str) -> bytes:
        response = self.client.get_object(Bucket=self.bucket, Key=key)
        return response['Body'].read()

    def upload_bytes(self, data: bytes, key: str, content_type: str = 'image/png') -> None:
        self.client.put_object(Bucket=self.bucket, Key=key,
            Body=data, ContentType=content_type)
```

### Step 2: Callback (callback.py)

```python
import httpx

async def report_item_result(
    callback_url: str,
    idx: int,
    status: str,  # "done" | "failed"
    output_key: str | None,
    preview_key: str | None,
    error: str | None,
    idempotency_key: str,
    secret: str,
    max_retries: int = 3,
) -> None:
    payload = {
        "idx": idx,
        "status": status,
        "output_key": output_key,
        "preview_key": preview_key,
        "error": error,
        "idempotency_key": idempotency_key,
    }
    headers = {"Authorization": f"Bearer {secret}"}

    for attempt in range(max_retries):
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.post(callback_url, json=payload, headers=headers)
                if resp.status_code < 500:
                    return  # 성공 또는 4xx (영구 실패)
        except httpx.RequestError:
            pass
        # 지수 백오프: 5s, 30s, 300s
        await asyncio.sleep(5 * (6 ** attempt))
```

### Step 3: Segmenter (segmenter.py) — SAM3 핵심

```python
import torch
from PIL import Image
import numpy as np

class SAM3Segmenter:
    def __init__(self, model_dir: str = "/models"):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model = self._load_model(model_dir)

    def _load_model(self, model_dir: str):
        # SAM3 모델 로드
        # TODO: SAM3 공식 API에 맞게 구현
        # from sam3 import SAM3Model  (또는 실제 패키지)
        pass

    def segment(
        self,
        image: np.ndarray,       # H×W×3 RGB
        concepts: dict,          # {"Floor": {"action":...}, "Wall": {...}}
        protect: list[str],      # ["Grout", "Frame_Molding"]
        preset_mapping: dict,    # interior.py의 CONCEPTS
    ) -> dict:
        """
        Returns:
        {
            "masks": {"Floor": ndarray, "Wall": ndarray},  # H×W binary
            "instances": {
                "Floor": [{"id": 0, "mask": ndarray, "bbox": [...], "area": int}]
            },
            "protect_mask": ndarray,  # 합산 보호 마스크 H×W binary
        }
        """
        result = {"masks": {}, "instances": {}, "protect_mask": None}

        # 1. 각 concept에 대해 SAM3 text-prompted segmentation
        for concept_name in concepts:
            if concept_name not in preset_mapping:
                continue
            prompt = preset_mapping[concept_name]["sam3_prompt"]
            # mask = self.model.predict(image, text_prompt=prompt)
            # result["masks"][concept_name] = mask

        # 2. protect concepts에 대해 마스크 생성 + 합산
        protect_combined = np.zeros(image.shape[:2], dtype=bool)
        for p in protect:
            if p in preset_mapping:
                prompt = preset_mapping[p]["sam3_prompt"]
                # p_mask = self.model.predict(image, text_prompt=prompt)
                # protect_combined |= p_mask
        result["protect_mask"] = protect_combined

        return result
```

### Step 4: Applier (applier.py) — 룰 적용

```python
import numpy as np
from PIL import Image

def apply_rules(
    image: np.ndarray,          # H×W×3 원본
    segment_result: dict,       # segmenter 출력
    concepts: dict,             # {"Floor": {"action": "recolor", "value": "oak_a"}}
) -> np.ndarray:
    """마스크 영역에 룰을 적용하고, protect 영역은 보호."""
    result = image.copy()
    protect_mask = segment_result["protect_mask"]

    for concept_name, rule in concepts.items():
        if concept_name not in segment_result["masks"]:
            continue
        mask = segment_result["masks"][concept_name]
        # protect 영역 제외
        effective_mask = mask & ~protect_mask

        if rule["action"] == "recolor":
            result = _recolor(result, effective_mask, rule["value"])
        elif rule["action"] == "tone":
            result = _adjust_tone(result, effective_mask, rule["value"])
        elif rule["action"] == "remove":
            result = _inpaint(result, effective_mask)
        # ... 추가 룰

    return result

def _recolor(image: np.ndarray, mask: np.ndarray, color_id: str) -> np.ndarray:
    # MVP: 간단한 색상 블렌딩
    # color_id → RGB 매핑 필요 (presets에서?)
    # mask 영역을 target color로 블렌딩
    pass

def _adjust_tone(image: np.ndarray, mask: np.ndarray, value: str) -> np.ndarray:
    # 밝기/채도 조절
    pass

def _inpaint(image: np.ndarray, mask: np.ndarray) -> np.ndarray:
    # 영역 제거 (인페인팅)
    pass
```

### Step 5: Postprocess (postprocess.py)

```python
from PIL import Image
import numpy as np

def finalize(
    result_image: np.ndarray,  # H×W×3
    max_size: int = 4096,
) -> tuple[bytes, bytes]:
    """결과 PNG + 썸네일 JPEG 반환"""
    img = Image.fromarray(result_image)

    # 결과 PNG
    if max(img.size) > max_size:
        img.thumbnail((max_size, max_size), Image.LANCZOS)
    png_buffer = io.BytesIO()
    img.save(png_buffer, format='PNG', optimize=True)

    # 썸네일 JPEG (300px)
    thumb = img.copy()
    thumb.thumbnail((300, 300), Image.LANCZOS)
    jpg_buffer = io.BytesIO()
    thumb.save(jpg_buffer, format='JPEG', quality=85)

    return png_buffer.getvalue(), jpg_buffer.getvalue()
```

### Step 6: Pipeline (pipeline.py) — 전체 오케스트레이션

```python
import asyncio
from engine.segmenter import SAM3Segmenter
from engine.applier import apply_rules
from engine.postprocess import finalize
from engine.r2_io import R2Client
from engine.callback import report_item_result
from presets import get_preset_mapping

segmenter = None  # 글로벌 (모델 1회 로드)

async def process_job(message: dict) -> None:
    global segmenter
    if segmenter is None:
        segmenter = SAM3Segmenter()

    r2 = R2Client()
    preset_mapping = get_preset_mapping(message["preset"])
    concurrency = message.get("batch_concurrency", 4)

    sem = asyncio.Semaphore(concurrency)

    async def process_item(item: dict):
        async with sem:
            idx = item["idx"]
            idem_key = f"{message['idempotency_prefix']}:{idx}:0"
            try:
                # 1. R2에서 이미지 다운로드
                img_bytes = r2.download_bytes(item["input_key"])
                image = np.array(Image.open(io.BytesIO(img_bytes)).convert("RGB"))

                # 2. SAM3 Segment
                seg_result = segmenter.segment(
                    image, message["concepts"], message["protect"], preset_mapping
                )

                # 3. Rule Apply
                result = apply_rules(image, seg_result, message["concepts"])

                # 4. Postprocess
                png_bytes, jpg_bytes = finalize(result)

                # 5. R2 Upload
                r2.upload_bytes(png_bytes, item["output_key"], "image/png")
                r2.upload_bytes(jpg_bytes, item["preview_key"], "image/jpeg")

                # 6. Callback (성공)
                await report_item_result(
                    message["callback_url"], idx, "done",
                    item["output_key"], item["preview_key"], None,
                    idem_key, os.environ.get("GPU_CALLBACK_SECRET", "")
                )
            except Exception as e:
                # Callback (실패)
                await report_item_result(
                    message["callback_url"], idx, "failed",
                    None, None, str(e),
                    idem_key, os.environ.get("GPU_CALLBACK_SECRET", "")
                )

    # 모든 item 병렬 처리 (semaphore로 동시성 제한)
    tasks = [process_item(item) for item in message["items"]]
    await asyncio.gather(*tasks)
```

### Step 7: Runpod Adapter (runpod_serverless.py)

```python
import runpod
from engine.pipeline import process_job

def handler(event: dict) -> dict:
    """Runpod Serverless handler"""
    message = event.get("input", {})
    import asyncio
    asyncio.run(process_job(message))
    return {"status": "completed", "job_id": message.get("job_id")}

def start():
    runpod.serverless.start({"handler": handler})
```

---

## 프리셋 매핑 (이미 완성됨)

`presets/interior.py` 예시:
```python
INTERIOR_CONCEPTS = {
    "Wall": {"sam3_prompt": "wall surface", "multi_instance": False},
    "Floor": {"sam3_prompt": "floor surface", "multi_instance": False},
    "Tile": {"sam3_prompt": "individual tile", "multi_instance": True},
    "Grout": {"sam3_prompt": "grout lines between tiles", "multi_instance": False},
    # ... 12개 concept
}
```

---

## 환경 설정

```bash
cd gpu-worker/
python -m venv .venv
.venv\Scripts\activate   # Windows

pip install -r requirements.txt

cp .env.example .env
# STORAGE_S3_ENDPOINT=https://xxx.r2.cloudflarestorage.com
# STORAGE_ACCESS_KEY=xxx
# STORAGE_SECRET_KEY=xxx
# STORAGE_BUCKET=s3-images

# 로컬 테스트 (GPU 없어도 가능 — mock mode)
pytest

# Docker 빌드
docker build -t s3-gpu .
```

---

## 테스트 전략

1. **GPU 없는 환경**: segmenter를 mock으로 교체 → pipeline 흐름만 검증
2. **GPU 있는 환경**: SAM3 모델 다운로드 → 실제 추론 테스트
3. **R2 테스트**: 로컬 MinIO 또는 실제 R2 dev bucket 사용
4. **Callback 테스트**: 로컬 HTTP 서버로 POST 수신 확인

---

## 완료 기준

- [ ] R2 download/upload 동작 (boto3)
- [ ] Callback POST 동작 + 재시도 (3회)
- [ ] SAM3 모델 로드 + segment 동작 (또는 mock)
- [ ] Rule apply: recolor 최소 1개 동작
- [ ] Pipeline: 전체 흐름 (다운 → segment → apply → 업로드 → callback)
- [ ] Runpod handler: event → process_job 호출
- [ ] Postprocess: PNG + 썸네일 JPEG 생성
- [ ] `pytest` 통과
- [ ] `docker build` 성공
