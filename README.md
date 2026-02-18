# S3 — Domain Palette Engine

> 도메인 구성요소를 잡고, 규칙으로 세트를 찍어내는 앱
> SAM3(Meta, 2025.11) 기반 — Concept → Instance → Protect → Rule → Output Set

---

## 연결 상태 (2026-02-18, 버그 수정 배포 완료)

```
┌──────────────┐      ┌─────────────────────────────────┐      ┌──────────────────┐
│   Flutter    │─ ✓ ──│  Cloudflare                     │─ ✗ ──│  GPU Worker      │
│   App        │      │  Workers + DO + D1 + R2         │      │  (Runpod)        │
│ (S3ApiClient)│      │  (배포됨, Jobs stub)             │      │  (코드만 완성)    │
└──────────────┘      └─────────────────────────────────┘      └──────────────────┘
```

### 한눈에 보는 현황

| 구간 | 상태 | 비고 |
|------|------|------|
| Flutter → Workers | **연결됨** | S3ApiClient + JWT + envelope unwrap |
| Auth (anon JWT) | **연결됨** | POST /auth/anon → token → SecureStorage |
| Workers Auth/Presets/Rules/Me | **작동** | 9개 엔드포인트 정상 (DO init 버그 수정 완료) |
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
| `POST /jobs` | **빈 stub** | — |
| `POST /jobs/:id/confirm-upload` | **빈 stub** | — |
| `POST /jobs/:id/execute` | **빈 stub** | — |
| `GET /jobs/:id` | **빈 stub** | — |
| `POST /jobs/:id/callback` | **빈 stub** | — |
| `POST /jobs/:id/cancel` | **빈 stub** | — |

---

## Frontend ↔ Workers 연결 상세

### Auth Flow (작동)

```
1. App 실행 → /splash (2초 애니메이션)
2. SecureStorage에 token 있으면 → /domain-select
3. token 없으면 → /auth (AuthScreen)
4. AuthScreen → authProvider.login() → POST /auth/anon
5. Workers → D1 user 생성 → JWT 발급 → { user_id, token, plan, is_new }
6. S3ApiClient envelope unwrap → LoginResponse.fromJson()
7. token을 SecureStorage에 저장 (key: 'accessToken')
8. authProvider state 변경 → GoRouter redirect → /domain-select
9. 이후 모든 요청: Authorization: Bearer <JWT>
```

### API Client 구조

```
apiClientProvider (@riverpod)
  └─ S3ApiClient (Dio)
       ├─ baseUrl: ApiEndpoints.baseUrl (production Workers URL)
       ├─ Interceptor 1: FlutterSecureStorage → Bearer token 주입
       └─ Interceptor 2: { success, data } envelope unwrap
```

### Router (GoRouter + Auth Guard)

```
/splash         → SplashScreen (initial, no guard)
/auth           → AuthScreen (auto anon login)
/domain-select  → DomainSelectScreen
/palette        → PaletteScreen (?presetId=)
/upload         → UploadScreen (?presetId=&concepts=&protect=)
/rules          → RulesScreen (?jobId=)
/jobs/:id       → JobProgressScreen
```

Guard: 미인증 → /auth, 인증+/auth → /domain-select

### Data Models (Workers 응답과 일치)

```dart
// POST /auth/anon → LoginResponse
{ user_id, token, plan, is_new }

// GET /me → User
{ user_id, plan, credits, rule_slots, concurrent_jobs }
```

---

## Data Flow (목표 vs 현재)

```
Step  Flow                             현재
────  ───────────────────────────────  ──────
 1    Flutter → POST /auth/anon        ✓ 연결됨 (JWT 발급 → 저장)
 2    Flutter → GET /presets/:id       ✓ 연결됨 (프리셋 로드)
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
│   │   ├── jobs/              # ❌ 6개 stub
│   │   ├── do/                # ✅ 완전 구현 (UserLimiter, JobCoordinator)
│   │   ├── middleware/        # ✅ JWT 검증
│   │   └── _shared/          # 타입, response helper, R2 helper
│   ├── migrations/
│   │   └── 0001_init_schema.sql
│   └── wrangler.toml
│
├── gpu-worker/                # ── GPU Worker (Python + Docker) ──
│   ├── engine/                # ✅ SAM3 pipeline (미배포)
│   ├── adapters/              # ✅ Runpod Serverless adapter
│   ├── Dockerfile
│   └── main.py
│
├── frontend/                  # ── Flutter App ──
│   └── lib/
│       ├── constants/
│       │   └── api_endpoints.dart    # ✅ baseUrl = production Workers URL
│       ├── core/
│       │   ├── api/
│       │   │   ├── api_client.dart          # ✅ 인터페이스 14개 메서드
│       │   │   ├── s3_api_client.dart       # ✅ 실제 구현 (Dio+JWT+envelope)
│       │   │   ├── mock_api_client.dart     # ✅ Mock (테스트용)
│       │   │   └── api_client_provider.dart # ✅ S3ApiClient() 사용
│       │   ├── auth/
│       │   │   ├── auth_provider.dart       # ✅ POST /auth/anon → JWT 저장
│       │   │   └── user_provider.dart       # ✅ GET /me → User
│       │   └── models/                      # ✅ Job, Preset, Rule (Freezed)
│       ├── routing/
│       │   └── app_router.dart    # ✅ 8개 라우트 + auth guard
│       └── features/
│           ├── auth/              # ✅ AuthScreen (auto anon login)
│           ├── splash/            # ✅ SplashScreen (auth check → redirect)
│           ├── domain_select/     # ✅ 프리셋 선택
│           ├── palette/           # ✅ concept 선택
│           ├── upload/            # ✅ 업로드 화면
│           ├── rules/             # ✅ 룰 CRUD
│           ├── jobs/              # ✅ Job 진행률
│           ├── workspace/         # ✅ 메인 작업 화면
│           ├── results/           # ✅ 결과 표시
│           ├── history/           # ✅ 히스토리
│           ├── pricing/           # ✅ 플랜 비교
│           └── settings/          # ✅ 설정 + 로그아웃
│
├── docs/                      # 문서
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

### P1 — Jobs 6개 엔드포인트 구현

DO 클래스 이미 완성 → 라우트 핸들러만 작성:

```
POST /jobs           → validate → UserLimiterDO.reserve() → JobCoordinatorDO.create() → presigned URLs
POST /confirm-upload → JobCoordinatorDO.confirmUpload()
POST /execute        → validate → JobCoordinatorDO.markQueued() → Queue.send()
GET  /jobs/:id       → JobCoordinatorDO.getStatus() → presigned download URLs
POST /callback       → verify GPU_CALLBACK_SECRET → JobCoordinatorDO.onItemResult()
POST /cancel         → JobCoordinatorDO.cancel()
```

### P2 — GPU Worker 배포

1. Docker build → registry push
2. Runpod Serverless endpoint 생성
3. Queue consumer에서 GPU Worker HTTP 호출

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

**주의사항:**
- Frontend는 **S3ApiClient 사용** (production Workers와 직접 통신)
- Auth는 **자동 anon JWT** (FlutterSecureStorage에 저장)
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
