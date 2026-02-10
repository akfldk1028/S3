# S3 - SAM3 Segmentation App Architecture

## Overview

SAM3(Segment Anything Model 3, Meta 2025.11)를 활용한 이미지/비디오 세그멘테이션 앱.
텍스트 프롬프트로 객체를 감지하고 세그멘테이션하는 서비스를 제공한다.

## System Architecture

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Flutter    │────▶│  Cloudflare      │────▶│  Vast.ai GPU    │
│   App        │◀────│  Workers + R2    │◀────│  (FastAPI)      │
│  (Frontend)  │     │  (Edge Layer)    │     │  SAM3 Inference │
└──────┬───────┘     └──────────────────┘     └─────────────────┘
       │                                              │
       │              ┌──────────────────┐            │
       └─────────────▶│    Supabase      │◀───────────┘
                      │  Auth / DB / RT  │
                      └──────────────────┘
```

### Data Flow

```
1. User → Flutter App → 이미지 업로드 + 텍스트 프롬프트
2. Flutter → Cloudflare R2 → 이미지 저장 (edge storage)
3. Flutter → Cloudflare Workers → Vast.ai FastAPI → SAM3 추론
4. SAM3 결과(마스크) → Cloudflare R2 저장 → Flutter 표시
5. 메타데이터 → Supabase DB 저장
```

---

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter 3.38.9 | 크로스 플랫폼 앱 (iOS/Android/Web) |
| **Edge** | Cloudflare Workers | API 게이트웨이, 캐싱, 라우팅 |
| **Edge Storage** | Cloudflare R2 | 이미지/마스크 저장 (S3 호환) |
| **GPU Backend** | FastAPI + Uvicorn | SAM3 추론 API 서버 |
| **GPU Infra** | Vast.ai | GPU 임대 (A100/H100) |
| **AI Model** | SAM3 (848M params) | 세그멘테이션 모델 |
| **Database** | Supabase (PostgreSQL) | 유저, 프로젝트, 결과 메타데이터 |
| **Auth** | Supabase Auth | 인증/인가 |
| **Realtime** | Supabase Realtime | 추론 상태 실시간 알림 |

---

## Folder Structure

```
C:\DK\S3\
├── ARCHITECTURE.md
├── .gitignore
│
├── frontend/                        # Flutter App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── common_widgets/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_theme.dart
│   │   │   └── api_endpoints.dart
│   │   ├── routing/
│   │   │   └── app_router.dart
│   │   ├── utils/
│   │   └── features/
│   │       ├── auth/
│   │       │   ├── models/
│   │       │   ├── mutations/
│   │       │   ├── queries/
│   │       │   └── pages/
│   │       │       ├── providers/
│   │       │       ├── screens/
│   │       │       └── widgets/
│   │       ├── home/
│   │       │   └── pages/screens/
│   │       ├── segmentation/       # ★ 핵심 기능
│   │       │   ├── models/
│   │       │   │   ├── segmentation_result_model.dart
│   │       │   │   └── segmentation_request_model.dart
│   │       │   ├── mutations/
│   │       │   │   └── run_segmentation_mutation.dart
│   │       │   ├── queries/
│   │       │   │   ├── get_results_query.dart
│   │       │   │   └── get_result_detail_query.dart
│   │       │   └── pages/
│   │       │       ├── providers/
│   │       │       │   └── segmentation_provider.dart
│   │       │       ├── screens/
│   │       │       │   ├── segmentation_screen.dart
│   │       │       │   └── result_detail_screen.dart
│   │       │       └── widgets/
│   │       │           ├── image_picker_widget.dart
│   │       │           ├── prompt_input_widget.dart
│   │       │           ├── mask_overlay_widget.dart
│   │       │           └── result_card_widget.dart
│   │       ├── gallery/             # 결과 갤러리
│   │       │   ├── models/
│   │       │   ├── queries/
│   │       │   └── pages/
│   │       │       ├── screens/
│   │       │       └── widgets/
│   │       └── profile/
│   │           └── pages/screens/
│   ├── pubspec.yaml
│   └── test/
│
├── backend/                         # FastAPI + SAM3 (Vast.ai GPU)
│   ├── app/
│   │   ├── main.py                  # FastAPI 진입점
│   │   ├── config.py                # 환경설정 (BaseSettings)
│   │   │
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── router.py        # v1 라우터 통합
│   │   │       └── endpoints/
│   │   │           ├── health.py    # 헬스체크
│   │   │           ├── segmentation.py  # ★ 세그멘테이션 API
│   │   │           └── tasks.py     # 작업 상태 조회
│   │   │
│   │   ├── core/
│   │   │   ├── security.py          # API Key / JWT 검증
│   │   │   ├── middleware.py        # CORS, 로깅, 에러 핸들링
│   │   │   └── dependencies.py      # FastAPI DI
│   │   │
│   │   ├── models/
│   │   │   ├── sam3/                # ★ SAM3 모델 래퍼
│   │   │   │   ├── predictor.py     # SAM3 predictor 초기화/추론
│   │   │   │   ├── postprocess.py   # 마스크 후처리
│   │   │   │   └── config.py        # 모델 설정 (weights path, device)
│   │   │   └── __init__.py
│   │   │
│   │   ├── schemas/
│   │   │   ├── segmentation.py      # Request/Response Pydantic 모델
│   │   │   └── task.py              # 작업 상태 스키마
│   │   │
│   │   ├── services/
│   │   │   ├── segmentation_service.py  # 비즈니스 로직
│   │   │   ├── storage_service.py   # R2 업로드/다운로드
│   │   │   └── task_service.py      # 비동기 작업 관리
│   │   │
│   │   └── utils/
│   │       ├── image.py             # 이미지 전처리
│   │       └── mask.py              # 마스크 인코딩/디코딩
│   │
│   ├── weights/                     # SAM3 모델 가중치 (gitignore)
│   │   └── .gitkeep
│   ├── tests/
│   │   ├── test_segmentation.py
│   │   └── conftest.py
│   ├── Dockerfile                   # Vast.ai 배포용
│   ├── docker-compose.yml
│   ├── pyproject.toml
│   ├── requirements.txt
│   └── .env.example
│
├── edge/                            # Cloudflare Workers + R2
│   ├── wrangler.toml                # Cloudflare 설정
│   ├── src/
│   │   ├── index.ts                 # Worker 진입점
│   │   ├── router.ts                # 라우팅
│   │   ├── handlers/
│   │   │   ├── upload.ts            # 이미지 업로드 → R2
│   │   │   ├── segmentation.ts      # Vast.ai 프록시
│   │   │   └── result.ts            # 결과 조회
│   │   ├── middleware/
│   │   │   ├── auth.ts              # Supabase JWT 검증
│   │   │   ├── cors.ts              # CORS
│   │   │   └── ratelimit.ts         # Rate limiting
│   │   ├── services/
│   │   │   ├── r2.ts                # R2 Storage 헬퍼
│   │   │   └── vastai.ts            # Vast.ai backend 프록시
│   │   └── types/
│   │       └── index.ts             # TypeScript 타입 정의
│   ├── package.json
│   ├── tsconfig.json
│   └── .dev.vars                    # 로컬 환경변수 (gitignore)
│
├── supabase/                        # Supabase (DB + Auth)
│   ├── config.toml                  # Supabase 프로젝트 설정
│   ├── migrations/
│   │   ├── 00001_create_users_profile.sql
│   │   ├── 00002_create_projects.sql
│   │   ├── 00003_create_segmentation_results.sql
│   │   └── 00004_create_usage_logs.sql
│   ├── functions/                   # Supabase Edge Functions
│   │   └── process-webhook/
│   │       └── index.ts
│   └── seed.sql                     # 초기 데이터
│
├── ai/                              # AI 모델 관련 스크립트/노트북
│   ├── notebooks/
│   │   ├── sam3_test.ipynb          # SAM3 테스트
│   │   └── benchmark.ipynb          # 성능 벤치마크
│   ├── scripts/
│   │   ├── download_weights.py      # 모델 가중치 다운로드
│   │   └── convert_model.py         # 모델 변환 (optional)
│   └── prompts/
│       └── default_prompts.json     # 기본 텍스트 프롬프트 예시
│
├── docs/                            # 문서
│   └── api.md                       # API 문서
│
├── scripts/                         # 프로젝트 스크립트
│   ├── setup.sh                     # 전체 환경 셋업
│   └── deploy.sh                    # 배포 스크립트
│
└── clone/                           # AC247 레퍼런스 (참고용)
    └── Auto-Claude/
