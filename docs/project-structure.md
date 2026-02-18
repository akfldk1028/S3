# S3 프로젝트 구조 가이드

> AI 에이전트와 팀원이 참고할 폴더/파일 맵
> 최종 업데이트: 2026-02-15

---

## 전체 구조

```
S3/
├── CLAUDE.md                    # AI Agent 가이드 (SSoT 참조)
├── workflow.md                  # 제품+기술 SSoT (API, 데이터모델, 파이프라인)
├── TODO.md                      # 실행 계획 (Phase A~E)
│
├── workers/                     # ⚡ Cloudflare Workers (입구+뇌)
│   ├── src/                     # TypeScript 소스
│   ├── migrations/              # D1 SQL 마이그레이션
│   ├── wrangler.toml            # CF 바인딩 설정
│   ├── .dev.vars                # 로컬 환경변수 (gitignore)
│   └── package.json             # 의존성 (hono, zod, jose, aws-sdk)
│
├── gpu-worker/                  # 🖥️ GPU Worker (근육)
│   ├── engine/                  # SAM3 추론 엔진
│   ├── adapters/                # Runpod/Vast 어댑터
│   ├── presets/                 # 도메인별 concept 매핑
│   ├── Dockerfile               # Docker 빌드
│   └── main.py                  # 엔트리포인트
│
├── frontend/                    # 📱 Flutter App
│   ├── lib/                     # Dart 소스
│   ├── pubspec.yaml             # 의존성
│   └── test/                    # 테스트
│
├── docs/                        # 📚 문서
│   ├── cloudflare-resources.md  # CF 리소스 현황
│   ├── wrangler-vs-do.md        # Wrangler vs DO 설명
│   ├── project-structure.md     # 이 파일
│   └── #Resource.md             # 리소스 참고
│
├── clone/Auto-Claude/           # 🤖 자동 빌드 시스템
│   └── apps/backend/            # daemon + runners
│
└── .auto-claude/                # Auto-Claude 상태
    ├── specs/                   # spec JSON 파일들
    └── daemon_status.json       # daemon 상태
```

---

## Workers 상세 (`workers/src/`)

```
workers/src/
├── index.ts                     # Hono 앱 + DO exports + Queue consumer
│                                # - 라우트 마운트: /auth, /presets, /rules, /jobs, /me
│                                # - 미들웨어: cors, logger, auth
│
├── _shared/                     # 공유 유틸리티
│   ├── types.ts                 # Env, AuthUser, JobStatus 등 모든 타입
│   ├── response.ts              # ok(), error() 응답 envelope
│   ├── errors.ts                # ERR 상수 (NOT_FOUND, UNAUTHORIZED 등)
│   ├── jwt.ts                   # JWT sign/verify (jose 라이브러리)
│   └── r2.ts                    # R2 presigned URL 생성 (S3 호환 서명)
│
├── middleware/
│   └── auth.middleware.ts       # JWT Bearer 검증
│                                # skip: /health, /auth/anon, /jobs/*/callback
│
├── auth/
│   ├── auth.route.ts            # POST /auth/anon
│   └── auth.service.ts          # D1: 유저 생성, 조회
│
├── presets/
│   ├── presets.route.ts         # GET /presets, GET /presets/:id
│   └── presets.data.ts          # 하드코딩 프리셋 (interior, seller)
│
├── rules/
│   ├── rules.route.ts           # POST/GET/PUT/DELETE /rules
│   ├── rules.service.ts         # D1 CRUD (createRule, listRules 등)
│   └── rules.validator.ts       # Zod 스키마 (CreateRuleSchema 등)
│
├── jobs/
│   ├── jobs.route.ts            # 6 endpoints: create, confirm, execute, get, callback, cancel
│   ├── jobs.service.ts          # D1 jobs_log/job_items_log 쿼리
│   └── jobs.validator.ts        # Zod: CreateJobSchema, ExecuteJobSchema, CallbackSchema
│
├── user/
│   └── user.route.ts            # GET /me → UserLimiterDO.getUserState()
│
└── do/
    ├── UserLimiterDO.ts         # 유저 크레딧/동시성/룰슬롯 관리
    ├── JobCoordinatorDO.ts      # Job 상태머신/멱등성/콜백 처리
    └── do.helpers.ts            # DO 헬퍼 함수
```

### 모듈 간 의존성 규칙

```
routes → services → D1 (읽기/쓰기)
routes → DO (상태 관리 위임)
routes → _shared (response, errors, types)
middleware → _shared/jwt (토큰 검증)
DO → D1 (영속 flush)
DO → _shared/types (타입)
```

**금지**: DO ↔ DO 직접 호출 안 함 (Workers route가 중개)

---

## Frontend 상세 (`frontend/lib/`)

