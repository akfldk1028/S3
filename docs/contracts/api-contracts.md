# S3 API Contracts

> **Single Source of Truth** for all inter-layer API communication.
> 엔드포인트 변경 시 이 파일을 먼저 수정할 것.

---

## Architecture Overview

```
Flutter → Edge(Full API, CF Workers) → Backend(SAM3 추론만, Vast.ai GPU)
                    ↕                            ↕
               Supabase (DB/Auth)           Supabase (결과 UPDATE)
```

- **Edge = Full API** — 모든 비즈니스 로직 (Auth, CRUD, R2 업로드, Supabase 연동)
- **Backend = SAM3 추론 전용** — GPU inference only. Edge에서만 호출.

---

## Response Envelope

모든 **Edge** API 응답은 이 형식을 따른다:

```typescript
// TypeScript (Edge — utils/response.ts)
interface ApiResponse<T> {
  success: boolean;
  data: T | null;
  error: { code: string; message: string } | null;
  meta: {
    request_id: string;    // UUID v4
    timestamp: string;     // ISO 8601
  };
}
```

**Backend**는 Response Envelope을 사용하지 않는다. 단순 JSON 응답 (Pydantic response_model).

---

## Auth Flow

```
1. Client → Supabase Auth → JWT (access_token + refresh_token)
2. Client → Edge: Authorization: Bearer <access_token>
3. Edge → Supabase: JWT 검증 → user_id 추출
4. Edge → Supabase REST API: JWT를 그대로 전달 (RLS 적용)
5. Edge → Backend: X-API-Key: <API_SECRET_KEY> (추론 요청 시)
```

---

## Edge Public API (Full API)

> **담당:** Edge (Cloudflare Workers) — 모든 비즈니스 로직 처리
> **호출자:** Flutter App
> **Base URL:** `https://s3-api.{domain}.workers.dev`
> **Auth:** `Authorization: Bearer <supabase_jwt>`

### POST `/api/v1/upload`

이미지를 R2에 업로드. **Edge가 직접 R2에 저장** (Backend 관여 없음).

**Request:**
```typescript
// Content-Type: multipart/form-data
interface UploadRequest {
  file: File;               // image/png, image/jpeg, image/webp (max 10MB)
  project_id?: string;      // UUID, optional
}
```

**Response:**
```typescript
interface UploadResponse {
  image_id: string;          // UUID
  image_url: string;         // R2 public URL
  size_bytes: number;
  content_type: string;
}
```

**Status Codes:** `200` OK, `400` Invalid file, `401` Unauthorized, `413` File too large

---

### POST `/api/v1/segment`

세그멘테이션 요청. **Edge가 처리:**
1. 요청 검증 (image_url, text_prompt)
2. Supabase: 유저 크레딧 확인
3. Supabase: segmentation_results INSERT (status: pending)
4. Backend POST /api/v1/predict 프록시 (비동기, waitUntil)
5. 즉시 응답 { task_id, status: 'pending' }

**Request:**
```typescript
interface SegmentRequest {
  image_url: string;         // R2 이미지 URL (upload 응답의 image_url)
  text_prompt: string;       // 세그멘테이션 텍스트 프롬프트
  project_id?: string;       // UUID, optional
}
```

**Response:**
```typescript
interface SegmentResponse {
  task_id: string;           // UUID — 폴링에 사용
  status: "pending";
}
```

**Status Codes:** `202` Accepted, `400` Bad request, `401` Unauthorized, `402` Insufficient credits, `429` Rate limited

---

### GET `/api/v1/tasks/:id`

작업 상태 조회. **Edge가 Supabase에서 직접 조회.**

**Response:**
```typescript
type TaskStatus = "pending" | "processing" | "done" | "error";

interface TaskResponse {
  task_id: string;
  status: TaskStatus;
  result_id?: string;        // status === "done"일 때
  error_message?: string;    // status === "error"일 때
  created_at: string;        // ISO 8601
  updated_at: string;
}
```

**Status Codes:** `200` OK, `401` Unauthorized, `404` Task not found

---

### GET `/api/v1/results`

사용자의 세그멘테이션 결과 목록 조회. **Edge가 Supabase에서 직접 조회.**

**Query Parameters:**
```typescript
interface ResultsQuery {
  project_id?: string;       // 프로젝트 필터
  page?: number;             // default: 1
  limit?: number;            // default: 20, max: 100
}
```

**Response:**
```typescript
interface ResultsListResponse {
  results: ResultSummary[];
  total: number;
  page: number;
  limit: number;
}

interface ResultSummary {
  id: string;
  source_image_url: string;
  mask_image_url: string;
  text_prompt: string;
  status: TaskStatus;
  created_at: string;
}
```

