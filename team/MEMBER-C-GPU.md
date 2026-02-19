# 팀원 C: GPU Worker — SAM3 Engine + Pipeline + Adapters

> **담당**: GPU Worker 전체 (SAM3 추론, 룰 적용, R2 I/O, 콜백, Docker)
> **상태**: 코드 완성 ✅, **Runpod 배포 필요 ❌**
> **브랜치**: master (머지 완료)

---

## 현재 상태 (2026-02-19)

### ✅ 완료된 작업

| 항목 | 상태 | 파일 |
|------|------|------|
| R2 I/O (boto3) | ✅ 완료 | `gpu-worker/engine/r2_io.py` |
| Callback (httpx) | ✅ 완료 | `gpu-worker/engine/callback.py` |
| SAM3 Segmenter | ✅ 완료 | `gpu-worker/engine/segmenter.py` |
| Rule Applier | ✅ 완료 | `gpu-worker/engine/applier.py` |
| Postprocessor | ✅ 완료 | `gpu-worker/engine/postprocess.py` |
| Pipeline Orchestrator | ✅ 완료 | `gpu-worker/engine/pipeline.py` |
| Runpod Adapter | ✅ 완료 | `gpu-worker/adapters/runpod_serverless.py` |
| Interior Preset | ✅ 완료 | `gpu-worker/presets/interior.py` |
| Seller Preset | ✅ 완료 | `gpu-worker/presets/seller.py` |
| Dockerfile | ✅ 완료 | `gpu-worker/Dockerfile` |
| Tests (133개) | ✅ 완료 | `gpu-worker/tests/` |
| Entry point | ✅ 완료 | `gpu-worker/main.py` |

### ❌ 미완료 작업

| 항목 | 상태 | 설명 |
|------|------|------|
| Docker build 검증 | ❌ 미확인 | 로컬에서 `docker build` 성공 확인 필요 |
| Runpod 배포 | ❌ 미배포 | Serverless endpoint 생성 필요 |
| SAM3 모델 다운로드 | ❌ 미확인 | HuggingFace에서 3.4GB 다운로드 테스트 |
| E2E 연동 | ❌ 미확인 | Workers Queue → GPU → R2 → Callback |

---

## 즉시 해야 할 일 (순서대로)

### Step 1: Docker Build 확인

```bash
cd gpu-worker
docker build -t s3-gpu .
```

**확인할 파일:**
- `gpu-worker/Dockerfile` — CUDA 12.6 + Python 3.12 기반
- `gpu-worker/requirements.txt` — 의존성 (runpod, httpx, torch, transformers, boto3, Pillow)
- `gpu-worker/.dockerignore` — 불필요 파일 제외

**트러블슈팅:**
- CUDA 버전 불일치 → Dockerfile의 FROM 이미지 확인
- pip install 실패 → requirements.txt 버전 핀 확인
- 이미지 크기 (~8GB) — `.dockerignore`로 test, docs 제외

### Step 2: Docker Registry에 Push

```bash
# Docker Hub
docker tag s3-gpu <username>/s3-gpu:latest
docker push <username>/s3-gpu:latest

# 또는 GHCR
docker tag s3-gpu ghcr.io/<org>/s3-gpu:latest
docker push ghcr.io/<org>/s3-gpu:latest
```

### Step 3: Runpod Serverless Endpoint 생성

**방법 1: Runpod MCP 도구 사용 (권장)**

```
1. MCP runpod → list-templates → 기존 템플릿 확인
2. MCP runpod → create-template:
   - name: "s3-gpu-worker"
   - dockerImage: "<registry>/s3-gpu:latest"
   - containerDiskInGb: 20
   - volumeInGb: 50  (모델 캐시용)
   - env:
     STORAGE_S3_ENDPOINT=<R2 endpoint>
     STORAGE_ACCESS_KEY=<R2 API Token>
     STORAGE_SECRET_KEY=<R2 Secret>
     STORAGE_BUCKET=s3-images
     GPU_CALLBACK_SECRET=<Workers와 동일>
     HF_TOKEN=<HuggingFace token>
     MODEL_CACHE_DIR=/models
     ADAPTER=runpod

3. MCP runpod → create-endpoint:
   - name: "s3-gpu-endpoint"
   - templateId: <위에서 만든 template ID>
   - gpuIds: ["NVIDIA RTX 4090"]  (또는 A100, H100)
   - workersMin: 0
   - workersMax: 3
   - idleTimeout: 5  (초, 유휴 시 스케일 다운)
```

**방법 2: Runpod Dashboard 수동 생성**

1. https://www.runpod.io/console/serverless → Create Endpoint
2. Docker image URL 입력
3. GPU 선택 (RTX 4090+, 16GB VRAM 이상)
4. 환경변수 설정 (위와 동일)

### Step 4: 환경변수 확인

**리드에게 받아야 하는 값:**

