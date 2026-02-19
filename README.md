# S3 — Domain Palette Engine

> 도메인 구성요소를 잡고, 규칙으로 세트를 찍어내는 앱
> SAM3(Meta, 2025.11) 기반 — Concept → Instance → Protect → Rule → Output Set

---

## 연결 상태 (2026-02-19)

```
┌──────────────┐      ┌─────────────────────────────────┐      ┌──────────────────┐
│   Flutter    │─ ✓ ──│  Cloudflare                     │─ ✗ ──│  GPU Worker      │
│   App        │      │  Workers + DO + D1 + R2         │      │  (Runpod)        │
│ (S3ApiClient)│      │  (배포됨, 14/14 엔드포인트 구현)  │      │  (코드만 완성)    │
└──────────────┘      └─────────────────────────────────┘      └──────────────────┘
```

### 한눈에 보는 현황

| 구간 | 상태 | 비고 |
|------|------|------|
| Flutter → Workers | **연결됨** | S3ApiClient + JWT + envelope unwrap |
| Auth (anon JWT) | **연결됨** | POST /auth/anon → token → SecureStorage |
| Workers 14개 엔드포인트 | **전부 구현** | auth+presets+rules+me+jobs 7개 |
| Workers → GPU Queue | **배선 완료** | Queue push 구현, GPU Worker 미배포 |
| GPU Worker | **미배포** | 코드 23파일 완성, Runpod 미배포 |
| D1/R2/DO/Queues | **배포됨** | 인프라 전부 존재 |
| 레거시 폴더 | **삭제됨** | cf-backend/, ai-backend/ 제거 완료 |

---

## Architecture

```
입구 (Workers)           뇌 (DO)               근육 (GPU)
┌──────────────┐    ┌───────────────┐    ┌───────────────┐
│ Hono Router  │───▶│UserLimiterDO  │    │ SAM3 Engine   │
│ Auth MW(JWT) │    │(크레딧/동시성) │    │ (segment)     │
│ D1 CRUD      │───▶│JobCoordinator │───▶│ Rule Applier  │
│ R2 Presigned │    │(상태머신/FSM) │    │ R2 Upload     │
│ Queue Push   │    └───────────────┘    │ Callback POST │
└──────────────┘           │             └───────────────┘
      │                    ▼                     │
   ┌──────┐         ┌──────────┐                 │
   │  D1  │         │  Queues  │─────────────────┘
   │SQLite│         │ gpu-jobs │     (GPU 미배포)
   └──────┘         └──────────┘
```

---

## Workers API (`https://s3-workers.clickaround8.workers.dev`)

| Endpoint | 상태 | 처리 주체 |
|----------|------|----------|
| `GET /health` | **작동** | Workers |
| `POST /auth/anon` | **작동** | Workers → D1 |
| `GET /me` | **작동** | UserLimiterDO → D1 |
| `GET /presets` | **작동** | Workers (하드코딩) |
| `GET /presets/:id` | **작동** | Workers |
| `POST /rules` | **작동** | UserLimiterDO → D1 |
| `GET /rules` | **작동** | D1 |
| `PUT /rules/:id` | **작동** | D1 |
| `DELETE /rules/:id` | **작동** | D1 + UserLimiterDO |
| `GET /jobs` | **작동** | D1 (목록 조회) |
| `POST /jobs` | **작동** | UserLimiterDO → JobCoordinatorDO → R2 presigned |
| `POST /jobs/:id/confirm-upload` | **작동** | JobCoordinatorDO |
| `POST /jobs/:id/execute` | **작동** | JobCoordinatorDO → Queue push |
| `GET /jobs/:id` | **작동** | JobCoordinatorDO + R2 download URLs |
| `POST /jobs/:id/callback` | **작동** | GPU_CALLBACK_SECRET → JobCoordinatorDO |
| `POST /jobs/:id/cancel` | **작동** | JobCoordinatorDO → UserLimiterDO rollback |

---

## Data Flow

