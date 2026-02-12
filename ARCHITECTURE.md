# S3 Architecture — 도메인 팔레트 엔진 기반 세트 생산 앱

> v3.0 (2026-02-11) — `workflow.md`가 SSoT. 이 문서는 아키텍처 심화 참조.

---

## 설계 원칙: n8n 모듈 패턴

모든 계층과 에이전트는 **n8n 노드** 패턴을 따른다:

```
┌─────────────────────────────────────┐
│  Module (= n8n Node)                │
│                                     │
│  Input  → [ 자체 로직 ] → Output    │
│                                     │
│  ■ 경계 명확 (다른 모듈 직접 import 금지) │
│  ■ 통신은 HTTP / Queue / Callback   │
│  ■ 독립 배포 + 독립 테스트 가능       │
│  ■ 실패해도 다른 모듈에 전파 안 됨     │
└─────────────────────────────────────┘
```

| 원칙 | 설명 |
|------|------|
| **단일 책임** | 각 모듈은 하나의 역할만. Workers=입구, DO=상태, GPU=추론 |
| **명확한 I/O** | JSON schema로 정의된 입출력. 암묵적 의존 금지 |
| **독립 배포** | Workers/GPU Worker 각각 독립적으로 배포 가능 |
| **실패 격리** | GPU Worker 다운 → Workers는 Queue에 남아있는 메시지로 재시도. 전체 시스템 안 죽음 |
| **교체 가능** | adapter 패턴으로 GPU 플랫폼 교체 (Runpod ↔ Vast ↔ 자체서버) |

---

## 시스템 아키텍처: 입구 — 뇌 — 근육

```
┌──────────────┐      ┌─────────────────────────────────┐      ┌──────────────────┐
│   Flutter    │─────▶│  Cloudflare                     │─────▶│  Runpod GPU      │
│   App        │◀─────│  Workers (입구) + DO (뇌)       │◀─────│  Docker Worker   │
│              │      │  + Queues + R2 + D1             │      │  (근육)          │
└──────────────┘      └─────────────────────────────────┘      └──────────────────┘
```

### 모듈 분해 (n8n Node View)

```
┌─────────┐    HTTP     ┌──────────┐   DO call   ┌──────────────┐
│ Flutter │───────────▶│ Workers  │───────────▶│ UserLimiter  │
│  (UI)   │◀───────────│ (입구)   │◀───────────│  DO (뇌)     │
└─────────┘   JSON      │          │             └──────────────┘
                        │          │   DO call   ┌──────────────┐
                        │          │───────────▶│ JobCoordinator│
                        │          │◀───────────│  DO (뇌)     │
                        └────┬─────┘             └──────┬───────┘
                             │                          │
                     R2 presigned              Queue push│
                             │                          │
                        ┌────▼─────┐             ┌──────▼───────┐
                        │   R2     │◀────────────│ GPU Worker   │
                        │ (저장소) │  S3 API     │  (근육)      │
                        └──────────┘             └──────┬───────┘
                                                        │
                        ┌──────────┐             HTTP callback
                        │   D1     │◀──── flush ────────┘
                        │ (영속DB) │
                        └──────────┘
```

---

## 계층별 모듈 상세

### Module 1: Workers (입구)

| 속성 | 값 |
|------|---|
| **역할** | HTTP API 서버 — 인증, 요청 검증, CRUD, presigned URL, DO 호출, Queue push |
| **기술** | Hono + Cloudflare Workers (TypeScript) |
| **Input** | Flutter HTTP 요청 (Authorization: Bearer JWT) |
| **Output** | JSON Response Envelope `{ success, data, error, meta }` |
| **바인딩** | D1 (DB), R2 (스토리지), DO (UserLimiter, JobCoordinator), Queue (gpu-jobs) |
| **배포** | `npx wrangler deploy` |

**내부 구조 (n8n sub-node):**