```

---

## Database Schema (Supabase)

```sql
-- 유저 프로필 (Supabase Auth 연동)
users_profile
├── id              UUID PK (= auth.users.id)
├── display_name    TEXT
├── avatar_url      TEXT
├── tier            TEXT DEFAULT 'free'   -- free / pro / enterprise
├── credits         INTEGER DEFAULT 100
├── created_at      TIMESTAMPTZ
└── updated_at      TIMESTAMPTZ

-- 프로젝트
projects
├── id              UUID PK
├── user_id         UUID FK → users_profile
├── name            TEXT
├── description     TEXT
├── created_at      TIMESTAMPTZ
└── updated_at      TIMESTAMPTZ

-- 세그멘테이션 결과
segmentation_results
├── id              UUID PK
├── project_id      UUID FK → projects
├── user_id         UUID FK → users_profile
├── source_image_url    TEXT            -- R2 원본 이미지 URL
├── mask_image_url      TEXT            -- R2 마스크 이미지 URL
├── text_prompt         TEXT            -- 텍스트 프롬프트
├── labels              JSONB           -- 감지된 라벨 목록
├── metadata            JSONB           -- 추론 시간, 신뢰도 등
├── status              TEXT            -- pending / processing / done / error
├── created_at          TIMESTAMPTZ
└── updated_at          TIMESTAMPTZ

