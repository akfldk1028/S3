# S3 — Domain Palette Engine

> 도메인 구성요소를 잡고, 규칙으로 세트를 찍어내는 앱
> SAM3(Meta, 2025.11) 기반 — Concept → Instance → Protect → Rule → Output Set

---

## 연결 상태 (2026-02-18)

```
┌──────────────┐      ┌─────────────────────────────────┐      ┌──────────────────┐
│   Flutter    │─ ✗ ──│  Cloudflare                     │─ ✗ ──│  GPU Worker      │
│   App        │      │  Workers + DO + D1 + R2         │      │  (Runpod)        │
│  (Mock만 사용)│      │  (배포됨, Jobs stub)             │      │  (코드만 완성)    │
└──────────────┘      └─────────────────────────────────┘      └──────────────────┘
```

### 한눈에 보는 현황

| 구간 | 상태 | 문제 |
|------|------|------|
| Flutter → Workers | **끊김** | `MockApiClient` 하드코딩, baseUrl이 `localhost:8787` |
| Workers Auth/Presets/Rules | **작동** | 8개 엔드포인트 정상 (health 포함) |
| Workers Jobs (6개) | **미구현** | 라우트 핸들러가 빈 stub |
| Workers → GPU Queue | **미구현** | Queue consumer가 log+ack만 |
| GPU Worker | **미배포** | 코드 23파일 완성, Runpod 미배포 |
| D1/R2/DO/Queues | **배포됨** | 인프라 전부 존재 |

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
   │SQLite│         │ gpu-jobs │     (미연결)
   └──────┘         └──────────┘
```

---

## 작동하는 것 vs 안 되는 것

### Workers API (`https://s3-workers.clickaround8.workers.dev`)

| Endpoint | 상태 | 처리 주체 |
|----------|------|----------|
| `GET /health` | **작동** | Workers |
| `POST /auth/anon` | **작동** | Workers → D1 |
| `GET /me` | **작동** | UserLimiterDO |
| `GET /presets` | **작동** | Workers (하드코딩) |
| `GET /presets/:id` | **작동** | Workers |
| `POST /rules` | **작동** | UserLimiterDO → D1 |
| `GET /rules` | **작동** | D1 |
| `PUT /rules/:id` | **작동** | D1 |
| `DELETE /rules/:id` | **작동** | D1 + UserLimiterDO |
| `POST /jobs` | **빈 stub** | — |
| `POST /jobs/:id/confirm-upload` | **빈 stub** | — |
| `POST /jobs/:id/execute` | **빈 stub** | — |
| `GET /jobs/:id` | **빈 stub** | — |
| `POST /jobs/:id/callback` | **빈 stub** | — |
| `POST /jobs/:id/cancel` | **빈 stub** | — |

### Durable Objects (완전 구현, 호출하는 라우트가 없을 뿐)

- **UserLimiterDO**: init, getUserState, reserve, commit, rollback, release, checkRuleSlot, increment/decrementRuleSlot
- **JobCoordinatorDO**: create, confirmUpload, markQueued, onItemResult (멱등성 ring buffer), getStatus, cancel, alarm (D1 flush)

### Flutter Frontend (UI 완성, 연결 끊김)

- **S3ApiClient** (Dio + JWT + envelope unwrap): 완전 구현
- **MockApiClient**: 완전 구현
- **WorkspaceScreen** + 10+ 위젯: 완전 구현
- **모든 Feature 화면**: domain, palette, upload, rules, results, history, settings

---

## 끊어진 연결 3개소 (이것만 고치면 작동)

### 1. Frontend → Workers 연결

```
파일: frontend/lib/constants/api_endpoints.dart  (Line 11)
현재: static const baseUrl = 'http://localhost:8787';
수정: static const baseUrl = 'https://s3-workers.clickaround8.workers.dev';

파일: frontend/lib/core/api/api_client_provider.dart  (Line 20)
현재: return MockApiClient();
수정: return S3ApiClient();
```

### 2. Auth Flow 미완성

```
파일: frontend/lib/core/auth/auth_provider.dart  (Lines 22-29)
현재: login()이 SecureStorage에서 읽기만 함 (POST /auth/anon 호출 안 함)
수정: apiClient.createAnonUser() 호출 → JWT 저장 → state 업데이트
```

