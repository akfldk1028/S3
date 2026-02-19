# S3 MVP — TODO (Sequential Execution Plan)

> 최종 목표: Workers + GPU + Frontend E2E 연결 → 프로덕션 배포
> 작성일: 2026-02-14 | **최종 업데이트: 2026-02-19**
> 상태: **Phase A~C 부분 완료, Phase D 진입 준비**

---

## Phase A: 코딩 ✅ 완료

### A-1. Spec 002: Workers Foundation (Auth, Presets, Rules) ✅
- [x] Phase 1: Foundation (hono, JWT, auth middleware, wrangler) — 4/4
- [x] Phase 2: Auth API (POST /auth/anon, GET /me) — 2/2
- [x] Phase 3: Presets API (GET /presets, GET /presets/:id) — 2/2
- [x] Phase 4: Rules CRUD (POST/GET/PUT/DELETE /rules) — 5/5
- [x] Phase 5: Integration + D1 migration + E2E verify — 3/3
- [x] QA 통과 + master 머지 완료

### A-2. Spec 003: Workers Advanced DO (UserLimiter, JobCoordinator, Jobs API) ✅
- [x] Phase 1: Dependencies (AWS SDK, wrangler bindings) — 2/2
- [x] Phase 2: UserLimiterDO (schema, credits, concurrency, getUserState) — 4/4
- [x] Phase 3: JobCoordinatorDO (schema, FSM, items, idempotency, D1 flush, RPC) — 6/6
- [x] Phase 4: R2 Presigned URLs — 2/2
- [x] Phase 5: Jobs API (7 routes) — 7/7
- [x] Phase 6: GET /me route — 1/1
- [x] Phase 7: Integration + route mount — 2/2
- [x] QA 통과 + master 머지 완료

### A-3. Spec 006: GPU Worker SAM3 ✅ (코드 완성)
- [x] Phase 1: R2 Storage Layer — 4/4
- [x] Phase 2: SAM3 Segmenter — 4/4
- [x] Phase 3: Rule Applier — 4/4
- [x] Phase 4: Callback Integration — 4/4
- [x] Phase 5: Pipeline Orchestrator — 5/5
- [x] Phase 6: Runpod Adapter — 4/4
- [x] Phase 7: Presets & Config — 4/4
- [x] Phase 8: Docker & Docs — 5/5
- [x] Phase 9: Tests (133개 mocked) — 5/5
- [x] master 머지 완료

### A-4. Frontend Flutter ✅ (UI + API 연결 + 카메라 홈 통합 완료)
- [x] Auth (anon JWT + SecureStorage)
- [x] GoRouter 8 라우트 + auth guard
- [x] S3ApiClient (Dio + JWT + envelope unwrap)
- [x] Workspace 반응형 UI (데스크톱+모바일)
- [x] Photo grid + concepts + protect + rules sections
- [x] SNOW-style 카메라 화면 (`camera` 패키지)
- [x] Android/iOS 카메라 권한 설정
- [x] 카메라 홈 도메인 사이드바 (☰ → DomainDrawer)
- [x] 카메라 홈 컨셉 칩 바 (ConceptChipsBar)
- [x] selectedPresetProvider (도메인 선택 → 컨셉 자동 로드)
- [x] proceed 로직: 도메인 선택됨 → /upload 직행, 미선택 → /domain-select
- [x] flutter analyze: 0 errors

---

## Phase B: 브랜치 머지 ✅ 완료

- [x] Spec 002 머지 → master
- [x] Spec 003 머지 → master (index.ts 충돌 해결)
- [x] Spec 006 머지 → master
- [x] Frontend 통합 → master
- [x] 레거시 삭제: `cf-backend/`, `ai-backend/`
- [x] Workers: `npx tsc --noEmit` — 0 errors
- [x] Frontend: `flutter analyze` — 0 errors

---

## Phase C: 배포 — 부분 완료

### C-1. Cloudflare Workers 배포 ✅
- [x] D1 데이터베이스 생성: `s3-db` (ID: `9e2d53af-ba37-4128-9ef8-0476ace30efa`)
- [x] D1 마이그레이션 실행: 5 tables + 4 indexes
- [x] R2 버킷 생성: `s3-images`
- [x] Queue 생성: `gpu-jobs` + `gpu-jobs-dlq`
- [x] Secrets: JWT_SECRET, GPU_CALLBACK_SECRET
- [x] Workers 배포: `https://s3-workers.clickaround8.workers.dev`
- [x] DO 자동 생성: UserLimiterDO, JobCoordinatorDO
- [x] 14/14 엔드포인트 동작 확인

