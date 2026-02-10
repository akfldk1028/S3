# S3 - SAM3 Segmentation App

> **SAM3**(Segment Anything Model 3, Meta 2025.11) 기반 이미지/비디오 세그멘테이션 앱.
> 텍스트 프롬프트로 객체를 감지하고 세그멘테이션하는 서비스.

---

## System Architecture

```
┌─────────────┐     ┌──────────────────────────┐     ┌─────────────────┐
│   Flutter    │────▶│  Cloudflare Workers       │────▶│  Vast.ai GPU    │
│   App        │◀────│  Full API (Hono + R2)     │◀────│  (FastAPI)      │
│  (Frontend)  │     │  Auth, CRUD, R2, Supabase │     │  SAM3 추론만     │
└──────┬───────┘     └────────────┬─────────────┘     └─────────────────┘
       │                          │                           │
       │              ┌───────────▼──────────┐                │
       └─────────────▶│    Supabase          │◀───────────────┘
                      │  Auth / DB / RT      │  (service_role: 결과 UPDATE)
                      └──────────────────────┘
```

**핵심 원칙:**
- **Edge = Full API** — Flutter가 호출하는 유일한 API 서버. 모든 비즈니스 로직 담당.
- **Backend = SAM3 추론만** — GPU에서 추론만 실행. Edge에서만 호출 가능한 Internal API.
- **Edge → Supabase** — 모든 CRUD (anon key + JWT)
- **Backend → Supabase** — 추론 완료 시 결과 UPDATE만 (service_role)

**Data Flow:**
1. User → Flutter App → 이미지 업로드 + 텍스트 프롬프트
2. Flutter → Edge Worker → R2 이미지 저장 (Edge가 직접 R2 put)
3. Flutter → Edge Worker → Supabase INSERT (pending) → Backend POST /predict (비동기)
4. Backend: R2에서 이미지 다운로드 → SAM3 추론 → 마스크 R2 업로드 → Supabase UPDATE (done)
5. Flutter → Edge Worker → Supabase SELECT → 결과 반환

---

## Layer Responsibilities

| Layer | Directory | Tech | Role | Status |
|-------|-----------|------|------|--------|
| **Frontend** | `frontend/` | Flutter 3.38.9 + Riverpod 3 + ShadcnUI | 크로스 플랫폼 앱 | ~30% |
| **Edge** | `edge/` | Hono + Cloudflare Workers + R2 (TypeScript) | **Full API** — Auth, CRUD, R2, Supabase 연동, Backend 추론 프록시 | scaffolding |
| **Backend** | `backend/` | FastAPI + SAM3 (Python 3.12) | **SAM3 추론 전용** — GPU inference only | scaffolding |
| **Supabase** | `supabase/` | PostgreSQL + Auth + Realtime | DB + Auth + Realtime | scaffolding |
| **AI** | `ai/` | SAM3 모델 스크립트/노트북 | 모델 관리 | scaffolding |

각 레이어 디렉토리의 `README.md`에 상세 가이드가 있음.

---

## Critical Rules

1. **API Contract는 `docs/contracts/api-contracts.md`가 Single Source of Truth** — 엔드포인트 변경 시 반드시 이 파일 먼저 수정
2. **레이어 간 직접 import 금지** — 항상 HTTP API를 통해 통신
3. **환경변수에 시크릿 하드코딩 금지** — `.env.example`만 커밋
4. **Frontend는 Edge API만 호출** — Backend(Vast.ai)를 직접 호출하지 않음
5. **Backend는 SAM3 추론 전용 Internal API** — Edge에서만 접근 가능, API_SECRET_KEY로 인증
6. **Edge가 모든 비즈니스 로직 담당** — CRUD, R2 업로드, Supabase 연동, 크레딧 확인
7. **모든 테이블에 RLS 활성화** — Supabase 정책 필수
8. **모델 가중치 커밋 금지** — `weights/` 디렉토리는 gitignore

---

## API Contract Summary

> 상세: `docs/contracts/api-contracts.md`

### Edge Public API — Flutter가 호출

> Base URL: `https://s3-api.{domain}.workers.dev`
> Auth: `Authorization: Bearer <supabase_jwt>`

| Method | Path | Description | 처리 주체 |
|--------|------|-------------|----------|
| `POST` | `/api/v1/upload` | 이미지 업로드 → R2 저장, `image_url` 반환 | Edge (R2 직접) |
| `POST` | `/api/v1/segment` | 세그멘테이션 요청 → `task_id` 반환 | Edge (Supabase INSERT → Backend 프록시) |
| `GET` | `/api/v1/tasks/:id` | 작업 상태 조회 | Edge (Supabase SELECT) |
| `GET` | `/api/v1/results` | 결과 목록 조회 (paginated) | Edge (Supabase SELECT) |
| `GET` | `/api/v1/results/:id` | 결과 상세 조회 | Edge (Supabase SELECT) |