### 3. Router에 Workspace 없음

```
파일: frontend/lib/routing/app_router.dart
현재: /splash, /, /login, /profile  (4개뿐)
수정: / → WorkspaceScreen, /auth → AuthScreen  (workspace를 메인으로)
```

---

## Data Flow (목표 vs 현재)

```
Step  Flow                             현재
────  ───────────────────────────────  ──────
 1    Flutter → POST /auth/anon        ✗ Mock (Workers는 작동함)
 2    Flutter → GET /presets/:id       ✗ Mock (Workers는 작동함)
 3    Flutter → POST /jobs             ✗ Workers stub
 4    Flutter → R2 PUT (presigned)     ✗ presigned URL 미생성
 5    Flutter → POST /confirm-upload   ✗ Workers stub
 6    User: concept/protect/rule 설정  ✓ 로컬 state
 7    Flutter → POST /execute          ✗ Workers stub
 8    Workers → Queue push             ✗ consumer stub
 9    GPU → SAM3 segment + apply       ✗ GPU 미배포
10    GPU → POST /callback             ✗ Workers stub + GPU 미배포
11    Flutter → GET /jobs/:id poll     ✗ Workers stub
12    Flutter → 결과 표시              ✓ UI 있음 (데이터 없음)
```

---

## Directory Structure