```
frontend/lib/
├── main.dart                    # 앱 엔트리
├── app.dart                     # ProviderScope + MaterialApp.router
│
├── constants/
│   └── api_endpoints.dart       # Workers API URL + 14개 path 정의
│
├── core/                        # 앱 코어 (비즈니스 로직)
│   ├── api/
│   │   ├── api_client.dart      # abstract ApiClient (13 methods)
│   │   ├── s3_api_client.dart   # 실제 HTTP 구현 (Dio + JWT + envelope unwrap)
│   │   ├── mock_api_client.dart # 개발용 Mock 구현
│   │   ├── api_client_provider.dart  # Riverpod provider (S3ApiClient 반환)
│   │   └── api_client_provider.g.dart
│   │
│   ├── auth/
│   │   ├── auth_provider.dart   # JWT 상태 관리 (login/logout)
│   │   ├── secure_storage_service.dart # JWT 암호화 저장
│   │   ├── user_provider.dart   # GET /me 유저 데이터
│   │   └── *.g.dart             # generated
│   │
│   ├── models/                  # Freezed 데이터 모델
│   │   ├── user.dart + .freezed.dart + .g.dart
│   │   ├── preset.dart
│   │   ├── rule.dart
│   │   ├── job.dart
│   │   └── job_item.dart
│   │
│   └── router/
│       └── app_router.dart      # GoRouter 라우트 정의
│
├── features/                    # Feature-First 구조
│   ├── auth/
│   │   └── auth_screen.dart     # 자동 anon 로그인 화면
│   │
│   ├── domain_select/
│   │   ├── domain_select_screen.dart  # 도메인 선택 (interior/seller)
│   │   └── presets_provider.dart      # 프리셋 목록 provider
│   │
│   ├── palette/
│   │   ├── palette_screen.dart  # Concept 선택 + Instance 카드
│   │   ├── palette_provider.dart
│   │   └── palette_state.dart   # Freezed state
│   │
│   ├── upload/
│   │   └── upload_screen.dart   # 이미지 선택 + R2 업로드
│   │
│   ├── rules/
│   │   ├── rules_screen.dart    # 룰 목록 + 에디터
│   │   └── rules_provider.dart  # CRUD provider
│   │
│   ├── jobs/
│   │   └── job_progress_screen.dart  # 폴링 + 진행률 바
│   │
│   └── results/
│       └── results_screen.dart  # 결과 갤러리 + 내보내기
│
├── routing/
│   └── app_router.dart          # GoRouter (auth guard 포함)
│
├── shared/
│   └── theme/
│       └── app_theme.dart       # ShadcnUI 스타일 테마
│
└── utils/                       # 공통 유틸
```

### 화면 흐름 (GoRouter)

```
/auth           → AuthScreen (자동 로그인)
    ↓ JWT 획득
/domain-select  → DomainSelectScreen
    ↓ 도메인 선택
/palette/:id    → PaletteScreen (concept 선택)
    ↓
/upload         → UploadScreen (이미지 업로드)
    ↓
/rules          → RulesScreen (룰 설정)
    ↓
/jobs/:id       → JobProgressScreen (폴링)
    ↓ done
/results/:id    → ResultsScreen (갤러리)
```

### 코드 생성 (build_runner)

모델/provider 수정 후 반드시 실행:
```bash
cd frontend
dart run build_runner build --delete-conflicting-outputs
```

생성되는 파일:
- `*.freezed.dart` — Freezed immutable 클래스
- `*.g.dart` — JSON serialization + Riverpod provider

---

## GPU Worker 상세 (`gpu-worker/`)

```
gpu-worker/
├── main.py                      # 엔트리 (Runpod handler)
├── engine/
│   ├── pipeline.py              # segment → apply → postprocess → upload
│   ├── segmenter.py             # SAM3 wrapper
│   ├── applier.py               # Rule apply (mask + replace)
│   ├── r2_io.py                 # R2 업/다운로드 (boto3)
│   └── callback.py              # Workers 콜백 (POST /jobs/:id/callback)
├── adapters/
│   ├── runpod_serverless.py     # Runpod Serverless 어댑터
│   └── queue_pull.py            # Vast/자체서버용
├── presets/                     # 도메인별 concept 매핑
├── Dockerfile                   # Python 3.12 + CUDA + SAM3
├── requirements.txt             # PyTorch, boto3, etc.
└── tests/
```

---

## 핵심 참조 파일 (AI Agent용)

| 무엇을 알고 싶을 때 | 이 파일을 읽어라 |
|---------------------|-----------------|
| API 스펙/데이터모델 | `workflow.md` |
| 전체 아키텍처/규칙 | `CLAUDE.md` |
| 실행 계획/진행 상태 | `TODO.md` |
| CF 리소스 현황 | `docs/cloudflare-resources.md` |
| Workers vs DO 차이 | `docs/wrangler-vs-do.md` |
| Workers 타입 정의 | `workers/src/_shared/types.ts` |
| Workers 바인딩 설정 | `workers/wrangler.toml` |
| Flutter API 인터페이스 | `frontend/lib/core/api/api_client.dart` |
| Flutter 라우팅 | `frontend/lib/routing/app_router.dart` |
| Flutter 모델 | `frontend/lib/core/models/*.dart` |
