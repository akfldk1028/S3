# S3 팀 작업 가이드 (v3.1 — 2026-02-18)

> 리드 + AI 팀원 4명 병렬 개발. Cloudflare-native 아키텍처.
> **Supabase 제거됨** → D1 + DO로 대체.

---

## 현재 상태 요약

```
Workers: 9/14 엔드포인트 작동 (auth, presets, rules, me + health)
         6/14 빈 stub (jobs 전체)
         DO 2개 완전 구현 (호출하는 라우트가 없을 뿐)
         버그 수정 배포 완료: DO init() 누락, async/await 정리

Frontend: UI 전부 구현 + Workers API 연결 완료
          S3ApiClient 사용 (JWT + envelope unwrap)
          8개 라우트 + auth guard 작동

GPU:     코드 23파일 완성
         Runpod 미배포
```

---

## 역할 분배 (v3)

| 역할 | 담당 범위 | 핵심 파일 | 현재 상태 |
|------|----------|----------|----------|
| **리드** | 통합, 코드리뷰, Auto-Claude | `README.md`, `CLAUDE.md` | P0 연결 완료 |
| **팀원 A** | Workers Auth+Presets+Rules | `workers/src/auth/`, `rules/`, `presets/` | **완료** |
| **팀원 B** | Workers Jobs+DO+Queue+R2 | `workers/src/jobs/`, `do/`, `_shared/r2.ts` | **Jobs 6개 stub** |
| **팀원 C** | GPU Worker (SAM3+Docker) | `gpu-worker/` | **코드 완성, 배포 필요** |
| **팀원 D** | Flutter (UI+API+Auth) | `frontend/lib/` | **API 연결 완료** |

---

## P0 완료 (2026-02-18) — Frontend ↔ Workers 연결

### 작동하는 것

```
Flutter App → POST /auth/anon → JWT 획득 → SecureStorage 저장    ✅
Flutter App → GET /me → { user_id, plan, credits, rule_slots }   ✅
Flutter App → GET /presets → 도메인 프리셋 목록                    ✅
Flutter App → GET /rules → 내 룰 목록                             ✅
Flutter App → POST/PUT/DELETE /rules → 룰 CRUD                   ✅
GoRouter auth guard → 미인증 /auth, 인증 /domain-select           ✅
```

### 수정된 파일

| 계층 | 파일 | 변경 |
|------|------|------|
| Frontend | `api_endpoints.dart` | baseUrl → production Workers URL |
| Frontend | `api_client_provider.dart` | MockApiClient → S3ApiClient |
| Frontend | `auth_provider.dart` | login() → POST /auth/anon + JWT 저장 |
| Frontend | `user_model.dart` | User/LoginResponse → Workers 응답 형식 |
| Frontend | `user_provider.dart` | getMeQuery → apiClientProvider.getMe() |
| Frontend | `app_router.dart` | 4→8 라우트 + auth guard |
| Frontend | `splash_screen.dart` | authStateProvider → authProvider |
| Workers | `index.ts` | `/user` → `/me` 마운트 |
| Workers | `user.route.ts` | 응답 snake_case + DO init 추가 |
| Workers | `auth.route.ts` | 중복 GET /me 제거 |

### 버그 수정 (2026-02-18, 배포 완료)

| 파일 | 수정 내용 |
|------|----------|
| `do/JobCoordinatorDO.ts` | `transitionState()` async → sync (sql.exec은 동기). `confirmUpload()`, `markQueued()` 도 sync로 전환 |
| `rules/rules.route.ts` | POST /rules, DELETE /rules/:id에서 DO `init()` 누락 → D1 plan 조회 + `init()` 추가 (미호출 시 500 에러) |
| `auth/auth.route.ts` | 중복 GET /me 핸들러 제거 (이전 수정) |

---

## 팀원별 즉시 해야 할 일

### 팀원 B: Workers Jobs 구현 (최우선 — P1)

**DO가 이미 완전 구현되어 있으므로 라우트 핸들러만 작성.**

파일: `workers/src/jobs/jobs.route.ts`

```
1. POST /jobs
   → CreateJobSchema 검증
   → UserLimiterDO.init(userId, plan) + reserve(jobId, itemCount)
   → JobCoordinatorDO.create(jobId, userId, preset, totalItems)
   → r2.ts의 generatePresignedUrl() 호출 (PUT URL 생성)
   → 응답: { job_id, upload_urls: [...] }

2. POST /jobs/:id/confirm-upload
   → JobCoordinatorDO.confirmUpload()

3. POST /jobs/:id/execute
   → ExecuteJobSchema 검증
   → JobCoordinatorDO.markQueued(conceptsJson, protectJson, ruleId)
   → GPU_QUEUE.send(GpuQueueMessage)

4. GET /jobs/:id
   → JobCoordinatorDO.getStatus()
   → 완료된 item에 presigned download URL 추가

5. POST /jobs/:id/callback
   → GPU_CALLBACK_SECRET 검증
   → CallbackSchema 검증
   → JobCoordinatorDO.onItemResult(payload)

6. POST /jobs/:id/cancel
   → JobCoordinatorDO.cancel()
```