```
workers/src/
├── index.ts              # Hono app entry → route mount
├── routes/               # 각 route = 독립 Hono instance
│   ├── auth.ts           # POST /auth/anon
│   ├── presets.ts        # GET /presets, GET /presets/{id}
│   ├── rules.ts          # CRUD /rules
│   └── jobs.ts           # POST /jobs, execute, confirm, callback, cancel
├── do/                   # Durable Objects
│   ├── UserLimiterDO.ts  # 크레딧, 동시성, 룰 슬롯
│   └── JobCoordinatorDO.ts # Job 상태머신, 멱등성
├── middleware/            # auth JWT, error handler
├── services/             # D1 queries, R2 presigned
└── utils/                # response envelope
```

**14 API 엔드포인트:**

| # | Method | Path | 처리 주체 |
|---|--------|------|----------|
| 1 | POST | `/auth/anon` | Workers → D1 |
| 2 | GET | `/me` | UserLimiterDO |
| 3-4 | GET | `/presets`, `/presets/{id}` | Workers (하드코딩) |
| 5-8 | CRUD | `/rules` | D1 + UserLimiterDO |
| 9-14 | POST/GET | `/jobs/*` | JobCoordinatorDO → Queue → R2 |

### Module 2: Durable Objects (뇌)

| 속성 | 값 |
|------|---|
| **역할** | 실시간 상태 관리 + 동시성 제어 + 멱등성 |
| **기술** | Cloudflare Durable Objects |
| **Input** | Workers 내부 DO 호출 (RPC) |
| **Output** | 상태 변경 + Workers 응답 |

**UserLimiterDO (유저당 1개):**

```
┌──────────────────────────────┐
│ Input:  checkCredits(cost)   │
│         reserve(job_id)      │
│         release(job_id)      │
│                              │
│ State:  credits, active_jobs,│
│         rule_slots_used      │
│                              │
│ Output: { allowed, reason }  │
│         { credits_remaining }│
└──────────────────────────────┘
```

**JobCoordinatorDO (job당 1개):**

```
┌──────────────────────────────────┐
│ Input:  create(preset, items)    │
│         confirmUpload()          │
│         execute(concepts, protect)│
│         callback(idx, status)    │
│         cancel()                 │
│                                  │
│ State:  status (상태머신),        │
│         items Map, done/failed,  │
│         seen_idempotency_keys    │
│                                  │
│ Output: { status, progress }     │
│         Queue message (execute)  │
│         D1 flush (완료 시)        │
└──────────────────────────────────┘

상태머신:
created → uploaded → queued → running → done
                                    ↘ failed
         (any) → canceled
```

### Module 3: GPU Worker (근육)

| 속성 | 값 |
|------|---|
| **역할** | SAM3 세그멘테이션 + 룰 적용 (추론 전용) |
| **기술** | Python 3.12 + PyTorch 2.7+ + SAM3 + Docker |
| **Input** | Queue 메시지 (JSON) or Runpod event |
| **Output** | R2 업로드 (결과) + Workers callback (HTTP) |
| **배포** | Docker image → Runpod Serverless |

**내부 구조 (n8n sub-node):**

```
gpu-worker/
├── engine/               # 플랫폼 독립 코어 (n8n pure logic)
│   ├── pipeline.py       # 전체 파이프라인 오케스트레이션
│   ├── segmenter.py      # SAM3 wrapper: concept → masks
│   ├── applier.py        # Rule apply: masks + params → result
│   ├── r2_io.py          # R2 업/다운로드 (boto3, S3 호환)
│   ├── callback.py       # Workers callback 보고
│   └── idempotency.py    # 중복 처리 방지
├── adapters/             # 플랫폼별 어댑터 (교체 지점)
│   ├── runpod_serverless.py  # Runpod handler (MVP)
│   ├── queue_pull.py         # Vast/Pod용 polling
│   └── http_trigger.py       # HTTP trigger (옵션)
├── presets/              # 도메인별 concept 매핑
│   ├── interior.py
│   └── seller.py
├── Dockerfile            # 2단 빌드 (base CUDA + app)
└── main.py               # 진입점
```

**2단계 추론 파이프라인:**