| 변수 | 출처 | 설명 |
|------|------|------|
| `STORAGE_S3_ENDPOINT` | CF Dashboard → R2 | R2 endpoint URL |
| `STORAGE_ACCESS_KEY` | CF Dashboard → R2 API Token | 리드가 생성 |
| `STORAGE_SECRET_KEY` | CF Dashboard → R2 API Token | 리드가 생성 |
| `GPU_CALLBACK_SECRET` | Workers .dev.vars | 리드에게 확인 |

**직접 준비하는 값:**

| 변수 | 설명 |
|------|------|
| `HF_TOKEN` | HuggingFace access token (SAM3 모델 다운로드) |
| `STORAGE_BUCKET` | `s3-images` (고정) |
| `MODEL_CACHE_DIR` | `/models` (볼륨 마운트) |
| `ADAPTER` | `runpod` (고정) |
| `BATCH_CONCURRENCY` | `4` (기본) |
| `LOG_LEVEL` | `info` |

**확인할 파일:**
- `gpu-worker/.env.example` — 전체 환경변수 목록
- `docs/cloudflare-resources.md` — R2 endpoint, bucket 정보

### Step 5: SAM3 모델 다운로드 테스트

```bash
# Runpod 배포 후 pod에 접속하여 확인
python -c "
from huggingface_hub import hf_hub_download
import os
os.environ['HF_TOKEN'] = '<your_token>'
path = hf_hub_download(
    repo_id='facebook/sam2.1-hiera-large',  # 실제 SAM3 repo 확인 필요
    filename='sam2.1_hiera_large.pt',
    cache_dir='/models'
)
print(f'Model downloaded to: {path}')
"
```

**확인할 파일:**
- `gpu-worker/engine/segmenter.py` — 모델 로드 로직
- `gpu-worker/requirements.txt` — huggingface_hub 포함 확인

### Step 6: E2E 연동 테스트

Workers가 Queue에 push한 메시지를 GPU Worker가 수신하는지 확인.

```
1. Workers에서 테스트 Job 생성:
   POST /jobs → presigned URLs
   POST /jobs/:id/confirm-upload
   POST /jobs/:id/execute → Queue push

2. Runpod endpoint 로그 확인:
   MCP runpod → Endpoint 로그 조회
   또는 Dashboard → Endpoint → Logs

3. Workers callback 수신 확인:
   MCP cloudflare-observability → query_worker_observability
   "s3-workers에서 callback 관련 로그 보여줘"
```

**확인할 파일:**
- `workers/src/jobs/jobs.route.ts` — Queue push 로직 (POST /execute)
- `workers/src/index.ts` — Queue consumer (메시지 형식)
- `gpu-worker/adapters/runpod_serverless.py` — Runpod handler
- `gpu-worker/engine/pipeline.py` — process_job() 전체 흐름
- `gpu-worker/engine/callback.py` — Workers 콜백 전송

---

## Queue 메시지 계약 (Workers → GPU Worker)

> 이 JSON이 GPU Worker의 유일한 입력. `workflow.md` 섹션 7 참조.

```json
{
  "job_id": "job_123",
  "user_id": "u_abc",
  "preset": "interior",
  "concepts": {
    "Floor": { "action": "recolor", "value": "oak_a" },
    "Wall": { "action": "recolor", "value": "offwhite_b" }
  },
  "protect": ["Grout", "Frame_Molding"],
  "items": [
    {
      "idx": 0,
      "input_key": "inputs/u_abc/job_123/0.jpg",
      "output_key": "outputs/u_abc/job_123/0_result.png",
      "preview_key": "previews/u_abc/job_123/0_thumb.jpg"
    }
  ],
  "callback_url": "https://s3-workers.clickaround8.workers.dev/jobs/job_123/callback",
  "idempotency_prefix": "job_123",
  "batch_concurrency": 4
}
```

---

## 콜백 인증 (GPU Worker → Workers)

```python
# callback.py — 필수 헤더
headers = {"Authorization": f"Bearer {os.environ['GPU_CALLBACK_SECRET']}"}
```

Workers에서 이 secret을 검증. `.env`의 `GPU_CALLBACK_SECRET` 값이
Workers `.dev.vars`의 `GPU_CALLBACK_SECRET`과 **반드시 동일**해야 함.

---

## 완료 기준

- [x] R2 download/upload 동작 (boto3)
- [x] Callback POST 동작 + 재시도 (3회)
- [x] SAM3 모델 wrapper
- [x] Rule apply: recolor/tone/texture/remove
- [x] Pipeline: 전체 흐름
- [x] Runpod handler
- [x] Postprocess: PNG + 썸네일 JPEG
- [x] `pytest` 133개 통과 (mocked)
- [x] Dockerfile 작성
- [ ] **Docker build 성공 확인**
- [ ] **Docker registry push**
- [ ] **Runpod Serverless endpoint 생성**
- [ ] **환경변수 설정 (R2 + callback secret + HF_TOKEN)**
- [ ] **SAM3 모델 다운로드 테스트**
- [ ] **E2E: Workers → Queue → GPU → R2 → Callback 전체 흐름**