**Status Codes:** `200` OK, `401` Unauthorized

---

### GET `/api/v1/results/:id`

결과 상세 조회. **Edge가 Supabase에서 직접 조회.**

**Response:**
```typescript
interface ResultDetailResponse {
  id: string;
  project_id: string | null;
  source_image_url: string;
  mask_image_url: string;
  text_prompt: string;
  labels: string[];          // 감지된 객체 라벨
  metadata: {
    inference_time_ms: number;
    confidence: number;
    model_version: string;
  };
  status: TaskStatus;
  created_at: string;
  updated_at: string;
}
```

**Status Codes:** `200` OK, `401` Unauthorized, `404` Not found

---

## Backend Internal API (SAM3 추론 전용)

> **담당:** Backend (FastAPI, Vast.ai GPU) — SAM3 추론만 담당
> **호출자:** Edge만 호출 가능
> **Base URL:** `http://<vastai-instance>:8000`
> **Auth:** `X-API-Key: <API_SECRET_KEY>`

**API 로직(CRUD, Auth, R2 직접 업로드)은 Edge가 처리.** Backend는 추론만.

### GET `/health`

GPU 서버 헬스체크. 인증 불필요.

**Response:**
```python
class HealthResponse(BaseModel):
    status: str              # "ok"
    model_loaded: bool
    gpu_available: bool
    gpu_name: Optional[str]
    vram_used_mb: Optional[float]
    vram_total_mb: Optional[float]
```

**Status Codes:** `200` OK

---

### POST `/api/v1/predict`

SAM3 추론 실행. 추론 완료 후 **Backend가 직접 Supabase UPDATE** (service_role).

**Request:**
```python
class PredictRequest(BaseModel):
    image_url: str           # R2 이미지 URL
    text_prompt: str         # 세그멘테이션 프롬프트
    user_id: str             # Edge에서 전달
    task_id: str             # 작업 추적용
```

**Response:**
```python
class PredictResponse(BaseModel):
    task_id: str
    mask_url: str            # R2에 저장된 마스크 URL
    labels: list[str]        # 감지된 객체 라벨
    inference_time_ms: float
    confidence: float
```

**Backend 추론 파이프라인:**
1. Supabase UPDATE status → "processing"
2. R2에서 이미지 다운로드 (boto3)
3. SAM3 추론
4. 마스크 R2 업로드 (boto3)
5. Supabase UPDATE (status: done, mask_image_url, labels, metadata)
6. 결과 반환

**Status Codes:** `200` OK, `400` Bad request, `401` Invalid API key, `503` Model not loaded

---

### POST `/api/v1/predict/batch`

배치 추론 (여러 프롬프트 동시 처리).

**Request:**
```python
class BatchPredictRequest(BaseModel):
    image_url: str
    prompts: list[str]       # 여러 텍스트 프롬프트
    user_id: str
    task_id: str
```

**Response:**
```python
class BatchPredictResponse(BaseModel):
    task_id: str
    results: list[PredictResponse]
    total_inference_time_ms: float
```

**Status Codes:** `200` OK, `400` Bad request, `401` Invalid API key, `503` Model not loaded

---

### GET `/api/v1/model/info`

로드된 모델 정보 조회.

**Response:**
```python
class ModelInfoResponse(BaseModel):
    model_name: str          # "SAM3"
    model_version: str       # "1.0"
    parameters: int          # 848_000_000
    weights_size_gb: float   # 3.4
    device: str              # "cuda:0"
    dtype: str               # "float16"
```

**Status Codes:** `200` OK, `503` Model not loaded

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `AUTH_REQUIRED` | 401 | 인증 토큰 없음 |
| `AUTH_INVALID` | 401 | 토큰 만료/유효하지 않음 |
| `FORBIDDEN` | 403 | 권한 없음 |
| `NOT_FOUND` | 404 | 리소스 없음 |
| `INVALID_REQUEST` | 400 | 잘못된 요청 파라미터 |
| `FILE_TOO_LARGE` | 413 | 파일 크기 초과 (10MB) |
| `INSUFFICIENT_CREDITS` | 402 | 크레딧 부족 |
| `RATE_LIMITED` | 429 | 요청 횟수 초과 |
| `MODEL_NOT_LOADED` | 503 | SAM3 모델 미로드 |
| `INFERENCE_FAILED` | 500 | 추론 실패 |
| `INTERNAL_ERROR` | 500 | 내부 서버 에러 |

---

## Rate Limits

| Tier | Upload | Segment | Results Query |
|------|--------|---------|---------------|
| **free** | 10/min | 5/min | 60/min |
| **pro** | 30/min | 20/min | 120/min |
| **enterprise** | 100/min | 60/min | 300/min |