```
Input Image
    │
    ▼
┌─────────────────────────────────────────┐
│  Phase A: SAM3 Segment (GPU 필수)       │
│  concept text → SAM3 → N개 인스턴스 마스크 │
│  protect concepts → protect 마스크들      │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│  Phase B: Rule Apply (CPU/GPU)          │
│  원본 + 마스크 + protect + rule params   │
│  → 영역별 변환 → 결과 이미지              │
└─────────────────────────────────────────┘
    │
    ▼
R2 Upload → Callback → Workers
```

**GPU 플랫폼 교체 (adapter 패턴):**

```
engine/ (동일) + adapters/runpod.py   → Runpod Serverless
engine/ (동일) + adapters/vast.py     → Vast.ai Pod
engine/ (동일) + adapters/local.py    → 자체 GPU 서버
```

### Module 4: Flutter App (UI)

| 속성 | 값 |
|------|---|
| **역할** | 사용자 인터페이스 — 팔레트 선택, 이미지 업로드, 결과 표시 |
| **기술** | Flutter 3.38.9 + Riverpod 3 + ShadcnUI + Freezed 3 + GoRouter |
| **Input** | 사용자 터치/입력 |
| **Output** | Workers API HTTP 요청 |

**내부 구조 (Feature-First):**

```
frontend/lib/
├── core/                   # 공통 인프라
│   ├── api/api_client.dart # Dio + JWT interceptor
│   ├── auth/               # Auth provider + service
│   ├── router/             # GoRouter + auth guard
│   └── storage/            # flutter_secure_storage
├── features/               # n8n 노드 = feature 모듈
│   ├── auth/               # 인증 (anon JWT)
│   ├── domain_select/      # 도메인 선택 (건축/셀러)
│   ├── palette/            # 팔레트 + 보호 토글
│   ├── upload/             # 이미지 업로드 (presigned URL → R2)
│   ├── rules/              # 룰 CRUD
│   ├── jobs/               # Job 실행 + polling 진행률
│   ├── results/            # 결과 표시 + Before/After
│   ├── compare/            # 시안 비교 (다른 룰 적용)
│   └── export/             # 세트 내보내기 (템플릿)
└── shared/                 # 공통 위젯, 유틸
```

### Module 5: 스토리지 (D1 + R2)

**D1 (영속 기록 — 5개 테이블):**

| 테이블 | 용도 |
|--------|------|
| `users` | 유저 프로필 + 플랜 + 크레딧 |
| `rules` | 룰 저장 (user_id, preset_id, concepts_json, protect_json) |
| `jobs_log` | Job 히스토리 |
| `job_items_log` | Item 히스토리 |
| `billing_events` | 정산 이벤트 |

**R2 (이미지 저장 — S3 호환):**

```
inputs/{userId}/{jobId}/{idx}.jpg           # 원본
outputs/{userId}/{jobId}/{idx}_result.png    # 결과
masks/{userId}/{jobId}/{idx}_{concept}.png   # 마스크
previews/{userId}/{jobId}/{idx}_thumb.jpg    # 미리보기
```

---

## 모듈 간 통신 맵

```
Flutter ──HTTP──▶ Workers ──DO RPC──▶ UserLimiterDO
                                   ──▶ JobCoordinatorDO
                 Workers ──presigned──▶ R2 (Flutter가 직접 PUT)
          JobCoordinatorDO ──Queue──▶ GPU Worker
          GPU Worker ──S3 API──▶ R2
          GPU Worker ──HTTP callback──▶ Workers → JobCoordinatorDO
          JobCoordinatorDO ──flush──▶ D1
```

| 통신 | 프로토콜 | 인증 |
|------|----------|------|
| Flutter → Workers | HTTPS REST | JWT (HS256) |
| Workers → DO | Internal RPC | N/A (같은 Worker) |
| Workers → D1 | Binding | N/A (같은 Worker) |
| Workers → R2 | Binding | N/A (같은 Worker) |
| Workers → Queue | Binding | N/A (같은 Worker) |
| Flutter → R2 | HTTPS PUT | presigned URL (시간 제한) |
| Queue → GPU Worker | Queue consume / Runpod event | N/A (플랫폼 내부) |
| GPU Worker → R2 | S3 API (boto3) | Access Key |
| GPU Worker → Workers | HTTPS POST callback | `GPU_CALLBACK_SECRET` |

