# S3 MVP — TODO (Sequential Execution Plan)

> 최종 목표: 4개 spec 코딩+QA → 머지 → 배포 → E2E 연결 확인
> 작성일: 2026-02-14
> 상태: Phase A 진행 중

---

## Phase A: Auto-Build (코딩 + QA) ← 현재 진행 중

daemon이 각 spec 브랜치에서 코딩 → QA를 자동 수행.

### A-1. Spec 002: Workers Foundation (Auth, Presets, Rules)
- [x] Phase 1: Foundation (hono, JWT, auth middleware, wrangler) — 4/4
- [x] Phase 2: Auth API (POST /auth/anon, GET /me) — 2/2
- [x] Phase 3: Presets API (GET /presets, GET /presets/:id) — 2/2
- [x] Phase 4: Rules CRUD (POST/GET/PUT/DELETE /rules) — 5/5
- [x] Phase 5: Integration + D1 migration + E2E verify — 3/3
- [x] 코딩 완료 → **QA 리뷰 진행 중** (status: ai_review)
- [ ] QA 통과 → 자동 머지 대기
- Branch: `auto-claude/002-workers-foundation-schema-auth`

### A-2. Spec 003: Workers Advanced DO (UserLimiter, JobCoordinator, Jobs API)
- [x] Phase 1: Dependencies (AWS SDK, wrangler bindings) — 2/2
- [x] Phase 2: UserLimiterDO (schema, credits, concurrency, getUserState) — 4/4
- [ ] Phase 3: JobCoordinatorDO (schema, FSM, items, idempotency, D1 flush, RPC) — 5/6
- [ ] Phase 4: R2 Presigned URLs — 0/2
- [ ] Phase 5: Jobs API (6 routes) — 0/6
- [ ] Phase 6: GET /me route — 0/1
- [ ] Phase 7: Integration + route mount — 0/2
- [ ] QA 리뷰
- [ ] QA 통과 → 자동 머지 대기
- Branch: `auto-claude/003-workers-advanced-userlimiterdo-jobcoordinatordo`

### A-3. Spec 006: GPU Worker SAM3 ⚠️ **daemon 실행 실패 (Exit code 1, 3회)**
- [ ] **원인 조사 필요**: run.py가 Exit code 1로 즉시 종료
- [ ] 수동 디버깅: `python run.py --spec 006-gpu-worker-sam3-segmenter --project-dir C:\DK\S3`
- [ ] Phase 1: R2 Storage Layer — 0/4
- [ ] Phase 2: SAM3 Segmenter — 0/4
- [ ] Phase 3: Rule Applier — 0/4
- [ ] Phase 4: Callback Integration — 0/4
- [ ] Phase 5: Pipeline Orchestrator — 0/5
- [ ] Phase 6: Runpod Adapter — 0/4
- [ ] Phase 7: Presets & Config — 0/4
- [ ] Phase 8: Docker & Docs — 0/5
- [ ] Phase 9: QA & Security — 0/5
- [ ] QA 통과
- Plan: 9 phases, 39 subtasks

### A-4. Spec 007: Frontend Flutter (Auth, Palette, Jobs, Gallery)
- [ ] Spec 생성 완료 대기 (planner 진행 중)
- [ ] Daemon pickup (touch implementation_plan.json)
- [ ] 코딩 (subtask count TBD)
- [ ] QA 통과
- Branch: TBD

---

## Phase B: 브랜치 머지 + 충돌 해결

각 spec 브랜치를 master에 순차 머지. 충돌 발생 시 수동 해결.

### B-1. Spec 002 브랜치 머지 (Workers Foundation)
- [ ] `git merge auto-claude/002-workers-foundation-schema-auth` → master
- [ ] 충돌 확인 (index.ts, wrangler.toml 주의)
- [ ] `npx tsc --noEmit` 컴파일 확인

### B-2. Spec 003 브랜치 머지 (Workers Advanced DO)
- [ ] `git merge auto-claude/003-workers-advanced-userlimiterdo-jobcoordinatordo` → master
- [ ] 충돌 해결 (index.ts route mount 통합, wrangler.toml DO/Queue 바인딩)
- [ ] `npx tsc --noEmit` 컴파일 확인
- [ ] D1 마이그레이션 스키마 통합 확인

### B-3. Spec 006 브랜치 머지 (GPU Worker)
- [ ] `git merge auto-claude/006-gpu-worker-sam3-segmenter` → master
- [ ] 충돌 없을 것 (독립 디렉토리: gpu-worker/)
- [ ] `python -m py_compile gpu-worker/main.py` 확인

### B-4. Spec 007 브랜치 머지 (Frontend Flutter)
- [ ] `git merge auto-claude/007-frontend-flutter-freezed-models` → master
- [ ] 충돌 없을 것 (독립 디렉토리: frontend/)
- [ ] `flutter analyze` 확인

### B-5. 통합 컴파일 확인
- [ ] Workers: `cd workers && npx tsc --noEmit`
- [ ] GPU Worker: `cd gpu-worker && python -m py_compile main.py`
- [ ] Frontend: `cd frontend && flutter analyze`

---

## Phase C: 배포 준비 (Cloudflare MCP 활용 시작)

