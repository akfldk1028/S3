# S3 프로젝트 전체 구조 맵

> AI 에이전트 + 팀원용 — 모든 폴더/파일의 역할과 관계
> 최종 업데이트: 2026-02-19

---

## 1. 루트 디렉토리 전체 구조

```
S3/
│
│  ─── 핵심 문서 ───────────────────────────────────────────────────
├── CLAUDE.md                        # AI Agent 가이드 (아키텍처, 규칙, 명령어)
├── workflow.md                      # 제품+기술 SSoT (API 스펙, 데이터 모델, 파이프라인)
├── TODO.md                          # Phase A~E 실행 계획 + 진행 상태
├── ARCHITECTURE.md                  # 아키텍처 개요
├── README.md                        # 프로젝트 소개
│
│  ─── 프로덕션 코드 (3계층) ────────────────────────────────────────
├── workers/                         # ⚡ Cloudflare Workers (입구+뇌)  ← 프로덕션
├── gpu-worker/                      # 🖥️ GPU Worker Docker (근육)      ← 프로덕션
├── frontend/                        # 📱 Flutter App (클라이언트)       ← 프로덕션
│
│  ─── 문서 / 팀 가이드 ────────────────────────────────────────────
├── docs/                            # 📚 기술 문서
├── team/                            # 👥 팀원별 가이드
│
│  ─── 자동화 시스템 ───────────────────────────────────────────────
├── clone/Auto-Claude/               # 🤖 Auto-Claude 24/7 빌드 시스템
├── .auto-claude/                    # Auto-Claude 상태 (specs, daemon)
│
│  ─── 설정 / 유틸 ────────────────────────────────────────────────
├── .claude/                         # Claude Code 프로젝트 설정
├── .gitignore
├── .claude_settings.json
├── .auto-claude-security.json
├── .auto-claude-status
│
│  ─── 스크립트 (PowerShell) ───────────────────────────────────────
├── start-daemon.ps1                 # Auto-Claude daemon 시작
├── start-daemon-v2.ps1
├── reset-daemon.ps1                 # worktree 정리 + 상태 리셋
├── restart-daemon.ps1
├── check-daemon.ps1                 # daemon 상태 확인
├── check-daemon-pickup.ps1
├── debug-daemon.ps1
├── run-daemon-debug.ps1
├── check-plans.ps1
├── check-recent-files.ps1
├── create-specs.ps1
├── start-ui.ps1 / start-ui.bat     # Auto-Claude UI 시작
├── prevent-sleep.ps1                # 슬립 방지
├── run-design-spec.ps1 / .bat
├── test-*.ps1 / run-*.ps1          # 테스트 실행 스크립트
│
│  ─── 로그 / 기타 ────────────────────────────────────────────────
├── daemon-out.log / daemon-err.log  # daemon 실행 로그
├── run-*-output.log                 # spec 실행 로그
├── s3-workspace-*.png               # UI 스크린샷 (데스크톱/모바일)
├── snow-*.png                       # UI 목업
├── daemon_status.json               # daemon 상태 (루트 복사본)
├── E2E-TEST-RESULTS.md
├── MOCK_API_VERIFICATION.md
├── SUBTASK_7-1_SUMMARY.md
└── logs/                            # 추가 로그 디렉토리
```

---

## 2. Workers 상세 (`workers/`)

> 역할: **입구+뇌** — 인증, API, CRUD, 상태관리, Queue dispatch
> 배포: `https://s3-workers.clickaround8.workers.dev` (Cloudflare Workers)