### C-2. R2 API Token ❌ — P0 블로커
- [ ] **CF Dashboard → R2 → Manage R2 API Tokens → Create**
- [ ] Permission: Object Read & Write, Bucket: s3-images
- [ ] `wrangler secret put R2_ACCESS_KEY_ID`
- [ ] `wrangler secret put R2_SECRET_ACCESS_KEY`
- [ ] 재배포: `cd workers && npx wrangler deploy`
- [ ] presigned URL 동작 확인

> ⚠️ **이것 없으면 presigned URL 전부 실패 → Jobs 업로드 불가**

### C-3. GPU Worker 배포 (Runpod) ❌ — P1
- [ ] Docker build: `cd gpu-worker && docker build -t s3-gpu .`
- [ ] Docker registry push (GHCR or Docker Hub)
- [ ] Runpod Template 생성 (GPU: RTX 4090+)
- [ ] Runpod Serverless Endpoint 생성
- [ ] 환경변수 설정:
  - [ ] STORAGE_S3_ENDPOINT (R2 endpoint)
  - [ ] STORAGE_ACCESS_KEY (R2 Token)
  - [ ] STORAGE_SECRET_KEY (R2 Token)
  - [ ] STORAGE_BUCKET=s3-images
  - [ ] GPU_CALLBACK_SECRET (Workers와 동일)
  - [ ] HF_TOKEN (HuggingFace)
  - [ ] ADAPTER=runpod
- [ ] SAM3 모델 다운로드 테스트 (3.4GB)
- [ ] Queue 수신 확인

### C-4. Frontend Jobs UI 연동 ❌ — P1
- [ ] POST /jobs → presigned URLs 수신
- [ ] R2 presigned PUT 업로드 (`workspace_provider.dart`의 `_uploadOne` 활용)
- [ ] POST /jobs/:id/confirm-upload
- [ ] POST /jobs/:id/execute { concepts, protect, rule_id }
- [ ] GET /jobs/:id polling (3초) → 진행률
- [ ] 결과 이미지 표시 (presigned GET URL)
- [ ] Job 취소 (POST /cancel)

### C-5. Frontend 카메라 홈 실기기 테스트 ❌ — P1
- [ ] Android: 카메라 프리뷰 + 촬영 + 갤러리
- [ ] iOS: 카메라 프리뷰 + 촬영 + 갤러리
- [ ] 플래시 토글 (OFF/AUTO/ON)
- [ ] 전면/후면 카메라 전환
- [ ] ☰ 사이드바: 도메인 목록 표시 + 선택
- [ ] 컨셉 칩: 도메인 선택 후 concepts 표시 + 토글
- [ ] 도메인 변경 시 컨셉 초기화 확인
- [ ] proceed: 도메인 선택됨 → /upload, 미선택 → /domain-select
- [ ] 웹: 갤러리 + 사이드바 + 컨셉 칩 동작 확인

### C-6. Frontend 빌드 ⏳ (E2E 후)
- [ ] API base URL 확인: `frontend/lib/constants/api_endpoints.dart`
- [ ] `flutter build apk --release`
- [ ] `flutter build web`
- [ ] 빌드 산출물 확인

---

## Phase D: E2E 연결 + 통합 테스트 ❌ — 미시작

> **전제조건**: C-2 (R2 Token) + C-3 (GPU 배포) + C-4 (Jobs UI) 완료 필요

### D-1. Auth 흐름 검증
- [x] Flutter → POST /auth/anon → JWT 수신 ✅ (P0에서 확인)
- [x] JWT로 GET /me 호출 → 유저 상태 반환 ✅
- [ ] 인증 없이 보호 API 호출 → 401 거부 확인

### D-2. Presets + Rules 흐름 검증
- [x] GET /presets → interior, seller 도메인 반환 ✅
- [x] GET /presets/interior → concepts, protect_defaults ✅
- [ ] POST /rules → 룰 저장 확인 (Flutter에서)
- [ ] GET /rules → 내 룰 목록 확인 (Flutter에서)
- [ ] PUT /rules/:id → 수정 확인 (Flutter에서)
- [ ] DELETE /rules/:id → 삭제 + 슬롯 반환 확인 (Flutter에서)

### D-3. Jobs 전체 흐름 (핵심!) ❌
- [ ] POST /jobs → job_id + presigned URLs 반환
- [ ] R2 직접 업로드 (presigned URL 사용)
- [ ] POST /jobs/:id/confirm-upload → uploaded 상태 전환
- [ ] POST /jobs/:id/execute → queued 상태 전환 + Queue push
- [ ] GPU Worker가 Queue에서 job 수신 확인
- [ ] GPU Worker: R2 이미지 다운로드 → SAM3 segment → rule apply
- [ ] GPU Worker: 결과 R2 업로드 + POST /jobs/:id/callback
- [ ] Workers: callback 처리 → 진행률 갱신
- [ ] GET /jobs/:id → done 상태 + 결과 URL 확인
- [ ] Flutter: polling → 결과 표시 확인