> 여기서부터 `cloudflare-observability` + `cloudflare-workers` MCP 적극 활용

### C-1. Cloudflare Workers 배포
- [ ] D1 데이터베이스 생성: `wrangler d1 create s3-db`
- [ ] D1 마이그레이션 실행: `wrangler d1 execute s3-db --file=migrations/0001_schema.sql`
- [ ] R2 버킷 생성: `wrangler r2 bucket create s3-images`
- [ ] Secrets 설정:
  - [ ] `wrangler secret put JWT_SECRET`
  - [ ] `wrangler secret put GPU_CALLBACK_SECRET`
- [ ] Workers 배포: `cd workers && npx wrangler deploy`
- [ ] MCP 확인: `cloudflare-observability` → workers_list, query_worker_observability
- [ ] Health check: `curl https://s3-api.{domain}.workers.dev/health`

### C-2. GPU Worker 배포 (Runpod)
- [ ] Docker 이미지 빌드: `docker build -t s3-gpu-worker gpu-worker/`
- [ ] Docker Hub 또는 GHCR에 push
- [ ] Runpod Template 생성 (MCP runpod 도구 활용 가능)
- [ ] Runpod Serverless Endpoint 생성
- [ ] 환경변수 설정:
  - [ ] R2 credentials (STORAGE_S3_ENDPOINT, ACCESS_KEY, SECRET_KEY)
  - [ ] CALLBACK_URL (Workers endpoint)
  - [ ] GPU_CALLBACK_SECRET
  - [ ] HF_TOKEN (HuggingFace, SAM3 모델 다운로드용)
- [ ] SAM3 모델 다운로드 확인 (3.4GB)

### C-3. Frontend 빌드
- [ ] API base URL 설정: `frontend/lib/core/constants.dart`
- [ ] `flutter build apk --release` 또는 `flutter build web`
- [ ] 빌드 산출물 확인

---

## Phase D: E2E 연결 + 통합 테스트

> 모든 계층이 실제로 연결되는지 확인하는 핵심 단계

### D-1. Auth 흐름 검증
- [ ] Flutter → POST /auth/anon → JWT 수신 확인
- [ ] JWT로 GET /me 호출 → 유저 상태 반환 확인
- [ ] 인증 없이 보호 API 호출 → 401 거부 확인

### D-2. Presets + Rules 흐름 검증
- [ ] GET /presets → interior, seller 도메인 반환 확인
- [ ] GET /presets/interior → concepts, protect_defaults 확인
- [ ] POST /rules → 룰 저장 확인
- [ ] GET /rules → 내 룰 목록 확인
- [ ] PUT /rules/:id → 수정 확인
- [ ] DELETE /rules/:id → 삭제 + 슬롯 반환 확인

### D-3. Jobs 전체 흐름 (핵심!)
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
- [ ] 앱 최초 실행 → 자동 anon 로그인
- [ ] 도메인 선택 (인테리어/셀러)
- [ ] 팔레트 UI: concept 버튼, 인스턴스 카드
- [ ] 이미지 업로드 → 보호 토글 → 룰 구성
- [ ] "적용" 클릭 → 진행률 표시 → 결과 갤러리
- [ ] 세트 내보내기

---

## Phase E: 런칭 전 최종 확인

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
- [ ] Workers production 배포
- [ ] Runpod production endpoint
- [ ] Flutter release build 배포

---

## 현재 상태 요약 (2026-02-14 17:35)

| Spec | 단계 | 진행률 | 상태 |
|------|------|--------|------|
| 002 Workers Foundation | Phase A | 16/16 ✅ | **QA 통과, 머지 대기** |
| 003 Workers Advanced DO | Phase A | 23/23 ✅ | **QA 통과, 머지 대기** |
| 006 GPU Worker | Phase A | 0/21 | **daemon 코딩 중** (PID 24012) |
| 007 Frontend Flutter | Phase A | ~4/28 | **daemon 코딩 중** (PID 24012) |

## 해결된 이슈

1. ~~Spec 006 daemon 실패~~ ✅ **해결**
   - 원인: Windows `nul` 예약 디바이스 파일이 `shutil.copytree`에서 충돌
   - 수정: `setup.py`에 `_ignore_win_reserved` 필터 추가
   - 추가: Python `.pyc` 캐시 삭제, plan 재생성 (0 bytes → 25KB)
   - 추가: `_load_plan`에 `UnicodeDecodeError` 예외 처리 추가

2. ~~Dual daemon 프로세스~~ ✅ **해결**
   - 두 프로세스 모두 종료 후 단일 daemon으로 재시작 (PID 24012)

3. ~~Sleep 방지~~ ✅ **해결**
   - `prevent-sleep.ps1` 실행: 덮개 닫아도 절전 안 됨

## 남은 이슈

1. **Workers index.ts 머지 충돌 예상**: 002와 003 모두 index.ts를 수정
   - Phase B에서 수동 해결 필요
   - 우선 002 머지 → 003 머지 순서로 진행

2. **Cloudflare MCP 미사용 (현재)**: 코딩 단계에서는 context7만 사용
   - Phase C (배포)부터 cloudflare-observability, cloudflare-workers MCP 활용