```
Step  Flow                             현재
────  ───────────────────────────────  ──────
 1    Flutter → POST /auth/anon        ✓ 연결됨 (JWT 발급 → 저장)
 2    Flutter → GET /presets/:id       ✓ 연결됨 (프리셋 로드)
 3    Flutter → POST /jobs             ✓ 구현됨 (presigned URLs 발급)
 4    Flutter → R2 PUT (presigned)     ✓ presigned URL 생성됨
 5    Flutter → POST /confirm-upload   ✓ 구현됨 (created → uploaded)
 6    User: concept/protect/rule 설정  ✓ 로컬 state
 7    Flutter → POST /execute          ✓ 구현됨 (Queue push)
 8    Workers → Queue push             ✓ 구현됨 (GpuQueueMessage 조립)
 9    GPU → SAM3 segment + apply       ✗ GPU 미배포
10    GPU → POST /callback             ✓ Workers 구현됨 (GPU 미배포)
11    Flutter → GET /jobs/:id poll     ✓ 구현됨 (상태+download URLs)
12    Flutter → 결과 표시              ✓ UI 있음 (GPU 연결 대기)
```

---

## Directory Structure

```
S3/
├── README.md                  ← 이 파일
├── CLAUDE.md                  # Agent 코딩 규칙, MCP 도구, 아키텍처
├── workflow.md                # SSoT — API 스키마, 데이터 모델, 전체 설계
├── TODO.md                    # Phase A~E 실행 계획
│
├── workers/                   # ── Cloudflare Workers (Hono + TS) ──
│   ├── src/
│   │   ├── index.ts           # Entry: routes mount + queue consumer
│   │   ├── auth/              # ✅ POST /auth/anon — JWT 발급
│   │   ├── presets/           # ✅ GET /presets, /presets/:id
│   │   ├── rules/             # ✅ CRUD 4개
│   │   ├── user/              # ✅ GET /me (mounted at /me)
│   │   ├── jobs/              # ✅ 7개 구현 완료 (list+create+confirm+execute+status+callback+cancel)
│   │   ├── do/                # ✅ 완전 구현 (UserLimiter, JobCoordinator)
│   │   ├── middleware/        # ✅ JWT 검증 (callback skip)
│   │   └── _shared/          # 타입, response helper, R2 helper, JWT
│   ├── migrations/
│   │   └── 0001_init_schema.sql
│   └── wrangler.toml
│
├── gpu-worker/                # ── GPU Worker (Python + Docker) ──
│   ├── engine/                # ✅ SAM3 pipeline (미배포)
│   ├── adapters/              # ✅ Runpod Serverless adapter
│   ├── presets/               # ✅ interior + seller 도메인 매핑
│   ├── docs/                  # 레거시 프롬프트 보존 (legacy-prompts.json)
│   ├── tests/                 # ✅ 133개 테스트
│   ├── Dockerfile
│   └── main.py
│
├── frontend/                  # ── Flutter App ──
│   └── lib/
│       ├── constants/
│       │   └── api_endpoints.dart    # ✅ baseUrl = production Workers URL
│       ├── core/
│       │   ├── api/                  # ✅ S3ApiClient (Dio+JWT+envelope)
│       │   ├── auth/                 # ✅ auth_provider + user_provider
│       │   └── models/              # ✅ Job, Preset, Rule (Freezed)
│       ├── routing/
│       │   └── app_router.dart      # ✅ 8개 라우트 + auth guard
│       └── features/
│           ├── workspace/           # ✅ 메인 작업 화면 (SNOW 스타일)
│           ├── auth/                # ✅ AuthScreen (auto anon login)
│           ├── splash/              # ✅ SplashScreen
│           ├── domain_select/       # ✅ 프리셋 선택
│           ├── palette/             # ✅ concept 선택
│           ├── upload/              # ✅ 업로드 화면
│           ├── rules/               # ✅ 룰 CRUD
│           ├── jobs/                # ✅ Job 진행률 (3초 polling)
│           ├── results/             # ✅ 결과 갤러리
│           ├── history/             # ✅ 히스토리
│           ├── pricing/             # ✅ 플랜 비교
│           └── settings/            # ✅ 설정
│
├── docs/                      # 문서
│   ├── project-structure.md   # 전체 폴더 구조 가이드
│   ├── cloudflare-resources.md # CF 리소스 현황
│   └── wrangler-vs-do.md      # Workers vs DO 차이
│
├── team/                      # 팀원별 가이드
│   ├── MEMBER-A-WORKERS-CORE.md
│   ├── MEMBER-B-WORKERS-DO.md
│   ├── MEMBER-C-GPU.md
│   └── MEMBER-D-FRONTEND.md
│
└── clone/Auto-Claude/         # 24/7 자동 빌드 시스템
```

