# S3 Backend — SAM3 GPU Inference Server

> Vast.ai GPU에서 실행되는 **SAM3 추론 전용** 서버.
> Edge(Cloudflare Workers)에서만 호출 가능한 Internal API.
> **API 로직(CRUD, Auth, R2 업로드)은 Edge에서 처리.** 이 서버는 추론만 담당.

---

## Overview

- **Framework**: FastAPI + Uvicorn
- **Architecture**: 도메인 모듈 패턴 (segmentation 단일 도메인)
- **Model**: SAM3 (848M params, 3.4GB weights)
- **GPU**: Vast.ai (RTX 4090 / A100 / H100)
- **Storage**: Cloudflare R2 (boto3, 이미지 다운로드 + 마스크 업로드)
- **Runtime**: Python 3.12+, PyTorch 2.7+, CUDA 12.1+
- **Entry Point**: `uvicorn src.main:app`

### 역할 분담

| 담당 | Edge (Cloudflare Workers) | Backend (이 서버) |
|------|--------------------------|-------------------|
| Auth | Supabase JWT 검증 | X-API-Key만 확인 |
| R2 Upload | 사용자 이미지 직접 업로드 | 마스크 업로드 (boto3) |
| R2 Download | - | 추론용 이미지 다운로드 (boto3) |
| Supabase CRUD | 모든 INSERT/SELECT | 추론 완료 시 UPDATE만 |
| SAM3 추론 | - | ★ 유일한 핵심 역할 |

---

## API Endpoints (Internal — Edge만 호출)

> Auth: `X-API-Key: <API_SECRET_KEY>` 헤더 필수 (health 제외)
> 상세 Request/Response: `docs/contracts/api-contracts.md`

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | 헬스체크 (모델 상태, GPU 정보) |
| `POST` | `/api/v1/predict` | SAM3 추론 (단일 프롬프트) |
| `POST` | `/api/v1/predict/batch` | 배치 추론 (복수 프롬프트) |
| `GET` | `/api/v1/model/info` | 모델 정보 조회 |

### 추론 파이프라인 (`POST /api/v1/predict`)

```
Edge → POST /api/v1/predict { image_url, text_prompt, user_id, task_id }
  Backend:
    1. Supabase UPDATE status → "processing"
    2. R2에서 이미지 다운로드 (boto3)
    3. SAM3 추론
    4. 마스크 R2 업로드 (boto3)
    5. Supabase UPDATE (status: done, mask_url, labels, metadata)
    6. 응답 { task_id, mask_url, labels, inference_time_ms, confidence }
```

---

## File Map

```
backend/
├── src/
│   ├── __init__.py
│   ├── main.py                 ✅ FastAPI factory (segmentation만)
│   ├── config.py               ✅ SAM3 + R2 + Supabase 설정
│   ├── database.py             🔲 Supabase client (결과 업데이트용)
│   │
│   ├── segmentation/           ★ 추론 도메인 (유일한 도메인)
│   │   ├── __init__.py
│   │   ├── router.py           ✅ predict, predict/batch, model/info
│   │   ├── schemas.py          ✅ Pydantic request/response
│   │   ├── service.py          🔲 추론 파이프라인 (stub)
│   │   ├── dependencies.py     ✅ X-API-Key 검증
│   │   └── constants.py        ✅ 상수
│   │
│   ├── tasks/                  결과 업데이트 (Backend→Supabase)
│   │   ├── __init__.py
│   │   └── service.py          🔲 update_status, update_result (stub)
│   │
│   ├── sam3/                   SAM3 모델 래퍼
│   │   ├── __init__.py
│   │   ├── predictor.py        🔲 모델 로드 + 추론 (stub)
│   │   ├── postprocess.py      🔲 마스크 후처리 (stub)
│   │   └── config.py           ✅ 모델 설정
│   │
│   ├── storage/                R2 스토리지 (boto3)
│   │   ├── __init__.py
│   │   └── service.py          🔲 이미지 다운로드, 마스크 업로드 (stub)
│   │
│   └── core/
│       ├── __init__.py
│       └── middleware.py       ✅ CORS (Edge 도메인만)
│
├── tests/
│   ├── __init__.py
│   ├── conftest.py             ✅ TestClient + auth fixture
│   └── test_segmentation.py    ✅ health + model/info + auth
│
├── weights/.gitkeep
├── Dockerfile
├── docker-compose.yml
├── pyproject.toml
├── requirements.txt
├── .env.example
└── README.md                   ← 이 파일
```