```
workers/
├── src/
│   ├── index.ts                          # Hono 앱 entry + 라우트 마운트 + DO export + Queue consumer
│   │                                     #   마운트: /auth, /presets, /rules, /jobs, /me
│   │                                     #   미들웨어: cors, logger, auth
│   │
│   ├── _shared/                          # ── 공유 유틸리티 ──
│   │   ├── types.ts                      #   모든 타입 SSoT (Env, Auth, Job FSM, Response envelope)
│   │   ├── response.ts                   #   ok() / error() 응답 래퍼
│   │   ├── jwt.ts                        #   HS256 sign / verify (hono/jwt)
│   │   ├── errors.ts                     #   에러 코드 상수 (AUTH_REQUIRED, RULE_SLOT_LIMIT 등)
│   │   └── r2.ts                         #   AWS SDK S3Client → R2 presigned URL 생성
│   │
│   ├── middleware/
│   │   └── auth.middleware.ts            #   JWT Bearer 검증
│   │                                     #   skip: /health, /auth/anon, /jobs/*/callback
│   │
│   ├── auth/                             # ── 인증 ──
│   │   ├── auth.route.ts                 #   POST /auth/anon → JWT 발급
│   │   └── auth.service.ts               #   createOrGetUser() + createAuthToken()
│   │
│   ├── user/                             # ── 유저 상태 ──
│   │   └── user.route.ts                 #   GET /me → UserLimiterDO.getUserState()
│   │
│   ├── presets/                          # ── 프리셋 ──
│   │   ├── presets.route.ts              #   GET /presets, GET /presets/:id
│   │   └── presets.data.ts               #   하드코딩: interior (12 concepts), seller (6 concepts)
│   │
│   ├── rules/                            # ── 룰 CRUD ──
│   │   ├── rules.route.ts               #   POST / GET / PUT / DELETE /rules
│   │   ├── rules.service.ts             #   D1 CRUD 5개 함수
│   │   └── rules.validator.ts           #   Zod: CreateRuleSchema, UpdateRuleSchema
│   │
│   ├── jobs/                             # ── Job 파이프라인 ──
│   │   ├── jobs.route.ts                #   7 endpoints (구현 완료)
│   │   │                                #     GET  /jobs            → 목록 (D1)
│   │   │                                #     POST /jobs            → 생성 + presigned URLs
│   │   │                                #     POST /jobs/:id/confirm-upload
│   │   │                                #     POST /jobs/:id/execute → Queue push
│   │   │                                #     GET  /jobs/:id        → 상태/진행률
│   │   │                                #     POST /jobs/:id/callback → GPU 콜백
│   │   │                                #     POST /jobs/:id/cancel
│   │   ├── jobs.service.ts              #   presigned URL 생성, queue push
│   │   └── jobs.validator.ts            #   Zod: CreateJob, Execute, Callback
│   │
│   └── do/                               # ── Durable Objects (뇌) ──
│       ├── UserLimiterDO.ts              #   유저당 1개: 크레딧 reserve/commit/rollback
│       │                                 #   동시성 슬롯 (free=1, pro=3)
│       │                                 #   룰 슬롯 (free≤2, pro≤20)
│       ├── JobCoordinatorDO.ts           #   Job당 1개: FSM 상태머신 7단계
│       │                                 #   created→uploaded→queued→running→done/failed/canceled
│       │                                 #   item별 진행률 + 멱등성 ring buffer (512)
│       │                                 #   alarm-based D1 flush
│       └── do.helpers.ts                 #   getUserLimiterStub(), getJobCoordinatorStub()
│
├── migrations/
│   └── 0001_init.sql                     # D1 스키마: 5 tables + 4 indexes
│                                         #   users, rules, jobs_log, job_items_log, billing_events
│
├── wrangler.toml                         # CF 바인딩: D1(s3-db), R2(s3-images), DO×2, Queue(gpu-jobs)
├── package.json                          # hono, zod, @aws-sdk/client-s3, @cloudflare/workers-types
├── tsconfig.json                         # ES2022, strict
├── .dev.vars.example                     # JWT_SECRET, GPU_CALLBACK_SECRET
└── VERIFICATION.md                       # E2E curl 테스트 가이드
```

**모듈 의존성 규칙:**
```
routes ──▶ services ──▶ D1 (쿼리)
routes ──▶ DO (상태 위임)
routes ──▶ _shared (response, errors, types)
middleware ──▶ _shared/jwt
DO ──▶ D1 (영속 flush, alarm)
DO ✕──▶ DO (직접 호출 금지, route가 중개)
```

---

## 4. GPU Worker 상세 (`gpu-worker/`)

> 역할: **근육** — SAM3 세그먼테이션 + 룰 적용 + R2 업로드 + Workers 콜백
> 배포: Runpod Serverless (미배포, 코드 완성)