---

## Cloudflare Resources (Live)

| Resource | Name/ID | URL/Status |
|----------|---------|------------|
| Workers | `s3-workers` | `https://s3-workers.clickaround8.workers.dev` |
| D1 | `s3-db` | ID: `9e2d53af-ba37-4128-9ef8-0476ace30efa` |
| R2 | `s3-images` | Bucket 존재 |
| Queue | `gpu-jobs` + `gpu-jobs-dlq` | Configured, max_batch=10, retries=3 |
| DO | UserLimiterDO, JobCoordinatorDO | Auto-created on deploy |
| Account | Clickaround8@gmail.com | `2c1b8299e2d8cec3f82a016fa88368aa` |
| Cost | **$0/month** | Cloudflare Free Plan |

---

## Next Steps (Priority Order)

### P1 — GPU Worker 배포

1. Docker build → registry push
2. Runpod Serverless endpoint 생성
3. R2 API Token 생성 (Dashboard)
4. 환경변수 설정 (HF_TOKEN, R2 credentials, GPU_CALLBACK_SECRET)

### P2 — Workers 재배포

Jobs 구현 포함 최신 코드 배포:
```bash
cd workers && npx wrangler deploy
```

### P3 — E2E 통합 테스트

Auth → Preset → Upload → Execute → GPU → Callback → Results

---

## For AI Agents

**반드시 읽어야 할 파일:**
1. `workflow.md` — API 스키마, 데이터 모델, 전체 설계 (SSoT)
2. 이 `README.md` — 현재 뭐가 되고 안 되는지
3. `CLAUDE.md` — 코딩 규칙, MCP 도구, 디렉토리 구조

**작업 전 확인:**
- Workers 수정 시: `workers/src/_shared/types.ts` (Env 바인딩 타입)
- DO 호출 시: `UserLimiterDO.ts`, `JobCoordinatorDO.ts` (RPC 메서드 시그니처)
- Frontend API 시: `api_client.dart` (인터페이스) → `s3_api_client.dart` (구현)
- 모델 수정 시: `workflow.md` 섹션 5~6 (D1 스키마 + API 응답)

**폴더별 상세 README:**
- `workers/README.md` — Workers API 14개 엔드포인트 + DO + D1 + R2 + Queue
- `gpu-worker/README.md` — SAM3 파이프라인 + Runpod + Docker
- `frontend/README.md` — Flutter 아키텍처 + Riverpod + GoRouter

---

## Dev Commands

```bash
# Workers (로컬 실행)
cd workers && npx wrangler dev

# Workers (배포)
cd workers && npx wrangler deploy

# Workers (타입 체크)
cd workers && npx tsc --noEmit

# Frontend (의존성 + 코드 생성)
cd frontend && flutter pub get
cd frontend && dart run build_runner build --delete-conflicting-outputs

# Frontend (분석 + 실행)
cd frontend && flutter analyze
cd frontend && flutter run

# GPU Worker (Docker 빌드)
cd gpu-worker && docker build -t s3-gpu .

# GPU Worker (테스트)
cd gpu-worker && pytest
```

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Frontend | Flutter 3.38.9, Riverpod 3, Freezed 3, GoRouter, ShadcnUI |
| Workers | Hono 4.7, CF Workers, D1(SQLite), R2, Durable Objects, Queues |
| GPU | Python 3.12, PyTorch 2.7+, SAM3, Docker, Runpod Serverless |
| Infra | Cloudflare Free Plan ($0), Runpod (GPU) |
| Automation | Auto-Claude daemon + 6 custom agents |
