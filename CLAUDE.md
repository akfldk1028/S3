# S3 — 도메인 팔레트 엔진 기반 세트 생산 앱

> **"지우는 앱"이 아니라 "도메인 구성요소를 잡고, 규칙으로 세트를 찍어내는 앱"**
>
> SAM3(Meta, 2025.11) 기반 — 컨셉(개념) → 전체 인스턴스 → 보호 → 룰 → 세트.
> 도메인 팔레트 + 인스턴스 리스트 + 보호 레이어 + 멀티샷 규칙 + 결과물 세트.

---

## 제품 5단 파이프라인 (모든 도메인 동일)

```
1. Palette    → 도메인 구성요소 버튼 (예: Wall/Floor/Tile/Grout)
2. Instances  → 동일 개념 다수 → #1~#N 카드 (체크/잠금/제외)
3. Protect    → 텍스트/로고/경계/하이라이트 등 "룰이 침범 못 하게" 고정
4. Rules      → 1회 설정 룰 → 앨범 전체 적용 (저장/재사용 = BM 핵심)
5. Output Sets → "1장"이 아니라 "패키지"로 내보내기 (템플릿)
```

**MVP 도메인**: 건축/인테리어, 쇼핑/셀러 | **Phase 2**: 프로필/브랜딩, 패션/OOTD

---

## 아키텍처: 입구 — 뇌 — 근육

```
┌──────────────┐      ┌─────────────────────────────────┐      ┌──────────────────┐
│   Flutter    │─────▶│  Cloudflare                     │─────▶│  Runpod GPU      │
│   App        │◀─────│  Workers (입구) + DO (뇌)       │◀─────│  Docker Worker   │
│              │      │  + Queues + R2 + D1             │      │  (근육)          │
└──────────────┘      └─────────────────────────────────┘      └──────────────────┘
```

| 계층 | 역할 | 기술 |
|------|------|------|
| **Workers (입구)** | 인증, 요청검증, presigned URL 발급, DO 호출, 프리셋/룰 CRUD | Hono + CF Workers |
| **DO (뇌)** | 상태머신, 동시성 제한, 크레딧 차감, 룰 슬롯 제한, 멱등성 | Durable Objects (UserLimiter, JobCoordinator) |
| **Queues** | GPU 작업 분산, 재시도 | CF Queues |
| **R2** | 원본/결과/마스크 이미지 저장 (S3 호환) | CF R2 |
| **D1** | 영속 기록 (유저, job, 룰, 프리셋, 정산) | CF D1 (SQLite) |
| **GPU Worker (근육)** | SAM3 segment + rule apply + R2 업로드 + 콜백 | Docker + Runpod Serverless |

> **Supabase 제거 완료** — D1 + DO로 Auth, DB, 동시성, 상태 관리 모두 처리.
> MVP: polling (3초). v2: DO WebSocket 실시간 진행률.

---

## Critical Rules

1. **`workflow.md`가 Single Source of Truth** — 아키텍처, API, 데이터 모델 모두 이 파일 기준
2. **레이어 간 직접 import 금지** — Workers ↔ GPU Worker는 Queue + HTTP callback으로만 통신
3. **환경변수에 시크릿 하드코딩 금지** — `.env.example`/`.dev.vars.example`만 커밋
4. **Frontend는 Workers API만 호출** — GPU Worker를 직접 호출하지 않음
5. **Workers = 유일한 API 서버** — 인증, CRUD, presigned URL, DO 호출, Queue push 모두 담당
6. **GPU Worker = 추론 전용** — SAM3 segment + rule apply만. Workers callback으로 결과 보고
7. **모델 가중치 커밋 금지** — `/models` 볼륨 마운트 or 런타임 다운로드
8. **DO = 실시간 상태, D1 = 영속 기록** — Source of Truth 분리
9. **MCP 도구 적극 활용** — Cloudflare MCP, context7, playwright 등 (아래 MCP 섹션 참조)

---

## API 엔드포인트 (14개)

> Base: `https://s3-api.{domain}.workers.dev`
> Auth: `Authorization: Bearer <JWT>` (Workers 자체 HS256 서명)
> Envelope: `{ success, data, error, meta: { request_id, timestamp } }`