---

## 데이터 흐름 (전체)

```
 1. Flutter → POST /auth/anon → JWT 획득
 2. Flutter → GET /presets/interior → concepts/protect 로드
 3. Flutter → POST /jobs { preset, item_count }
    Workers → UserLimiterDO.checkCredits() → JobCoordinatorDO.create()
    → presigned URLs + job_id 반환
 4. Flutter → R2 직접 업로드 (N장, presigned PUT)
 5. Flutter → POST /jobs/{id}/confirm-upload
    → JobCoordinatorDO.markUploaded()
 6. [Flutter 로컬: concept 선택, protect 설정, 룰 구성]
 7. Flutter → POST /jobs/{id}/execute { concepts, protect, rule_id? }
    → JobCoordinatorDO.markQueued() → Queue push
 8. GPU Worker: R2 다운로드 → SAM3 segment → rule apply → R2 업로드
 9. GPU Worker → POST /jobs/{id}/callback (item별)
    → JobCoordinatorDO.onCallback()
10. 전체 완료 → UserLimiterDO.release() + D1 flush
11. Flutter → GET /jobs/{id} (polling 3초) → 결과 표시
```

---

## 인증 (MVP: anon JWT)

```
┌──────────┐         ┌──────────┐         ┌──────┐
│ Flutter  │─ POST ─▶│ Workers  │─ INSERT ▶│  D1  │
│          │  /auth/ │          │         │      │
│          │  anon   │ HS256    │         │ users│
│          │◀─ JWT ──│ sign()   │         │      │
└──────────┘         └──────────┘         └──────┘

이후 모든 요청:
Authorization: Bearer <JWT>
Workers middleware → JWT 검증 → sub=user_id 추출
```

---

## GPU 이동성 (adapter 패턴)

```
                    ┌─────────────────┐
                    │   engine/       │  ← 플랫폼 독립 (불변)
                    │   pipeline.py   │
                    │   segmenter.py  │
                    │   applier.py    │
                    │   r2_io.py      │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
     ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
     │  Runpod     │ │  Vast.ai    │ │  자체서버    │
     │  adapter    │ │  adapter    │ │  adapter    │
     │  (MVP)      │ │  (옵션)     │ │  (옵션)     │
     └─────────────┘ └─────────────┘ └─────────────┘

교체 시 변경: adapters/ 파일 1개만
engine/ 코드: 변경 없음
```

---

## MCP 도구 (모든 에이전트 필수)

> 코드 작성 전 문서 조회, 배포 후 로그 확인 필수.

### 필수 MCP (모든 에이전트)

| MCP 서버 | 도구 | 용도 |
|----------|------|------|
| **cloudflare-observability** | `query_worker_observability`, `search_cloudflare_documentation`, `workers_list`, `workers_get_worker_code` | Workers 로그, D1/R2/DO 디버깅, CF 공식 문서 |
| **context7** | `resolve-library-id` → `query-docs` | Hono, CF Workers, Flutter, Riverpod 등 최신 문서 |

### 필수 MCP (GPU 에이전트)

| MCP 서버 | 도구 | 용도 |
|----------|------|------|
| **runpod** | `create-pod`, `list-endpoints`, `create-endpoint`, `list-templates` 등 26개 | GPU Pod/Endpoint/Template 관리, Serverless 배포 |

### 필수 MCP (Frontend 에이전트)

| MCP 서버 | 도구 | 용도 |
|----------|------|------|
| **dart** | 코드 분석, 테스트, pub.dev 검색, API 문서 | 공식 Dart MCP (Dart SDK 3.9+ 내장) |
| **flutter-docs** | `flutter_search`, `flutter_docs` | Flutter/Dart 문서 + pub.dev 50,000+ 패키지 |