**주의**: UserLimiterDO는 `init(userId, plan)` 호출 후에만 `getUserState()` 가능. INSERT OR IGNORE라서 반복 호출 안전.

**참조 파일:**
- `workers/src/do/JobCoordinatorDO.ts` — RPC 메서드 시그니처
- `workers/src/do/UserLimiterDO.ts` — init/reserve/release 메서드
- `workers/src/_shared/types.ts` — Env, GpuQueueMessage, CallbackPayload 타입
- `workers/src/_shared/r2.ts` — generatePresignedUrl() 함수
- `workers/src/jobs/jobs.validator.ts` — Zod 스키마 (이미 정의됨)

### 팀원 C: GPU Worker 배포 (P2)

```
1. gpu-worker/ 에서 Docker build
2. Docker image → registry (GHCR or Docker Hub)
3. Runpod Serverless endpoint 생성
4. endpoint URL을 Workers 환경변수로 설정
```

### 팀원 D: Frontend — Jobs UI 연동 (P1 완료 후)

```
P0 연결 완료 → Jobs 엔드포인트가 구현되면:
1. POST /jobs → presigned URL 받기
2. R2 직접 PUT 업로드
3. POST /confirm-upload
4. POST /execute
5. GET /jobs/:id polling (3초)
6. 결과 이미지 표시
```

---

## Workers 라우트 구조

```typescript
// workers/src/index.ts
app.route('/auth', authRoutes);     // POST /auth/anon
app.route('/presets', presetsRoutes); // GET /presets, /presets/:id
app.route('/rules', rulesRoutes);    // POST/GET/PUT/DELETE /rules
app.route('/jobs', jobsRoutes);      // 6개 stub
app.route('/me', userRoutes);        // GET /me (UserLimiterDO)
```

### DO 호출 패턴

```typescript
// UserLimiterDO — 반드시 init() 먼저 (D1에서 plan 조회 필수)
const userRow = await c.env.DB
  .prepare('SELECT plan FROM users WHERE id = ?')
  .bind(user.userId)
  .first<{ plan: 'free' | 'pro' }>();
const plan = userRow?.plan ?? 'free';

const limiterNs = c.env.USER_LIMITER as unknown as DurableObjectNamespace<UserLimiterDO>;
const limiterStub = limiterNs.get(limiterNs.idFromName(user.userId));
await limiterStub.init(user.userId, plan);  // INSERT OR IGNORE (반복 호출 안전)
const state = await limiterStub.getUserState();

// JobCoordinatorDO — confirmUpload(), markQueued()는 sync (await 불필요)
const coordNs = c.env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
const coordStub = coordNs.get(coordNs.idFromName(jobId));
await coordStub.create(jobId, userId, preset, totalItems);
const result = coordStub.confirmUpload();  // sync — no await needed
```

> **주의**: DO 메서드 호출 전에 반드시 `init()` 먼저. `user.route.ts`, `rules.route.ts` 모두 이 패턴 적용됨.

### Response Envelope

```typescript
import { ok, error } from '../_shared/response';
return c.json(ok({ job_id: '...', upload_urls: [...] }));
return c.json(error('CREDIT_INSUFFICIENT', 'Not enough credits'), 402);
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
authProvider       → AsyncValue<String?>  (JWT token)
userProvider       → AsyncValue<User>     (credits, plan, rule_slots)
presetsProvider    → AsyncValue<List<Preset>>
rulesProvider      → AsyncValue<List<Rule>>
paletteProvider    → PaletteState (selectedConcepts, protectConcepts)
workspaceProvider  → WorkspaceState (phase, images, job, results)
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

---

## 핵심 참조 문서

| 문서 | 용도 | 읽어야 하는 팀원 |
|------|------|----------------|
| `workflow.md` | SSoT — API 스키마, D1 스키마, 전체 설계 | **전원** |
| `README.md` | 현재 연결 상태, 뭐가 되고 안 되는지 | **전원** |
| `CLAUDE.md` | 코딩 규칙, MCP 도구, 아키텍처 | **전원** |
| `workers/src/_shared/types.ts` | Env 바인딩, PLAN_LIMITS, 타입 정의 | B |
| `workers/src/do/*.ts` | DO RPC 메서드 시그니처 | B |
| `frontend/lib/core/api/api_client.dart` | API 인터페이스 | D |
| `frontend/lib/core/api/s3_api_client.dart` | 실제 API 구현 | D |

---

## 규칙

1. **workflow.md = SSoT** — API 스키마는 여기서 확인
2. **types.ts 수정 시 리드 승인** — 전체 타입 시스템에 영향
3. **각자 폴더만 작업** — 충돌 방지
4. **환경변수 하드코딩 금지** — .dev.vars / wrangler.toml secrets 사용
5. **DO는 wrangler deploy 시 자동 생성** — 별도 생성 불필요
6. **UserLimiterDO는 init() 먼저** — getUserState() 전에 반드시 init(userId, plan) 호출