| # | Method | Path | 설명 | 처리 주체 |
|---|--------|------|------|----------|
| 1 | POST | `/auth/anon` | 익명 유저 생성 + JWT | Workers → D1 |
| 2 | GET | `/me` | 유저 상태 (credits, plan, rule_slots) | UserLimiterDO |
| 3 | GET | `/presets` | 도메인 프리셋 목록 | Workers (하드코딩) |
| 4 | GET | `/presets/{id}` | 프리셋 상세 (concepts, protect, templates) | Workers |
| 5 | POST | `/rules` | 룰 저장 | UserLimiterDO → D1 |
| 6 | GET | `/rules` | 내 룰 목록 | D1 |
| 7 | PUT | `/rules/{id}` | 룰 수정 | D1 |
| 8 | DELETE | `/rules/{id}` | 룰 삭제 | D1 + UserLimiterDO |
| 9 | POST | `/jobs` | Job 생성 + presigned URLs | UserLimiterDO → JobCoordinatorDO → R2 |
| 10 | POST | `/jobs/{id}/confirm-upload` | 업로드 완료 확인 | JobCoordinatorDO |
| 11 | POST | `/jobs/{id}/execute` | 룰 적용 실행 (Queue push) | JobCoordinatorDO → Queue |
| 12 | GET | `/jobs/{id}` | 상태/진행률 조회 | JobCoordinatorDO |
| 13 | POST | `/jobs/{id}/callback` | GPU Worker 콜백 (내부) | JobCoordinatorDO |
| 14 | POST | `/jobs/{id}/cancel` | Job 취소 + 크레딧 환불 | JobCoordinatorDO → UserLimiterDO |

> 상세 Request/Response 스키마: `workflow.md` 섹션 6 참조

---

## 데이터 흐름

```
 1. User → Flutter → POST /auth/anon → JWT 획득 (최초 1회)
 2. User → 도메인 선택 → GET /presets/interior → concepts/protect 로드
 3. User → 사진 선택 → POST /jobs { preset, item_count } → presigned URLs + job_id
 4. Flutter → R2 직접 업로드 (N회) → POST /jobs/{id}/confirm-upload
 5. [User가 Flutter에서 concept 선택, protect 설정, 룰 구성 — 로컬 상태]
 6. User → "적용" → POST /jobs/{id}/execute { concepts, protect, rule_id? }
 7. Workers → JobCoordinatorDO.markQueued() → Queue push
 8. Runpod GPU Worker → R2에서 이미지 다운 → SAM3 segment → rule apply → 결과 R2 업로드
 9. GPU Worker → POST /jobs/{id}/callback (item별 완료 보고)
10. JobCoordinatorDO → 진행률 갱신, 전체 완료 시 UserLimiterDO.release() + D1 flush
11. Flutter → GET /jobs/{id} (polling 3초) → 결과 표시
```

---

## 데이터 모델

### DO: UserLimiter (유저당 1개)

```
user_id, plan (free|pro), credits, active_jobs,
max_concurrency (free=1, pro=3), rule_slots_used (free≤2, pro≤20)
```

### DO: JobCoordinator (job당 1개)

```
job_id, user_id, status (created|uploaded|queued|running|done|failed|canceled),
preset, concepts_json, protect_json, rule_id?, total_items, done_items, failed_items,
items: Map<idx, { status, input_key, output_key, error? }>,
seen_idempotency_keys: RingBuffer
```

### D1 테이블 (5개)

| 테이블 | 용도 |
|--------|------|
| `users` | 유저 (id, plan, credits, auth_provider, email, device_hash) |
| `rules` | 룰 저장 (user_id, name, preset_id, concepts_json, protect_json) |
| `jobs_log` | Job 히스토리 (user_id, status, preset, rule_id, cost_estimate) |
| `job_items_log` | Item 히스토리 (job_id, idx, status, input_key, output_key) |
| `billing_events` | 정산 (user_id, type, amount, ref) |

> DDL: `workflow.md` 섹션 5.3 참조

### R2 파일 키 규칙

```
inputs/{userId}/{jobId}/{idx}.jpg                   // 원본
outputs/{userId}/{jobId}/{idx}_result.png            // 최종 결과
masks/{userId}/{jobId}/{idx}_{concept}.png           // concept별 마스크
masks/{userId}/{jobId}/{idx}_instances.json          // 인스턴스 메타
previews/{userId}/{jobId}/{idx}_thumb.jpg            // 미리보기
```

---

## 인증 (MVP)

```
1. Flutter 최초 실행 → POST /auth/anon
2. Workers → D1에 user 생성 → JWT 서명 (HS256, Workers 환경변수 secret)
3. Flutter → 이후 모든 요청에 Authorization: Bearer <JWT>
4. Workers 미들웨어 → JWT 검증 → sub=user_id 추출
```

> v2: 소셜 로그인 (Google/Apple OAuth2 on Workers)

---

## 디렉토리 구조

### 현재 (전환 전)