-- 사용량 로그
usage_logs
├── id              UUID PK
├── user_id         UUID FK → users_profile
├── action          TEXT                -- segmentation / upload
├── credits_used    INTEGER
├── metadata        JSONB
└── created_at      TIMESTAMPTZ
```

---

## API Endpoints

### Edge (Cloudflare Workers) - Public API

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/upload` | 이미지 업로드 → R2 저장 |
| `POST` | `/api/v1/segment` | 세그멘테이션 요청 |
| `GET` | `/api/v1/tasks/:id` | 작업 상태 조회 |
| `GET` | `/api/v1/results` | 결과 목록 조회 |
| `GET` | `/api/v1/results/:id` | 결과 상세 조회 |

### Backend (FastAPI on Vast.ai) - Internal API

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | GPU 서버 헬스체크 |
| `POST` | `/api/v1/predict` | SAM3 추론 실행 |
| `POST` | `/api/v1/predict/batch` | 배치 추론 |
| `GET` | `/api/v1/model/info` | 모델 정보 조회 |

---

## Request Flow Detail

```
[Flutter App]
    │
    ├─ 1. POST /api/v1/upload (이미지)
    │     → Cloudflare Worker → R2에 저장 → image_url 반환
    │
    ├─ 2. POST /api/v1/segment { image_url, text_prompt }
    │     → Cloudflare Worker
    │       ├─ JWT 검증 (Supabase Auth)
    │       ├─ 크레딧 확인
    │       ├─ Supabase DB에 task 생성 (status: pending)
    │       ├─ Vast.ai FastAPI POST /api/v1/predict 호출
    │       │   ├─ SAM3 추론 실행 (GPU)
    │       │   ├─ 마스크 결과 → R2 업로드
    │       │   └─ 결과 반환
    │       ├─ Supabase DB 업데이트 (status: done, mask_url, labels)
    │       └─ 크레딧 차감
    │
    └─ 3. GET /api/v1/results/:id
          → Cloudflare Worker → Supabase 조회 → 결과 + R2 URL 반환
```

---

## Key Design Decisions

### 1. Edge Layer (Cloudflare Workers)를 두는 이유
- Vast.ai GPU 서버를 직접 노출하지 않음 (보안)
- 이미지 캐싱, Rate Limiting, Auth 처리
- Vast.ai 인스턴스 교체 시 엔드포인트 변경 불필요
- R2 Storage로 이미지/마스크를 글로벌 엣지에서 서빙

### 2. 비동기 처리 전략
- SAM3 추론은 ~30ms (H200 기준)이지만 이미지 업로드/다운로드 포함 시 더 걸림
- 간단한 요청: 동기 처리 (Worker가 대기)
- 대용량/배치: task_id 반환 후 폴링 또는 Supabase Realtime으로 상태 알림

### 3. Vast.ai 인스턴스 관리
- Docker 이미지로 패키징 (SAM3 + FastAPI + 가중치)
- 인스턴스 교체 시 edge/src/services/vastai.ts에서 URL만 변경
- 오토스케일링 필요 시 여러 인스턴스 + Workers에서 로드밸런싱

---

## Environment Variables

### Backend (.env)
```
SAM3_WEIGHTS_PATH=/app/weights/sam3.pt
SAM3_DEVICE=cuda
HF_TOKEN=hf_xxxxx
R2_ENDPOINT=https://xxx.r2.cloudflarestorage.com
R2_ACCESS_KEY_ID=xxx
R2_SECRET_ACCESS_KEY=xxx
R2_BUCKET=s3-images
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_KEY=xxx
API_SECRET_KEY=xxx
```

### Edge (.dev.vars)
```
VASTAI_BACKEND_URL=http://xxx.xxx.xxx.xxx:8000
API_SECRET_KEY=xxx
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
R2_BUCKET=s3-images
```

### Frontend (constants/api_endpoints.dart)
```dart
static const baseUrl = 'https://s3-api.your-domain.workers.dev';
static const supabaseUrl = 'https://xxx.supabase.co';
static const supabaseAnonKey = 'xxx';
```

---

## Commands

| Command | Location | Description |
|---------|----------|-------------|
| `flutter run` | `frontend/` | Flutter 앱 실행 |
| `dart run build_runner build` | `frontend/` | Freezed/Riverpod 코드 생성 |
| `uvicorn app.main:app --reload` | `backend/` | FastAPI 로컬 실행 |
| `docker build -t s3-backend .` | `backend/` | Docker 이미지 빌드 |
| `npx wrangler dev` | `edge/` | Workers 로컬 실행 |
| `npx wrangler deploy` | `edge/` | Workers 배포 |
| `supabase db push` | `supabase/` | DB 마이그레이션 |
| `supabase start` | `supabase/` | 로컬 Supabase 실행 |

---

## GPU Requirements (Vast.ai)

| Spec | Minimum | Recommended |
|------|---------|-------------|
| **GPU VRAM** | 16 GB | 24+ GB |
| **GPU Model** | RTX 4090 | A100 / H100 |
| **RAM** | 16 GB | 32 GB |
| **Disk** | 20 GB | 50 GB |
| **CUDA** | 12.1+ | 12.6+ |
| **Python** | 3.12+ | 3.12+ |
| **PyTorch** | 2.7+ | 2.7+ |

SAM3 모델: **848M params**, 가중치 **3.4 GB**, 추론 **~30ms/image** (H200)
