# S3 팀 작업 가이드 (v3.2 — 2026-02-19)

> 리드 + AI 팀원 4명 병렬 개발. Cloudflare-native 아키텍처.
> **Supabase 제거됨** → D1 + DO로 대체.

---

## 현재 상태 요약 (2026-02-19)

```
Workers: 14/14 엔드포인트 구현 + 배포 완료 ✅
         DO 2개 완전 구현 + 라우트 연결 완료
         Jobs 7개 엔드포인트 구현 완료
         URL: https://s3-workers.clickaround8.workers.dev

Frontend: UI 전부 구현 + Workers API 연결 완료 ✅
          S3ApiClient 사용 (JWT + envelope unwrap)
          8개 라우트 + auth guard 작동
          SNOW-style 카메라 홈 통합 (도메인 사이드바 + 컨셉 칩)
          flutter analyze: 0 errors

GPU:     코드 23파일 완성 ✅
         테스트 133개 (mock)
         Docker build ready
         Runpod 미배포 ❌

레거시:  cf-backend/, ai-backend/ 삭제 완료 ✅
```

---

## 역할 분배 (v3.2 — 최신)

| 역할 | 담당 범위 | 핵심 파일 | 현재 상태 |
|------|----------|----------|----------|
| **리드** | 통합, 코드리뷰, Auto-Claude, E2E | `README.md`, `CLAUDE.md`, `TODO.md` | **P0 완료, E2E 준비** |
| **팀원 A** | Workers Auth+Presets+Rules | `workers/src/auth/`, `rules/`, `presets/` | **✅ 완료** |
| **팀원 B** | Workers Jobs+DO+Queue+R2 | `workers/src/jobs/`, `do/`, `_shared/r2.ts` | **✅ 완료 (14/14)** |
| **팀원 C** | GPU Worker (SAM3+Docker) | `gpu-worker/` | **코드 완성, 배포 필요** |
| **팀원 D** | Flutter (UI+API+Auth+Camera) | `frontend/lib/` | **API 연결 완료, 카메라 홈 통합 (사이드바+칩)** |

---

## 팀원별 즉시 해야 할 일 (2026-02-19)

### 리드: E2E 통합 + R2 Token + 배포 검증

```
1. R2 API Token 생성 (Dashboard → R2 → Manage R2 API Tokens)
   → Workers .dev.vars에 R2_ACCESS_KEY_ID + R2_SECRET_ACCESS_KEY 추가
   → 재배포: cd workers && npx wrangler deploy

2. E2E curl 테스트 (모든 14 엔드포인트)
   → workers/VERIFICATION.md 참조
   → POST /auth/anon → JWT → 나머지 엔드포인트 순회

3. GPU Worker Runpod 배포 지원 (팀원 C 협업)

4. TODO.md Phase D (E2E 통합 테스트) 실행
```

**확인할 파일/경로:**
- `workers/VERIFICATION.md` — curl 테스트 가이드
- `workers/wrangler.toml` — CF 바인딩 현황
- `docs/cloudflare-resources.md` — D1/R2/DO 리소스 ID
- `TODO.md` — Phase A~E 진행 상태

### 팀원 A: ✅ 완료 — 유지보수 대기

```
Workers Auth+Presets+Rules 전부 구현 + 배포 완료.
새 작업 없음. 버그 리포트 시 대응.
```

### 팀원 B: ✅ 완료 — 유지보수 대기

```
Workers Jobs 7개 + DO 2개 + Queue consumer 구현 + 배포 완료.
새 작업 없음. E2E 테스트에서 버그 발견 시 대응.
```

### 팀원 C: GPU Worker Runpod 배포 (P1 — 최우선)

```
1. Docker build 확인
   cd gpu-worker && docker build -t s3-gpu .

2. Docker image → registry (GHCR or Docker Hub)
   docker tag s3-gpu ghcr.io/<org>/s3-gpu:latest
   docker push ghcr.io/<org>/s3-gpu:latest

3. Runpod MCP로 Serverless endpoint 생성
   → Template 생성 (GPU: RTX 4090+, Docker image URL)
   → Endpoint 생성 (min workers: 0, max: 3)

4. 환경변수 설정 (Runpod endpoint에):
   STORAGE_S3_ENDPOINT=<R2 endpoint>
   STORAGE_ACCESS_KEY=<R2 API Token>
   STORAGE_SECRET_KEY=<R2 API Token Secret>
   STORAGE_BUCKET=s3-images
   GPU_CALLBACK_SECRET=<Workers와 동일한 값>
   HF_TOKEN=<HuggingFace access token>

5. SAM3 모델 다운로드 테스트 (3.4GB)

6. E2E: Workers POST /jobs/execute → Queue → GPU Worker 수신 확인
```