### 선택 MCP

| MCP 서버 | 용도 |
|----------|------|
| **marionette** | Flutter 앱 실시간 제어 (위젯 탭, 스크린샷, hot reload) |
| **playwright** | 브라우저 UI 테스트 |
| **e2b** | Python 코드 실행 샌드박스 |
| **brave-search** | 웹 검색 |
| **github** | 이슈/PR 관리 |

### 에이전트별 MCP 매핑

| 에이전트 | 필수 MCP | 추가 MCP |
|----------|----------|----------|
| `s3_edge_api` | CF, context7 | playwright, brave-search |
| `s3_backend_inference` | CF, context7, **runpod** | e2b, brave-search |
| `s3_supabase` | CF, context7 | — |
| `s3_frontend_auth` | CF, context7, **dart**, **flutter-docs** | playwright, marionette |
| `s3_frontend_segmentation` | CF, context7, **dart**, **flutter-docs** | playwright, marionette |
| `s3_frontend_gallery` | CF, context7, **dart**, **flutter-docs** | playwright, marionette |

---

## Auto-Claude 자동화 (n8n 워크플로우)

### 에이전트 = n8n 노드

각 커스텀 에이전트는 독립 n8n 노드:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ s3_edge_api │     │s3_backend_  │     │s3_frontend_ │
│             │     │ inference   │     │ auth        │
│ Input:      │     │ Input:      │     │ Input:      │
│  spec.md    │     │  spec.md    │     │  spec.md    │
│ Output:     │     │ Output:     │     │ Output:     │
│  workers/   │     │  gpu-worker/│     │  frontend/  │
│  src/*.ts   │     │  engine/*.py│     │  lib/core/  │
│ Tools:      │     │ Tools:      │     │ Tools:      │
│  CF MCP     │     │  CF+Runpod  │     │  CF MCP     │
│  context7   │     │  MCP        │     │  context7   │
└─────────────┘     └─────────────┘     └─────────────┘
```

### Daemon 실행

```powershell
set PYTHONUTF8=1
python runners/daemon_runner.py --project-dir "C:\DK\S3" ^
  --status-file "C:\DK\S3\.auto-claude\daemon_status.json"
```

### Task 생성

```powershell
python runners/spec_runner.py --task "작업 설명" --project-dir "C:\DK\S3" --no-build
```

### 파이프라인

```
spec_runner (--no-build) → spec 생성 (status: "queue")
→ daemon 감지 → executor 실행 → planner → coder → QA → merge
→ daemon_status.json 갱신 → UI Kanban 카드 이동
```

---

## 디렉토리 구조

### 현재 (전환 전)

```
S3/
├── CLAUDE.md               ← Agent 마스터 가이드
├── ARCHITECTURE.md         ← 지금 이 파일
├── workflow.md             ← SSoT (아키텍처, API, 데이터 모델)
├── frontend/               ← Flutter App (~30%)
├── edge/                   ← Hono Workers (전환 대상 → workers/)
├── cf-backend/             ← FastAPI scaffolding (전환 대상 → gpu-worker/)
├── supabase/               ← Supabase 마이그레이션 (삭제 대상)
├── ai-backend/             ← 모델 스크립트 (통합 대상 → gpu-worker/engine/)
├── clone/Auto-Claude/      ← 자동 빌드 시스템
└── .auto-claude/           ← specs, daemon_status.json
```

### 전환 후 목표

```
S3/
├── CLAUDE.md
├── ARCHITECTURE.md
├── workflow.md
├── workers/                ← Hono + CF Workers + D1 + DO + Queues + R2
│   ├── src/
│   │   ├── index.ts
│   │   ├── routes/         # auth, presets, rules, jobs
│   │   ├── do/             # UserLimiterDO, JobCoordinatorDO
│   │   ├── middleware/
│   │   ├── services/
│   │   └── utils/
│   └── wrangler.toml
├── gpu-worker/             ← Docker + SAM3 + Runpod
│   ├── engine/             # 플랫폼 독립 코어
│   ├── adapters/           # Runpod/Vast/자체서버
│   ├── presets/            # 도메인 concept 매핑
│   └── Dockerfile
├── frontend/               ← Flutter 3.38.9 + Riverpod 3 + ShadcnUI
│   └── lib/
│       ├── core/           # api client, auth, router
│       ├── features/       # feature-first 모듈들
│       └── shared/         # 공통 위젯
└── clone/Auto-Claude/      ← 자동 빌드 + 커스텀 에이전트 6개
```

---

## 환경변수

### Workers (`workers/.dev.vars`)

```
JWT_SECRET=                  # HS256 서명키
GPU_CALLBACK_SECRET=         # GPU Worker 콜백 인증
```

> D1, R2, DO, Queue 바인딩 → `wrangler.toml`

### GPU Worker (`gpu-worker/.env`)

```
STORAGE_S3_ENDPOINT=         # R2 endpoint
STORAGE_ACCESS_KEY=
STORAGE_SECRET_KEY=
STORAGE_BUCKET=s3-images
BATCH_CONCURRENCY=4
MODEL_CACHE_DIR=/models
CALLBACK_TIMEOUT_SEC=10
RUNPOD_API_KEY=              # Runpod Serverless 관리
```

### Frontend (`frontend/lib/core/constants.dart`)

```dart
const baseUrl = 'https://s3-api.your-domain.workers.dev';
```

---

## GPU 요구사항

| 항목 | 최소 | 권장 |
|------|------|------|
| GPU VRAM | 16 GB (RTX 4090) | 24+ GB (A100/H100) |
| CUDA | 12.1+ | 12.6+ |
| Python | 3.12+ | 3.12+ |
| PyTorch | 2.7+ | 2.7+ |

SAM3: 848M params, 가중치 3.4GB, 추론 ~30ms/image (H200)

---

## 핵심 설계 결정

### 1. Supabase 제거 → D1 + DO

| 이전 | 이후 | 이유 |
|------|------|------|
| Supabase Auth | Workers JWT (HS256) | 외부 의존 제거, 콜드스타트 없음 |
| Supabase DB | D1 (SQLite) | Workers 바인딩으로 직접 쿼리, 0ms latency |
| Supabase Realtime | DO 상태 + polling (MVP) | DO가 이미 상태 관리, 별도 Realtime 불필요 |

### 2. Queue 기반 비동기 처리

```
Workers → Queue push (즉시 응답) → GPU Worker (비동기 소비)
→ callback (item별 완료 보고) → DO 상태 갱신
```

- GPU Worker 다운 → Queue에 메시지 남아있음 → 재시작 시 자동 재처리
- 여러 GPU Worker → Queue가 자동 분산

### 3. DO = Source of Truth (실시간), D1 = 영속 기록

| | DO | D1 |
|--|----|----|
| **목적** | 실시간 상태/동시성 | 히스토리/분석 |
| **쓰기 빈도** | 매 요청 | Job 완료 시 flush |
| **읽기 빈도** | 매 요청 | 대시보드/분석 |
| **TTL** | 세션 기반 (10분 idle) | 영구 |

### 4. Presigned URL 직접 업로드

```
Flutter → Workers (presigned URL 요청)
Workers → R2 presigned URL 생성 → Flutter에 반환
Flutter → R2 직접 PUT (Workers 우회) → 대용량 이미지 효율적 전송
```

---

## 문서 인덱스

| 문서 | 역할 |
|------|------|
| `workflow.md` | **SSoT** — 제품 비전, 아키텍처, API, 데이터 모델, 로드맵 |
| `CLAUDE.md` | Agent 마스터 가이드 — 명령어, 규칙, MCP 도구, Auto-Claude |
| `ARCHITECTURE.md` | 아키텍처 심화 — 모듈 설계, 통신 맵, 설계 결정 (이 파일) |
| `docs/contracts/api-contracts.md` | API 요약 (SSoT는 workflow.md) |