**범례:** ✅ = 구현 완료 | 🔲 = stub (TODO)

---

## Agent 작업 가이드

> 이 레이어를 개발할 에이전트를 위한 **단계별 지침**.
> **주의:** 이 서버는 SAM3 추론 전용. CRUD/Auth/R2 업로드는 Edge에서 처리.

### Step 1: SAM3 모델 래퍼 (`src/sam3/predictor.py`)

**목표:** HuggingFace에서 SAM3 모델 로드 + 추론 메서드 구현

- `SAM3Predictor.load()` — `huggingface_hub`로 가중치 다운로드 → PyTorch 로드
- `SAM3Predictor.predict(image, text_prompt)` → `PredictResult`
- `SAM3Predictor.predict_batch(image, prompts)` → `list[PredictResult]`
- **검증:** `python -c "from src.sam3.predictor import SAM3Predictor; p = SAM3Predictor(); p.load()"`

### Step 2: R2 스토리지 서비스 (`src/storage/service.py`)

**목표:** boto3로 R2에서 이미지 다운로드 + 마스크 업로드

- `StorageService.download_image(url)` → `PIL.Image`
- `StorageService.upload_mask(mask, key)` → `str` (R2 URL)
- **검증:** `pytest tests/test_storage.py` (R2 mock 필요)

### Step 3: Supabase 결과 업데이트 (`src/tasks/service.py`)

**목표:** 추론 완료 시 Supabase에 결과 업데이트 (service_role)

- `TaskService.update_status(task_id, status)` — processing/done/error
- `TaskService.update_result(task_id, mask_url, labels, metadata)` — 결과 저장
- **주의:** CREATE/GET/LIST는 Edge가 담당. Backend는 UPDATE만.

### Step 4: 추론 파이프라인 + 테스트

**목표:** Step 1 + 2 + 3 통합

- `SegmentationService.run_prediction()` — 전체 파이프라인
- `pytest tests/test_segmentation.py` (mock predictor + mock storage)

---

## 의존하는 계약

| 대상 | 설명 | 파일 |
|------|------|------|
| Edge → Backend | Edge가 `X-API-Key` 헤더로 predict 호출 | `docs/contracts/api-contracts.md` |
| Backend → R2 | boto3로 이미지 다운로드 + 마스크 업로드 | `src/config.py` R2_* |
| Backend → Supabase | service_role로 segmentation_results UPDATE만 | `supabase/migrations/` |

---

## Setup & Run

```bash
# 가상환경
python -m venv .venv && source .venv/bin/activate  # Linux/Mac
python -m venv .venv && .venv\Scripts\activate      # Windows

# 의존성
pip install -r requirements.txt

# 환경변수
cp .env.example .env

# 서버 실행
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload

# 테스트
pytest -v

# Docker
docker build -t s3-backend .
docker compose up -d
```

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SAM3_WEIGHTS_PATH` | 모델 가중치 경로 (default: `weights/sam3.pt`) |
| `SAM3_DEVICE` | cuda / cpu |
| `HF_TOKEN` | HuggingFace 토큰 |
| `R2_ENDPOINT` | R2 엔드포인트 |
| `R2_ACCESS_KEY_ID` | R2 Access Key |
| `R2_SECRET_ACCESS_KEY` | R2 Secret Key |
| `R2_BUCKET` | R2 버킷명 (default: `s3-images`) |
| `SUPABASE_URL` | Supabase URL |
| `SUPABASE_SERVICE_KEY` | Supabase Service Key (결과 UPDATE용) |
| `API_SECRET_KEY` | Edge ↔ Backend 인증 키 |