```
S3/
├── CLAUDE.md               ← 지금 이 파일
├── workflow.md              ← SSoT (아키텍처, API, 데이터 모델)
├── frontend/                ← Flutter App (~30%)
├── edge/                    ← Hono Workers (Supabase 기반 — 전환 대상)
├── cf-backend/              ← FastAPI scaffolding (전환 대상)
├── ai-backend/              ← 모델 스크립트 (통합 대상)
├── supabase/                ← 마이그레이션 4개 (삭제 대상)
├── clone/Auto-Claude/       ← 자동 빌드 시스템
└── .auto-claude/            ← specs, daemon_status.json
```

### 전환 계획

| 현재 | 전환 후 | 액션 |
|------|---------|------|
| `edge/` | `workers/` | Hono 유지. Supabase → D1/DO로 교체. R2/response utils 재사용 |
| `cf-backend/` | `gpu-worker/` | FastAPI 제거 → Docker engine + adapter 패턴 재작성 |
| `ai-backend/` | `gpu-worker/engine/` | 모델 스크립트를 engine 하위로 통합 |
| `supabase/` | 삭제 | 스키마 참고하여 D1 DDL 작성 |
| `frontend/` | `frontend/` (유지) | API 호출부만 변경 (Supabase SDK → REST) |

### 전환 후 목표 구조

```
S3/
├── CLAUDE.md
├── workflow.md
├── workers/                 ← Hono + CF Workers + D1 + DO + Queues + R2
│   ├── src/
│   │   ├── index.ts         # Hono app entry
│   │   ├── routes/          # auth, presets, rules, jobs
│   │   ├── do/              # UserLimiterDO, JobCoordinatorDO
│   │   ├── middleware/      # JWT 검증, error handler
│   │   ├── services/        # D1 queries, R2 presigned
│   │   └── utils/           # response envelope, helpers
│   ├── wrangler.toml        # D1, R2, DO, Queue 바인딩
│   └── package.json
├── gpu-worker/              ← Docker + SAM3 + Runpod Serverless
│   ├── engine/
│   │   ├── pipeline.py      # segment → apply → postprocess → upload
│   │   ├── segmenter.py     # SAM3 wrapper
│   │   ├── applier.py       # Rule apply
│   │   ├── r2_io.py         # S3 호환 업/다운로드
│   │   └── callback.py      # Workers 콜백
│   ├── adapters/
│   │   ├── runpod_serverless.py  # MVP
│   │   └── queue_pull.py         # Vast/Pod용
│   ├── presets/             # 도메인별 concept 매핑
│   ├── Dockerfile
│   └── main.py
├── frontend/                ← Flutter 3.38.9 + Riverpod 3 + ShadcnUI
│   └── lib/
│       ├── features/        # auth, palette, jobs, gallery
│       ├── core/            # api client, models, router
│       └── shared/          # UI components, utils
└── clone/Auto-Claude/       ← 자동 빌드 시스템
```

---

## 환경변수

### Workers (`workers/.dev.vars`)

```
JWT_SECRET=                  # HS256 서명키
D1_DATABASE_ID=              # wrangler.toml에서도 설정
R2_BUCKET=s3-images
GPU_CALLBACK_SECRET=         # GPU Worker 콜백 인증
```

> D1, R2, DO, Queue 바인딩은 `wrangler.toml`에서 설정

### GPU Worker (`gpu-worker/.env`)

```
STORAGE_S3_ENDPOINT=         # R2 endpoint
STORAGE_ACCESS_KEY=
STORAGE_SECRET_KEY=
STORAGE_BUCKET=s3-images
BATCH_CONCURRENCY=4
MODEL_CACHE_DIR=/models
CALLBACK_TIMEOUT_SEC=10
LOG_LEVEL=info
```

### Frontend (`frontend/lib/core/constants.dart`)

```dart
const baseUrl = 'https://s3-api.your-domain.workers.dev';  // Workers URL (유일한 API)
```

> Supabase SDK 제거됨. 모든 통신은 Workers REST API를 통해.

---

## 개발 명령어

| 명령어 | 위치 | 설명 |
|--------|------|------|
| `npx wrangler dev` | `workers/` | Workers 로컬 실행 (D1/R2/DO 시뮬레이션) |
| `npx wrangler deploy` | `workers/` | Workers 배포 |
| `npx wrangler d1 execute DB --local --file=schema.sql` | `workers/` | D1 로컬 마이그레이션 |
| `npx tsc --noEmit` | `workers/` | TypeScript 타입 체크 |
| `docker build -t s3-gpu .` | `gpu-worker/` | GPU Worker 빌드 |
| `flutter run` | `frontend/` | Flutter 앱 실행 |
| `dart run build_runner build` | `frontend/` | Freezed/Riverpod 코드 생성 |
| `flutter analyze` | `frontend/` | Dart lint |
| `flutter test` | `frontend/` | Flutter 테스트 |