### Backend Internal API — Edge만 호출

> Base URL: `http://<vastai-instance>:8000`
> Auth: `X-API-Key: <API_SECRET_KEY>`

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | GPU 서버 헬스체크 |
| `POST` | `/api/v1/predict` | SAM3 추론 실행 (이미지 → 마스크) |
| `POST` | `/api/v1/predict/batch` | 배치 추론 |
| `GET` | `/api/v1/model/info` | 모델 정보 조회 |

### Response Envelope

```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "meta": { "request_id": "uuid", "timestamp": "ISO8601" }
}
```

### Auth Flow

```
1. Flutter → Supabase Auth (로그인/회원가입) → JWT 토큰 획득
2. Flutter → Edge API 요청 시 Authorization: Bearer <JWT> 헤더
3. Edge → Supabase JWT 검증 → user_id 추출
4. Edge → Supabase REST API (CRUD) — JWT를 그대로 전달 (RLS 적용)
5. Edge → Backend 요청 시 X-API-Key: <API_SECRET_KEY> 헤더
```

---

## Database Schema

4개 테이블: `users_profile`, `projects`, `segmentation_results`, `usage_logs`

상세 스키마는 `supabase/migrations/` 참조.

| Table | PK | 핵심 필드 |
|-------|-----|----------|
| `users_profile` | `id` (= auth.users.id) | tier, credits |
| `projects` | `id` | user_id, name |
| `segmentation_results` | `id` | project_id, source_image_url, mask_image_url, text_prompt, status |
| `usage_logs` | `id` | user_id, action, credits_used |

---

## Environment Variables

### Backend (`backend/.env`)
```
SAM3_WEIGHTS_PATH=/app/weights/sam3.pt
SAM3_DEVICE=cuda
HF_TOKEN=
R2_ENDPOINT=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET=s3-images
SUPABASE_URL=
SUPABASE_SERVICE_KEY=
API_SECRET_KEY=
```

### Edge (`edge/.dev.vars`)
```
VASTAI_BACKEND_URL=
API_SECRET_KEY=
SUPABASE_URL=
SUPABASE_ANON_KEY=
R2_BUCKET=s3-images
```

### Frontend (`frontend/lib/constants/api_endpoints.dart`)
```dart
baseUrl = 'https://s3-api.your-domain.workers.dev'  // Edge Worker URL (유일한 API)
supabaseUrl = 'https://xxx.supabase.co'
supabaseAnonKey = 'xxx'
```

---

## Commands Reference

| Command | Location | Description |
|---------|----------|-------------|
| `flutter run` | `frontend/` | Flutter 앱 실행 |
| `dart run build_runner build` | `frontend/` | Freezed/Riverpod 코드 생성 |
| `npx wrangler dev` | `edge/` | Edge Full API 로컬 실행 |
| `npx tsc --noEmit` | `edge/` | Edge 타입 체크 |
| `npx wrangler deploy` | `edge/` | Edge 배포 |
| `uvicorn src.main:app --reload` | `backend/` | Backend 추론 서버 로컬 실행 |
| `docker build -t s3-backend .` | `backend/` | Docker 이미지 빌드 |
| `pytest` | `backend/` | 백엔드 테스트 |
| `supabase start` | `supabase/` | 로컬 Supabase 실행 |
| `supabase db push` | `supabase/` | DB 마이그레이션 |

---

## GPU Requirements (Vast.ai)

- **SAM3**: 848M params, 가중치 3.4GB, 추론 ~30ms/image (H200)
- **최소**: RTX 4090 (16GB VRAM), CUDA 12.1+, Python 3.12+, PyTorch 2.7+
- **권장**: A100/H100 (24GB+ VRAM), CUDA 12.6+

---

## Agent 작업 흐름

각 레이어 README.md에 **Agent 작업 가이드**가 있음:
- `edge/README.md` — Step 1~6: Auth JWT → Supabase client → R2 → Upload → Segment → Results
- `backend/README.md` — Step 1~4: SAM3 래퍼 → Storage → Supabase 업데이트 → 테스트
- `supabase/README.md` — Step 1~5: 마이그레이션 검증 → Webhook → RLS 테스트 → Realtime
- `ai/README.md` — Step 1~4: 가중치 다운로드 → 변환 → 추론 테스트 → 벤치마크
- `frontend/README.md` — TODO 목록 참조

---

## Project Structure

```
S3/
├── CLAUDE.md                 ← 지금 이 파일
├── docs/contracts/
│   └── api-contracts.md      ← API 계약서 (SSoT)
├── frontend/                 ← Flutter App (~30%)
├── edge/                     ← Full API (Cloudflare Workers + R2)
├── backend/                  ← SAM3 추론 전용 (FastAPI + GPU)
├── supabase/                 ← DB + Auth + Realtime
└── ai/                       ← 모델 스크립트/노트북
```