```
gpu-worker/
├── main.py                               # entry — ADAPTER env 기반 어댑터 선택
│
├── engine/                               # ── 핵심 추론 엔진 ──
│   ├── pipeline.py                       #   2단계 오케스트레이터
│   │                                     #   Stage 1: R2 다운 → SAM3 segment → instance masks
│   │                                     #   Stage 2: rule apply → R2 업로드 → callback
│   ├── segmenter.py                      #   SAM3 wrapper (848M, HuggingFace 다운로드)
│   │                                     #   segment(image, concept_text) → instance masks
│   ├── applier.py                        #   룰 적용 엔진 (recolor/tone/texture)
│   │                                     #   protect mask 영역 보존
│   ├── r2_io.py                          #   R2 S3호환 클라이언트 (boto3)
│   │                                     #   download(key), upload(key, data)
│   ├── callback.py                       #   Workers API 콜백 (httpx)
│   │                                     #   deterministic idempotency key + 1회 retry
│   └── postprocess.py                    #   (v2 예약: 후처리)
│
├── adapters/                             # ── 배포 어댑터 ──
│   ├── runpod_serverless.py              #   MVP: Runpod event loop handler
│   └── queue_pull.py                     #   v2: CF Queue polling (Vast/자체서버)
│
├── presets/                              # ── 도메인 concept 매핑 ──
│   ├── interior.py                       #   건축/인테리어: 12 concepts
│   │                                     #   Wall, Floor, Ceiling, Window, Door, Frame_Molding,
│   │                                     #   Tile, Grout, Cabinet, Countertop, Light, Handle
│   └── seller.py                         #   쇼핑/셀러: 8 concepts
│                                         #   Product, Background, Body, Label_Text, Logo,
│                                         #   Gloss, Parts, Accessories
│
├── tests/                                # ── 133개 테스트 (전체 mocked) ──
│   ├── test_pipeline.py                  #   통합 22개
│   ├── test_segmenter.py                 #   세그먼터 25개
│   ├── test_applier.py                   #   룰 적용 37개
│   ├── test_r2_io.py                     #   스토리지 18개
│   └── test_callback.py                  #   콜백/멱등성 31개
│
├── Dockerfile                            # CUDA 12.6 + Python 3.12 (~8GB image)
├── .dockerignore
├── requirements.txt                      # runpod, httpx, torch, transformers, boto3, Pillow
├── pyproject.toml
├── pytest.ini
├── .env.example                          # HF_TOKEN, R2 credentials, callback secret
├── verify_imports.py                     # 모듈 import 검증
├── docker-verification.sh                # Docker 자동 검증
├── DOCKER_TESTING.md
├── VERIFICATION_SUMMARY.md
└── README.md
```

**추론 파이프라인 흐름:**
```
Runpod Queue ──▶ handler(event)
                    │
                    ▼
              pipeline.process_job()
                    │
        ┌───────────┼───────────┐
        ▼                       ▼
  Stage 1: Segment        Stage 2: Apply (×N items, 동시 4개)
  ┌─────────────────┐     ┌─────────────────────┐
  │ R2 download     │     │ masks + rule params  │
  │ SAM3 segment    │     │ applier.apply_rules()│
  │ instance masks  │     │ protect mask 적용    │
  └────────┬────────┘     │ R2 upload results    │
           │              │ callback per item    │
           └──────────────┘─────────┬────────────┘
                                    ▼
                          Workers callback (done)
```

---

## 5. Frontend 상세 (`frontend/`)

> 역할: **클라이언트** — 5단 파이프라인 UI + Workers API 연동
> 기술: Flutter 3.38.9 + Riverpod 3 + ShadcnUI + Freezed 3 + GoRouter