**확인할 파일/경로:**
- `gpu-worker/Dockerfile` — Docker 빌드 설정
- `gpu-worker/.env.example` — 필요한 환경변수 목록
- `gpu-worker/main.py` — entry point (ADAPTER 환경변수로 어댑터 선택)
- `gpu-worker/adapters/runpod_serverless.py` — Runpod handler
- `gpu-worker/engine/pipeline.py` — 추론 파이프라인
- `gpu-worker/requirements.txt` — Python 의존성
- `docs/cloudflare-resources.md` — R2 bucket/endpoint 정보
- `workers/.dev.vars.example` — GPU_CALLBACK_SECRET 값 확인

### 팀원 D: Frontend UI 고도화 (P2)

```
P0 연결 완료 + 카메라 홈 통합 완료 (도메인 사이드바 + 컨셉 칩). 남은 작업:

1. 카메라 홈 실기기 테스트 (Android/iOS/Web)
   → ☰ 사이드바 열기 → 도메인 선택 → 컨셉 칩 표시
   → 컨셉 칩 탭 → accent1 하이라이트 토글
   → 도메인 변경 → 컨셉 초기화 확인
   → 사진 촬영 → proceed → /upload?presetId=... 이동

2. Jobs UI 연동 (Workers Jobs 엔드포인트 활용)
   → POST /jobs → presigned URL 받기
   → R2 직접 PUT 업로드 (Dio)
   → POST /confirm-upload
   → POST /execute
   → GET /jobs/:id polling (3초)
   → 결과 이미지 표시

3. workspace_screen.dart → 실제 Job 실행 플로우 연결
   → action_bar.dart "Apply" 버튼 → Jobs API 호출
   → progress_overlay.dart → polling 진행률 표시
   → results_overlay.dart → 결과 이미지 표시

4. 오프라인/에러 처리
   → 카메라 권한 거부 시 UI 처리
   → 네트워크 에러 시 재시도 UX
```

**확인할 파일/경로:**
- `frontend/lib/features/camera/camera_home_screen.dart` — 카메라 홈 (메인 진입점)
- `frontend/lib/features/camera/widgets/domain_drawer.dart` — 도메인 사이드바
- `frontend/lib/features/camera/widgets/concept_chips_bar.dart` — 컨셉 칩 바
- `frontend/lib/features/domain_select/selected_preset_provider.dart` — 도메인 선택 상태
- `frontend/lib/features/workspace/workspace_provider.dart` — addPhotosFromFiles()
- `frontend/lib/features/workspace/workspace_screen.dart` — 메인 작업 영역
- `frontend/lib/features/workspace/widgets/action_bar.dart` — Apply 버튼
- `frontend/lib/features/workspace/widgets/progress_overlay.dart` — 진행률
- `frontend/lib/features/workspace/widgets/results_overlay.dart` — 결과
- `frontend/lib/core/api/api_client.dart` — API 인터페이스 (14 methods)
- `frontend/lib/core/api/s3_api_client.dart` — 실제 Dio 구현
- `frontend/lib/features/workspace/workspace_state.dart` — Phase machine

---

## 완료 체크리스트 (전체)

### Workers (A+B) ✅
- [x] POST /auth/anon → JWT 발급 + D1 user 생성
- [x] Auth middleware → JWT 검증
- [x] GET /presets, GET /presets/:id
- [x] POST/GET/PUT/DELETE /rules
- [x] GET /me → UserLimiterDO 상태
- [x] POST /jobs → presigned URLs
- [x] POST /jobs/:id/confirm-upload
- [x] POST /jobs/:id/execute → Queue push
- [x] GET /jobs/:id → 상태/진행률
- [x] POST /jobs/:id/callback → GPU 콜백
- [x] POST /jobs/:id/cancel
- [x] GET /jobs → 목록
- [x] TypeScript: 0 errors
- [x] 배포 완료

### GPU Worker (C) — 코드 완성, 배포 대기
- [x] R2 download/upload (boto3)
- [x] Callback POST + 재시도
- [x] SAM3 모델 wrapper
- [x] Rule apply (recolor/tone/texture/remove)
- [x] Pipeline orchestrator
- [x] Runpod adapter
- [x] Postprocess (PNG + thumbnail)
- [x] pytest 133개 (mocked)
- [x] Dockerfile 작성
- [ ] **Docker build 성공 확인**
- [ ] **Runpod 배포**
- [ ] **E2E: Workers → Queue → GPU → R2 → Callback**