### D-4. 보호/제한 기능 검증
- [ ] Free plan: 동시 1 job, 룰 2개, 배치 10장 제한 확인
- [ ] 크레딧 부족 시 Job 거부 확인
- [ ] Job 취소 → 크레딧 환불 확인
- [ ] Callback 중복 방지 (idempotency key) 확인

### D-5. Flutter UI 전체 흐름
- [ ] 앱 최초 실행 → 자동 anon 로그인 → 카메라 홈
- [ ] ☰ 사이드바에서 도메인 선택 (인테리어/셀러)
- [ ] 컨셉 칩 바에서 concept 선택
- [ ] 카메라 촬영 또는 갤러리 선택
- [ ] proceed → /upload?presetId=... (도메인 선택 페이지 스킵)
- [ ] 룰 구성 + 저장
- [ ] "적용" 클릭 → 업로드 → 진행률 표시 → 결과 갤러리
- [ ] 세트 내보내기

---

## Phase E: 런칭 전 최종 확인 ❌ — 미시작

### E-1. 보안 점검
- [ ] JWT_SECRET 강도 확인 (32+ chars random)
- [ ] GPU_CALLBACK_SECRET 확인
- [ ] CORS 설정 확인 (Workers)
- [ ] Rate limiting 확인 (UserLimiterDO)
- [ ] .env, .dev.vars 커밋 안 됐는지 확인

### E-2. 모니터링 설정
- [ ] Cloudflare Workers Analytics 대시보드 확인
- [ ] Runpod Endpoint 모니터링 확인
- [ ] 에러 알림 설정 (선택)

### E-3. 프로덕션 배포
- [ ] Workers production 배포 (이미 완료, 재확인)
- [ ] Runpod production endpoint
- [ ] Flutter release build (APK/Web)
- [ ] 앱스토어 제출 준비 (선택)

---

## 현재 상태 요약 (2026-02-19)

| 영역 | Phase A (코딩) | Phase B (머지) | Phase C (배포) | Phase D (E2E) |
|------|:-:|:-:|:-:|:-:|
| Workers (A+B) | ✅ 14/14 | ✅ | ✅ 배포됨 | ⏳ |
| GPU Worker (C) | ✅ 23파일 | ✅ | ❌ Runpod 미배포 | ❌ |
| Frontend (D) | ✅ UI+API | ✅ | ❌ Jobs 미연동 | ❌ |

### 의존성 체인 (블로커 순서)

```
C-2. R2 Token 생성 ←── P0 (모든 것의 전제)
  │
  ├── C-3. GPU Runpod 배포 ←── P1 (R2 Token 필요)
  │     │
  │     └── D-3. Jobs E2E (Queue → GPU → Callback)
  │
  ├── C-4. Jobs UI 연동 ←── P1 (presigned URL 필요)
  │     │
  │     └── D-5. Flutter 전체 흐름
  │
  └── C-5. 카메라 실기기 테스트 ←── P1 (독립)
        │
        └── D-5. Flutter 전체 흐름
```

---

## 해결된 이슈

1. ~~Spec 006 daemon 실패~~ ✅ — Windows `nul` 예약 파일 → `_ignore_win_reserved` 필터
2. ~~Dual daemon 프로세스~~ ✅ — 단일 daemon 재시작
3. ~~Sleep 방지~~ ✅ — `prevent-sleep.ps1`
4. ~~Workers index.ts 머지 충돌~~ ✅ — 수동 해결 완료
5. ~~Frontend ↔ Workers 연결~~ ✅ — P0 수리 (2026-02-18)
6. ~~DO init() 누락 버그~~ ✅ — rules/user route 수정
7. ~~레거시 폴더 삭제~~ ✅ — cf-backend/, ai-backend/ 삭제 (프롬프트 보존)

## 남은 이슈

1. **R2 API Token 미생성** — presigned URL 블로커 → Dashboard에서 수동 생성 필요
2. **GPU Worker Runpod 미배포** — 코드 완성, Docker + 배포 필요
3. **Jobs UI 미연동** — Frontend에서 POST /jobs ~ polling 미구현
4. **카메라 홈 실기기 미테스트** — 사이드바+칩 통합 완료, Android/iOS/Web 실행 필요