```
frontend/lib/
├── main.dart                              # 앱 entry + error boundary
├── app.dart                               # ShadcnApp.router + ProviderScope
│
├── routing/                               # ── GoRouter ──
│   ├── app_router.dart                    #   8 라우트 + auth guard (redirect callback)
│   └── app_router.g.dart                  #   [generated]
│
├── constants/                             # ── 상수 ──
│   ├── api_endpoints.dart                 #   Workers base URL + 14개 path
│   ├── app_colors.dart                    #   색상 팔레트
│   └── app_theme.dart                     #   테마 상수 (레거시)
│
├── core/                                  # ── 앱 코어 ──
│   ├── api/                               #   API 클라이언트
│   │   ├── api_client.dart                #     abstract 인터페이스 (14 methods)
│   │   ├── s3_api_client.dart             #     Dio 구현 (JWT interceptor + envelope unwrap)
│   │   ├── mock_api_client.dart           #     테스트용 Mock
│   │   └── api_client_provider.dart       #     Riverpod provider
│   │
│   ├── auth/                              #   인증 상태
│   │   ├── auth_provider.dart             #     JWT 관리 (login/logout)
│   │   ├── user_provider.dart             #     GET /me 유저 데이터
│   │   └── secure_storage_service.dart    #     SecureStorage 래퍼
│   │
│   ├── models/                            #   Freezed 데이터 모델
│   │   ├── preset.dart                    #     + .freezed.dart + .g.dart
│   │   ├── rule.dart
│   │   ├── job.dart
│   │   ├── job_progress.dart
│   │   └── job_item.dart
│   │
│   ├── services/
│   │   └── image_service.dart             #   이미지 압축 / 썸네일
│   │
│   ├── providers/
│   │   └── theme_provider.dart            #   라이트/다크 테마
│   │
│   └── widgets/
│       ├── error_boundary.dart            #   에러 캐칭 wrapper
│       └── offline_indicator.dart         #   오프라인 표시
│
├── features/                              # ── Feature-First 구조 ──
│   │
│   ├── camera/                            #   SNOW-style 카메라 홈 (메인 진입점)
│   │   ├── camera_home_screen.dart        #     카메라 홈 (☰사이드바 + 컨셉칩 + 셔터)
│   │   ├── camera_screen.dart             #     독립 카메라 (workspace push용)
│   │   └── widgets/
│   │       ├── domain_drawer.dart         #     도메인 사이드바 (프리셋 선택)
│   │       └── concept_chips_bar.dart     #     수평 스크롤 컨셉 칩 바
│   │
│   ├── splash/                            #   스플래시 화면 (애니메이션)
│   │   └── splash_screen.dart
│   │
│   ├── auth/                              #   인증 (자동 anon 로그인)
│   │   ├── auth_screen.dart
│   │   └── models/
│   │       └── user_model.dart            #     Freezed User (Workers 응답 형식)
│   │
│   ├── onboarding/                        #   온보딩 (3페이지)
│   │   ├── onboarding_screen.dart
│   │   ├── onboarding_provider.dart
│   │   └── widgets/
│   │       ├── onboarding_page_1.dart
│   │       ├── onboarding_page_2.dart
│   │       └── onboarding_page_3.dart
│   │
│   ├── domain_select/                     #   도메인 선택 (interior/seller)
│   │   ├── domain_select_screen.dart
│   │   ├── presets_provider.dart
│   │   └── selected_preset_provider.dart  #     선택된 도메인 ID (카메라 홈용)
│   │
│   ├── palette/                           #   팔레트 (concept 칩 선택)
│   │   ├── palette_screen.dart
│   │   ├── palette_provider.dart
│   │   └── palette_state.dart             #     Freezed state
│   │
│   ├── upload/                            #   이미지 업로드 (R2 presigned)
│   │   └── upload_screen.dart
│   │
│   ├── rules/                             #   룰 에디터 + CRUD
│   │   ├── rules_screen.dart
│   │   └── rules_provider.dart
│   │
│   ├── workspace/                         #   🔑 메인 작업 영역 (5단계 통합)
│   │   ├── workspace_screen.dart          #     멀티스텝 메인 화면
│   │   ├── workspace_provider.dart        #     Riverpod notifier
│   │   ├── workspace_state.dart           #     Phase machine (5단계)
│   │   ├── preset_detail_provider.dart
│   │   ├── theme.dart
│   │   └── widgets/                       #     반응형 위젯 (데스크톱+모바일)
│   │       ├── photo_grid.dart
│   │       ├── concepts_section.dart
│   │       ├── protect_section.dart
│   │       ├── rules_section.dart
│   │       ├── domain_section.dart
│   │       ├── top_bar.dart
│   │       ├── action_bar.dart
│   │       ├── progress_overlay.dart
│   │       ├── results_overlay.dart
│   │       ├── side_panel.dart            #     데스크톱 사이드 패널
│   │       ├── mobile_bottom_sheet.dart   #     모바일 바텀시트
│   │       └── mobile_pipeline_tabs.dart  #     모바일 탭 네비게이션
│   │
│   ├── jobs/                              #   Job 진행률 (3초 polling)
│   │   └── job_progress_screen.dart
│   │
│   ├── history/                           #   Job 히스토리
│   │   ├── history_screen.dart
│   │   ├── history_provider.dart
│   │   └── widgets/
│   │       ├── job_history_item.dart
│   │       ├── status_badge.dart
│   │       └── history_empty_state.dart
│   │
│   ├── results/                           #   결과 갤러리 + 내보내기
│   │   └── results_screen.dart
│   │
│   ├── pricing/                           #   요금제 / 크레딧
│   │   ├── pricing_screen.dart
│   │   └── widgets/
│   │       ├── pricing_card.dart
│   │       ├── plan_upgrade_flow.dart
│   │       └── credit_topup_dialog.dart
│   │
│   ├── settings/                          #   설정
│   │   └── settings_screen.dart
│   │
│   ├── profile/                           #   프로필
│   │   └── pages/screens/profile_screen.dart
│   │
│   └── home/                              #   홈 대시보드
│       └── pages/screens/home_screen.dart
│
├── shared/                                # ── 공유 위젯/테마 ──
│   ├── theme/
│   │   └── app_theme.dart
│   └── widgets/
│       ├── tap_scale.dart                 #   탭 애니메이션
│       └── before_after_slider.dart       #   비포/애프터 슬라이더
│
└── common_widgets/                        # ── 공통 위젯 ──
    ├── shimmer_card.dart                  #   로딩 카드
    ├── shimmer_list.dart                  #   로딩 리스트
    └── shimmer_widgets.dart               #   shimmer 유틸
```