```
S3/
├── README.md                  ← 이 파일 (현황 + 연결 상태)
├── CLAUDE.md                  # Agent 코딩 규칙, MCP 도구, 아키텍처
├── workflow.md                # SSoT — API 스키마, 데이터 모델, 전체 설계
├── TODO.md                    # Phase A~E 실행 계획
│
├── workers/                   # ── Cloudflare Workers (Hono + TS) ──
│   ├── src/
│   │   ├── index.ts           # Entry: routes mount + queue consumer
│   │   ├── auth/              # ✅ POST /auth/anon — JWT 발급
│   │   │   ├── auth.route.ts
│   │   │   └── auth.service.ts
│   │   ├── presets/           # ✅ GET /presets, /presets/:id
│   │   │   ├── presets.route.ts
│   │   │   └── presets.data.ts  # interior(12개), seller(6개) 하드코딩
│   │   ├── rules/             # ✅ CRUD 4개
│   │   │   ├── rules.route.ts
│   │   │   ├── rules.service.ts # D1 queries
│   │   │   └── rules.validator.ts
│   │   ├── user/              # ✅ GET /me
│   │   │   └── user.route.ts
│   │   ├── jobs/              # ❌ 6개 stub
│   │   │   ├── jobs.route.ts  #   GET /jobs만 구현, 나머지 빈 주석
│   │   │   ├── jobs.service.ts#   generateUploadUrls → "Not implemented"
│   │   │   └── jobs.validator.ts# Zod 스키마는 정의됨 (사용 안 됨)
│   │   ├── do/                # ✅ 완전 구현 (호출하는 라우트가 없을 뿐)
│   │   │   ├── UserLimiterDO.ts
│   │   │   └── JobCoordinatorDO.ts
│   │   ├── middleware/        # ✅ JWT 검증
│   │   │   └── auth.middleware.ts
│   │   └── _shared/
│   │       ├── types.ts       # Env 바인딩, PLAN_LIMITS, 모든 타입
│   │       ├── response.ts    # ok(), error() envelope 헬퍼
│   │       └── r2.ts          # presigned URL 헬퍼 (존재하나 미사용)
│   ├── migrations/
│   │   └── 0001_init_schema.sql # D1 5 tables + 4 indexes
│   └── wrangler.toml          # D1/R2/DO/Queue 바인딩
│
├── gpu-worker/                # ── GPU Worker (Python + Docker) ──
│   ├── engine/                # ✅ 구현됨
│   │   ├── pipeline.py        # segment → apply → postprocess → upload
│   │   ├── segmenter.py       # SAM3 wrapper
│   │   ├── applier.py         # Rule apply
│   │   ├── r2_io.py           # S3/R2 업/다운로드
│   │   └── callback.py        # Workers 콜백
│   ├── adapters/              # ✅ Runpod Serverless adapter
│   ├── presets/               # ✅ 도메인별 concept 매핑
│   ├── Dockerfile             # ✅ 빌드 가능
│   └── main.py                # ✅ Entry point
│   # ⚠️ Runpod에 미배포
│
├── frontend/                  # ── Flutter App ──
│   └── lib/
│       ├── constants/
│       │   └── api_endpoints.dart    # ❌ baseUrl = localhost:8787
│       ├── core/
│       │   ├── api/
│       │   │   ├── api_client.dart          # ✅ 인터페이스 14개 메서드
│       │   │   ├── s3_api_client.dart       # ✅ 실제 구현 (Dio+JWT+envelope)
│       │   │   ├── mock_api_client.dart     # ✅ Mock 구현
│       │   │   └── api_client_provider.dart # ❌ MockApiClient() 하드코딩
│       │   ├── auth/
│       │   │   └── auth_provider.dart       # ❌ login() stub
│       │   └── models/                      # ✅ Job, Preset, Rule (Freezed)
│       ├── routing/
│       │   └── app_router.dart    # ❌ 4개 라우트만 (workspace 없음)
│       └── features/
│           ├── workspace/         # ✅ 단일페이지 UI (라우터에 미연결)
│           ├── palette/           # ✅ concept 선택
│           ├── rules/             # ✅ 룰 CRUD
│           ├── upload/            # ✅ 업로드 화면
│           ├── results/           # ✅ 결과 표시
│           ├── history/           # ✅ 히스토리
│           └── settings/          # ✅ 설정
│
├── docs/
│   ├── cloudflare-resources.md  # CF 리소스 ID/URL
│   ├── project-structure.md     # 폴더 구조 상세
│   └── wrangler-vs-do.md        # Workers vs DO 차이
│
├── team/                      # 팀원 역할 가이드
│   ├── README.md
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
| R2 | `s3-images` | Bucket 존재, 비어있음 |
| Queue | `gpu-jobs` + `gpu-jobs-dlq` | Configured, max_batch=10, retries=3 |
| DO | UserLimiterDO, JobCoordinatorDO | Auto-created on deploy |
| Account | Clickaround8@gmail.com | `2c1b8299e2d8cec3f82a016fa88368aa` |
| Cost | **$0/month** | Cloudflare Free Plan |

---

## Next Steps (Priority Order)

### P0 — Frontend ↔ Workers 연결 (30분)

1. `api_endpoints.dart` L11: baseUrl → `https://s3-workers.clickaround8.workers.dev`
2. `api_client_provider.dart` L20: `MockApiClient()` → `S3ApiClient()`
3. `auth_provider.dart`: login() → POST /auth/anon 호출 구현
4. `app_router.dart`: `/` → WorkspaceScreen 라우트 추가

### P1 — Jobs 6개 엔드포인트 구현 (2~4시간)

DO 클래스 이미 완성 → 라우트 핸들러만 작성하면 됨:

```
POST /jobs           → validate → UserLimiterDO.reserve() → JobCoordinatorDO.create() → presigned URLs
POST /confirm-upload → JobCoordinatorDO.confirmUpload()
POST /execute        → validate → JobCoordinatorDO.markQueued() → Queue.send()
GET  /jobs/:id       → JobCoordinatorDO.getStatus() → presigned download URLs
POST /callback       → verify GPU_CALLBACK_SECRET → JobCoordinatorDO.onItemResult()
POST /cancel         → JobCoordinatorDO.cancel()
```

### P2 — GPU Worker 배포 (1~2시간)

1. Docker build → registry push
2. Runpod Serverless endpoint 생성
3. Queue consumer에서 GPU Worker HTTP 호출

### P3 — E2E 테스트

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

**주의사항:**
- Frontend는 현재 **MockApiClient만 사용** (Workers와 통신 안 함)
- Jobs 6개 엔드포인트는 **빈 stub** (DO는 완성됨)
- R2 presigned URL 헬퍼는 **존재하나 호출되지 않음**
- Queue consumer는 **log+ack만** (GPU로 전달 안 함)

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