---

## GPU 요구사항

- **SAM3**: 848M params, 가중치 3.4GB, 추론 ~30ms/image (H200)
- **최소**: RTX 4090 (16GB VRAM), CUDA 12.1+, Python 3.12+, PyTorch 2.7+
- **권장**: A100/H100 (24GB+ VRAM), CUDA 12.6+
- **GPU 이동성**: Runpod ↔ Vast ↔ 자체서버 — `adapters/` 교체만

---

## MCP 도구 (Agent 필수 활용)

> **cloudflare-observability + context7 = 모든 에이전트 필수.**
> 코드 작성 전 문서 조회, 배포 후 로그 확인을 반드시 수행.

### 필수 MCP 서버 (모든 에이전트)

| MCP 서버 | 용도 | 주요 도구 |
|----------|------|-----------|
| **cloudflare-observability** | **필수** — Workers 로그, D1/R2/DO 디버깅, CF 문서 검색 | `query_worker_observability`, `search_cloudflare_documentation`, `workers_list`, `workers_get_worker_code` |
| **context7** | **필수** — 라이브러리 최신 문서 조회 | `resolve-library-id` → `query-docs` (Hono, CF Workers, Flutter, Riverpod 등) |

### 필수 MCP 서버 (GPU 에이전트)

| MCP 서버 | 용도 | 주요 도구 |
|----------|------|-----------|
| **runpod** | **필수 (s3_backend_inference)** — GPU Pod/Endpoint/Template 관리, Serverless 배포 | `create-pod`, `list-endpoints`, `create-endpoint`, `update-endpoint`, `list-templates`, `create-template` 등 26개 |

> Runpod MCP: `RUNPOD_API_KEY` 환경변수 필요. `.claude.json`에서 설정.

### 필수 MCP 서버 (Frontend 에이전트)

| MCP 서버 | 용도 | 주요 도구 |
|----------|------|-----------|
| **dart** | **필수 (s3_frontend_*)** — 공식 Dart MCP. 코드 분석, 테스트, pub.dev 검색, 문서 | 코드 분석, 테스트 실행, 패키지 검색, 문서 조회 |
| **flutter-docs** | **필수 (s3_frontend_*)** — Flutter/Dart 문서 + pub.dev 패키지 검색 | `flutter_search`, `flutter_docs` |

### 선택 MCP 서버

| MCP 서버 | 용도 | 주요 도구 |
|----------|------|-----------|
| **marionette** | Flutter 앱 실시간 제어 (위젯 탭, 텍스트 입력, 스크린샷, hot reload) | `connect`, `tap`, `enter_text`, `take_screenshots`, `hot_reload` |
| **playwright** | 브라우저 자동화 테스트 | `browser_navigate`, `browser_snapshot`, `browser_click`, `browser_screenshot` |
| **github** | GitHub 이슈/PR 관리 | `create_issue`, `create_pull_request`, `search_code` |
| **brave-search** | 웹 검색 | `brave_web_search` |
| **e2b** | 코드 실행 샌드박스 | `run_code` |
| **linear** | 프로젝트 관리 | `linear_createIssue`, `linear_getIssues` |
| **posthog** | 사용자 분석 | `query-run`, `insight-create-from-query` |

### 에이전트별 MCP 활용

| 에이전트 | 필수 MCP | 추가 MCP | 용도 |
|----------|----------|----------|------|
| **모든 에이전트** | cloudflare-observability, context7 | — | CF 문서/로그 + 라이브러리 문서 |
| `s3_edge_api` | — | playwright, brave-search | Workers 배포 후 API 테스트 |
| `s3_backend_inference` | **runpod** | e2b, brave-search | GPU 배포/관리 + 코드 테스트 |
| `s3_frontend_*` | **dart**, **flutter-docs** | playwright, marionette | 코드 분석/문서 + UI 테스트 |
| QA Reviewer | — | playwright | 브라우저 검증 |

### context7 활용 패턴

```
1. resolve-library-id로 라이브러리 ID 확인
2. query-docs로 필요한 문서 조회

주요 라이브러리 ID:
- Cloudflare Workers: /websites/developers_cloudflare_workers
- Hono: /llmstxt/hono_dev_llms-full_txt
- Flutter Riverpod: /rrousselgit/riverpod
```

### cloudflare-observability 활용 패턴

```
1. accounts_list → set_active_account
2. workers_list → Workers 목록 확인
3. query_worker_observability → 로그/에러 분석
4. search_cloudflare_documentation → CF 기능 문서 조회
```