**화면 흐름 (GoRouter 8 라우트):**
```
/splash ──▶ /auth ──▶ / (카메라 홈)
                          │
                    ┌─────┼────────────────────────────┐
                    │     │                            │
              ☰ 사이드바  사진 촬영/갤러리              │
              (도메인 선택 + 컨셉 칩)                   │
                    │                                  │
                    ▼                                  │
              도메인 선택됨? ──Yes──▶ /upload?presetId= │
                    │                                  │
                    No                                 │
                    ▼                                  │
              /domain-select ──▶ /palette ──▶ /upload   │
                                                       │
                                    ┌──────────────────┘
                                    ▼
                              /rules    /jobs/:id    /settings
```

---

## 6. 문서 디렉토리 (`docs/`, `team/`)

```
docs/
├── README.md                              # 문서 인덱스
├── #Resource.md                           # 외부 리소스 링크
├── cloudflare-resources.md                # CF 리소스 현황 (D1 ID, R2 bucket, DO 등)
├── wrangler-vs-do.md                      # Workers vs Durable Objects 차이 설명
├── project-structure.md                   # 이 파일
├── contracts/
│   └── api-contracts.md                   # API 계약 문서
└── idea/
    ├── S3_기획.pdf                         # 제품 기획서
    └── S3-차별.pdf                         # 경쟁 차별화 문서

team/
├── README.md                              # 팀 가이드 인덱스
├── LEAD.md                                # 리드 가이드
├── HANDOFF.md                             # 인수인계 문서
├── SETUP.md                               # 환경 셋업
├── MEMBER-A-WORKERS-CORE.md               # Workers Core 담당
├── MEMBER-B-WORKERS-DO.md                 # Workers DO 담당
├── MEMBER-C-GPU.md                        # GPU Worker 담당
└── MEMBER-D-FRONTEND.md                   # Frontend 담당
```

---

## 7. Auto-Claude 자동 빌드 (`clone/Auto-Claude/`, `.auto-claude/`)

```
clone/Auto-Claude/                         # Auto-Claude 소스 (외부 repo clone)
├── apps/
│   ├── backend/                           # Python daemon + runners + agents
│   │   ├── runners/
│   │   │   ├── daemon_runner.py           # 24/7 daemon (spec → build → QA)
│   │   │   └── spec_runner.py             # 단건 spec 생성
│   │   ├── agents/                        # 6개 커스텀 에이전트
│   │   ├── prompts/                       # AI 프롬프트 (~40개)
│   │   ├── spec/                          # spec 생성 로직
│   │   └── .venv/                         # Python 가상환경
│   └── frontend/                          # Electron UI (Kanban 보드)
│
.auto-claude/                              # Auto-Claude 프로젝트 상태
├── daemon_status.json                     # daemon 현재 상태 (running/idle)
├── project_index.json                     # 프로젝트 인덱스
├── specs/                                 # 생성된 spec들 (28개)
│   ├── 001-mvp-full-implementation-design/
│   │   ├── spec.md                        # 설계 spec
│   │   ├── qa_report.md                   # QA 결과
│   │   └── MANUAL_TEST_PLAN.md            # 수동 테스트 플랜
│   ├── 002-workers-foundation-schema-auth/
│   ├── ...
│   └── 028-flutter-camera-plus-album/
└── worktrees/                             # git worktree (빌드 격리)
    └── tasks/
        ├── 012-frontend-sam3-프롬프트-...
        ├── 014-pricingscreen-...
        └── ...
```

---

## 8. 3계층 아키텍처 한눈에 보기