### Frontend (D) — UI + API 연결 + 카메라 홈 통합 완료
- [x] Auth: 자동 anon 로그인
- [x] Domain: 도메인 선택 화면
- [x] Palette: concept 선택 + protect 토글
- [x] Workspace: 반응형 (데스크톱+모바일)
- [x] Upload: 이미지 선택 + 그리드 표시
- [x] Rules: 룰 편집 + 목록
- [x] API 연결: S3ApiClient + JWT + envelope
- [x] Router: 8 라우트 + auth guard
- [x] Camera: SNOW-style 카메라 화면
- [x] 카메라 홈 통합: 도메인 사이드바 + 컨셉 칩 바
- [x] flutter analyze: 0 errors
- [ ] **Jobs UI 연동 (실제 API 호출)**
- [ ] **R2 presigned URL 업로드**
- [ ] **Polling 진행률 표시**
- [ ] **결과 이미지 표시**
- [ ] **카메라 홈 실기기 테스트 (사이드바+칩 포함)**

### E2E 통합 — 미시작
- [ ] **R2 API Token 생성**
- [ ] **Auth → Presets → Rules → Jobs 전체 흐름**
- [ ] **Workers → Queue → GPU → R2 → Callback**
- [ ] **Flutter → Workers → GPU → 결과 표시**

---

## Workers 라우트 구조 (14/14 완료)

```typescript
// workers/src/index.ts
app.route('/auth', authRoutes);      // POST /auth/anon              ✅
app.route('/presets', presetsRoutes); // GET /presets, /presets/:id   ✅
app.route('/rules', rulesRoutes);     // POST/GET/PUT/DELETE /rules   ✅
app.route('/jobs', jobsRoutes);       // 7개 엔드포인트              ✅
app.route('/me', userRoutes);         // GET /me                     ✅
```

---

## Frontend 아키텍처

### API 호출 흐름

```
Widget → ref.watch(provider) → apiClientProvider → S3ApiClient (Dio)
                                                      │
                                          ┌────────────┤
                                          │            │
                                   Bearer JWT    Envelope unwrap
                                   (SecureStorage)  { success, data } → data
```

### 상태 관리 (Riverpod)

```
authProvider            → AsyncValue<String?>  (JWT token)
userProvider            → AsyncValue<User>     (credits, plan, rule_slots)
presetsProvider         → AsyncValue<List<Preset>>
selectedPresetProvider  → String? (선택된 도메인 ID — 카메라 홈 사이드바)
presetDetailProvider    → AsyncValue<Preset> (도메인 상세 — concepts 포함)
rulesProvider           → AsyncValue<List<Rule>>
paletteProvider         → PaletteState (selectedConcepts, protectConcepts)
workspaceProvider       → WorkspaceState (phase, images, job, results)
```

### Router (GoRouter + Auth Guard)

```
/splash         → SplashScreen (initial, no guard)
/auth           → AuthScreen (auto anon login)
/               → CameraHomeScreen (☰사이드바 + 컨셉칩 + 카메라)
/domain-select  → DomainSelectScreen (fallback — 사이드바 미사용 시)
/palette        → PaletteScreen (?presetId=)
/upload         → UploadScreen (?presetId=&concepts=&protect=)
/rules          → RulesScreen (?jobId=)
/jobs/:id       → JobProgressScreen
/settings       → SettingsScreen
```

---

## 핵심 참조 문서

| 문서 | 용도 | 읽어야 하는 팀원 |
|------|------|----------------|
| `workflow.md` | SSoT — API 스키마, D1 스키마, 전체 설계 | **전원** |
| `README.md` (team/) | 현재 연결 상태, 뭐가 되고 안 되는지 | **전원** |
| `CLAUDE.md` | 코딩 규칙, MCP 도구, 아키텍처 | **전원** |
| `TODO.md` | Phase A~E 실행 계획 + 진행 상태 | **리드** |
| `docs/cloudflare-resources.md` | CF 리소스 (D1 ID, R2 bucket 등) | **리드, C** |
| `docs/project-structure.md` | 폴더 구조 전체 맵 | **전원** |
| `workers/src/_shared/types.ts` | Env 바인딩, 타입 정의 | B (완료) |
| `workers/src/do/*.ts` | DO RPC 메서드 시그니처 | B (완료) |
| `frontend/lib/core/api/api_client.dart` | API 인터페이스 | D |
| `frontend/lib/core/api/s3_api_client.dart` | 실제 API 구현 | D |
| `gpu-worker/engine/pipeline.py` | 추론 파이프라인 | C |
| `gpu-worker/.env.example` | GPU Worker 환경변수 | C |

---

## 규칙

1. **workflow.md = SSoT** — API 스키마는 여기서 확인
2. **types.ts 수정 시 리드 승인** — 전체 타입 시스템에 영향
3. **각자 폴더만 작업** — 충돌 방지
4. **환경변수 하드코딩 금지** — .dev.vars / wrangler.toml secrets 사용
5. **DO는 wrangler deploy 시 자동 생성** — 별도 생성 불필요
6. **UserLimiterDO는 init() 먼저** — getUserState() 전에 반드시 init(userId, plan) 호출