---

## Auto-Claude (24/7 자동 빌드)

### Daemon 실행

```powershell
set PYTHONUTF8=1
C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe ^
  C:\DK\S3\clone\Auto-Claude\apps\backend\runners\daemon_runner.py ^
  --project-dir "C:\DK\S3" ^
  --status-file "C:\DK\S3\.auto-claude\daemon_status.json" ^
  --use-worktrees ^
  --skip-qa ^
  --use-claude-cli ^
  --claude-cli-path "C:\Users\User\.local\bin\claude.exe"
```

> `--use-worktrees`/`--skip-qa`는 `projects/S3/project.json`의 daemon 섹션에서도 설정 가능

### Task 생성

```powershell
set PYTHONUTF8=1
C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe ^
  C:\DK\S3\clone\Auto-Claude\apps\backend\runners\spec_runner.py ^
  --task "Workers D1 스키마 마이그레이션" ^
  --project-dir "C:\DK\S3" ^
  --no-build
```

또는 Claude Code에서: `/s3-auto-task "Workers D1 스키마 마이그레이션"`

### 커스텀 에이전트 (6개)

| Agent | 담당 |
|-------|------|
| `s3_edge_api` | Workers + DO + D1 + Queues + R2 |
| `s3_backend_inference` | GPU Worker Docker + SAM3 engine |
| `s3_supabase` | (레거시) D1 마이그레이션으로 전환 예정 |
| `s3_frontend_auth` | Flutter Auth UI |
| `s3_frontend_segmentation` | 이미지 업로드 + 팔레트 + 인스턴스 + 보호 + 룰 |
| `s3_frontend_gallery` | 결과 갤러리 + 세트 내보내기 |

### 상태 확인

- Status JSON: `C:\DK\S3\.auto-claude\daemon_status.json`
- WebSocket: `ws://127.0.0.1:18801`
- Specs: `C:\DK\S3\.auto-claude\specs\`

---

## 런칭 로드맵 (Phase 1 — MVP)

### 병렬 실행 전략

```
Group A (Workers): D1 스키마 → Auth → [Presets, Rules, UserLimiterDO 병렬] → JobCoordinatorDO → R2+Queues → Callback
Group B (GPU):     SAM3 engine → Runpod adapter ──────────────────────────────────────────────────────┘
Group C (Flutter): Auth → 도메인/팔레트 → 업로드/보호/룰 → 진행률/결과/세트
```

| # | 태스크 | 레이어 | 의존성 |
|---|--------|--------|--------|
| 1 | D1 스키마 (users, rules, jobs_log, job_items_log, billing_events) | Workers | - |
| 2 | Workers Auth (anon JWT 발급/검증 미들웨어) | Workers | 1 |
| 3 | Workers Presets API (하드코딩 interior+seller) | Workers | 2 |
| 4 | Workers Rules CRUD API | Workers | 2 |
| 5 | UserLimiterDO (크레딧/동시성/룰 슬롯 제한) | Workers | 2 |
| 6 | JobCoordinatorDO (상태머신/멱등성/execute 분리) | Workers | 5 |
| 7 | R2 presigned URL + Queues 연결 | Workers | 6 |
| 8 | GPU Worker Docker: SAM3 segment + rule apply | GPU | - |
| 9 | GPU Worker: Runpod adapter | GPU | 8 |
| 10 | Workers callback + 상태 갱신 + D1 flush | Workers | 7,9 |
| 11 | Flutter: Auth (anon) + 온보딩 | Frontend | 2 |
| 12 | Flutter: 도메인 선택 + 팔레트 UI + 인스턴스 리스트 | Frontend | 3 |
| 13 | Flutter: 이미지 업로드 + 보호 토글 + 룰 적용/저장 | Frontend | 4,7 |
| 14 | Flutter: 진행률(polling) + 결과 + 세트 내보내기 | Frontend | 10 |
| 15 | E2E 통합 테스트 | All | 10,14 |

---

## Tech Stack 요약

| 계층 | 기술 |
|------|------|
| Frontend | Flutter 3.38.9, Riverpod 3, Freezed 3, GoRouter, ShadcnUI |
| Workers | Hono, Cloudflare Workers, D1, R2, Durable Objects, Queues |
| GPU Worker | Python 3.12, PyTorch 2.7+, SAM3, Docker, Runpod Serverless |
| 인프라 | Cloudflare (Workers/D1/R2/DO/Queues), Runpod (GPU) |
| 자동화 | Auto-Claude (daemon + 6 custom agents), MCP tools |