```
                    ┌─────────────────────────────────────────────┐
                    │              사용자 (브라우저/앱)              │
                    └────────────────────┬────────────────────────┘
                                         │
                    ┌────────────────────▼────────────────────────┐
                    │            frontend/ (Flutter)               │
                    │  Riverpod + ShadcnUI + GoRouter              │
                    │  S3ApiClient → Dio + JWT + envelope unwrap   │
                    └────────────────────┬────────────────────────┘
                                         │ REST API (14 endpoints)
                    ┌────────────────────▼────────────────────────┐
                    │            workers/ (Cloudflare)             │
                    │  ┌──────────┐  ┌──────────┐  ┌───────────┐ │
                    │  │ Hono API │  │   D1     │  │    R2     │ │
                    │  │ (입구)    │  │ (SQLite) │  │ (이미지)   │ │
                    │  └────┬─────┘  └──────────┘  └───────────┘ │
                    │       │                                      │
                    │  ┌────▼────────────┐  ┌──────────────────┐  │
                    │  │ UserLimiterDO   │  │ JobCoordinatorDO │  │
                    │  │ (뇌: 크레딧)    │  │ (뇌: 상태머신)    │  │
                    │  └─────────────────┘  └───────┬──────────┘  │
                    │                               │ Queue push  │
                    └───────────────────────────────┼─────────────┘
                                                    │
                    ┌───────────────────────────────▼─────────────┐
                    │           gpu-worker/ (Runpod)               │
                    │  SAM3 segment → rule apply → R2 upload      │
                    │  callback → Workers /jobs/:id/callback       │
                    │  (근육)                                      │
                    └─────────────────────────────────────────────┘

    ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄

    ✅ cf-backend, ai-backend 레거시 폴더 삭제 완료 (2026-02-19)
       프롬프트만 gpu-worker/docs/legacy-prompts.json 으로 보존
```

---

## 9. 핵심 참조 파일 (AI Agent용)

| 무엇을 알고 싶을 때 | 이 파일을 읽어라 |
|---------------------|-----------------|
| API 스펙 / 데이터 모델 | `workflow.md` |
| 전체 아키텍처 / 규칙 | `CLAUDE.md` |
| 실행 계획 / 진행 상태 | `TODO.md` |
| CF 리소스 현황 (D1 ID, R2 등) | `docs/cloudflare-resources.md` |
| Workers vs DO 차이 | `docs/wrangler-vs-do.md` |
| 프로젝트 폴더 구조 | `docs/project-structure.md` (이 파일) |
| Workers 타입 정의 | `workers/src/_shared/types.ts` |
| Workers 바인딩 설정 | `workers/wrangler.toml` |
| D1 스키마 | `workers/migrations/0001_init.sql` |
| Flutter API 인터페이스 | `frontend/lib/core/api/api_client.dart` |
| Flutter 라우팅 | `frontend/lib/routing/app_router.dart` |
| Flutter 모델 | `frontend/lib/core/models/*.dart` |
| GPU 추론 파이프라인 | `gpu-worker/engine/pipeline.py` |
| GPU 도메인 프리셋 | `gpu-worker/presets/interior.py`, `seller.py` |
| 팀원별 담당 | `team/MEMBER-*.md` |

---

## 10. Tech Stack 요약

| 계층 | 기술 | 버전 |
|------|------|------|
| **Frontend** | Flutter + Dart | 3.38.9 |
| | Riverpod (상태관리) | 3.1.0 |
| | Freezed (모델) | 3.2.3 |
| | GoRouter (네비게이션) | 17.1.0 |
| | ShadcnUI (디자인 시스템) | 0.45.1 |
| | Dio (HTTP) | 5.7.0 |
| **Workers** | Hono (HTTP 프레임워크) | 4.7.0 |
| | Cloudflare Workers | — |
| | D1 (SQLite DB) | — |
| | R2 (S3 호환 스토리지) | — |
| | Durable Objects (상태) | — |
| | Queues (메시지 큐) | — |
| | Zod (검증) | 3.24.0 |
| | TypeScript | 5.7.0 |
| **GPU Worker** | Python | 3.12+ |
| | PyTorch | 2.7+ |
| | SAM3 (세그먼테이션) | 848M params |
| | Runpod SDK | 1.7+ |
| | boto3 (R2 클라이언트) | 1.35+ |
| | Docker + CUDA | 12.6 |
| **자동화** | Auto-Claude | daemon + 6 agents |
