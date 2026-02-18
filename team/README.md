# S3 팀 작업 가이드 (v2 — 2026-02-18)

> 리드 + AI 팀원 4명 병렬 개발. Cloudflare-native 아키텍처.
> **Supabase 제거됨** → D1 + DO로 대체.

---

## 현재 상태 요약

```
Workers: 8/14 엔드포인트 작동 (auth, presets, rules, me)
         6/14 빈 stub (jobs 전체)
         DO 2개 완전 구현 (호출하는 라우트가 없을 뿐)

Frontend: UI 전부 구현 (workspace, palette, rules, upload, results...)
          API 연결 끊김 (MockApiClient 사용중)
          라우터에 화면 미등록

GPU:     코드 23파일 완성
         Runpod 미배포
```

---

## 역할 분배 (v2)

| 역할 | 담당 범위 | 핵심 파일 | 현재 상태 |
|------|----------|----------|----------|
| **리드** | 통합, 코드리뷰, Auto-Claude | `README.md`, `CLAUDE.md` | 문서 업데이트 중 |
| **팀원 A** | Workers Auth+Presets+Rules | `workers/src/auth/`, `rules/`, `presets/` | **✅ 완료** |
| **팀원 B** | Workers Jobs+DO+Queue+R2 | `workers/src/jobs/`, `do/`, `_shared/r2.ts` | **❌ Jobs 6개 stub** |
| **팀원 C** | GPU Worker (SAM3+Docker) | `gpu-worker/` | **⚠️ 코드 완성, 배포 필요** |
| **팀원 D** | Flutter (UI+API+Auth) | `frontend/lib/` | **❌ Mock→Real 전환 필요** |

---

## 팀원별 즉시 해야 할 일

### 팀원 B: Workers Jobs 구현 (최우선)

**DO가 이미 완전 구현되어 있으므로 라우트 핸들러만 작성.**

파일: `workers/src/jobs/jobs.route.ts`

```
1. POST /jobs
   → CreateJobSchema 검증
   → UserLimiterDO.reserve(jobId, itemCount)
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

**참조 파일:**
- `workers/src/do/JobCoordinatorDO.ts` — RPC 메서드 시그니처
- `workers/src/do/UserLimiterDO.ts` — reserve/release 메서드
- `workers/src/_shared/types.ts` — Env, GpuQueueMessage, CallbackPayload 타입
- `workers/src/_shared/r2.ts` — generatePresignedUrl() 함수
- `workers/src/jobs/jobs.validator.ts` — Zod 스키마 (이미 정의됨)

### 팀원 C: GPU Worker 배포

```
1. gpu-worker/ 에서 Docker build
2. Docker image → registry (GHCR or Docker Hub)
3. Runpod Serverless endpoint 생성
4. endpoint URL을 Workers 환경변수로 설정
```

### 팀원 D: Frontend 연결

```
1. api_endpoints.dart L11:
   'http://localhost:8787' → 'https://s3-workers.clickaround8.workers.dev'

2. api_client_provider.dart L20:
   return MockApiClient(); → return S3ApiClient();

3. auth_provider.dart L22-29:
   login() 안에서 apiClient.createAnonUser() 호출
   → JWT를 SecureStorage에 저장
   → state = AsyncValue.data(token)

4. routing/app_router.dart:
   / → WorkspaceScreen  (메인 화면)
   /auth → AuthScreen    (fallback)
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

## Workers 아키텍처 이해

### 진입점: `workers/src/index.ts`

```typescript
// 라우트 마운트 (prefix 없이 직접 마운트)
app.route('/auth', authRoutes);
app.route('/presets', presetsRoutes);
app.route('/rules', rulesRoutes);
app.route('/jobs', jobsRoutes);
app.route('/me', userRoutes);

// Queue consumer (GPU job 처리)
export default { fetch: app.fetch, queue: async (batch, env) => { ... } }
```

### DO 호출 패턴

```typescript
// UserLimiterDO 호출
const id = env.USER_LIMITER.idFromName(userId);
const stub = env.USER_LIMITER.get(id);
const result = await stub.getUserState();  // RPC 호출

// JobCoordinatorDO 호출
const id = env.JOB_COORDINATOR.idFromName(jobId);
const stub = env.JOB_COORDINATOR.get(id);
const result = await stub.create(jobId, userId, preset, totalItems);
```

### Response Envelope

```typescript
// 모든 응답은 ok() 또는 error()로 감싸기
import { ok, error } from '../_shared/response';
return c.json(ok({ job_id: '...', upload_urls: [...] }));
return c.json(error('CREDIT_INSUFFICIENT', 'Not enough credits'), 402);
```

### Auth Middleware

```typescript
// public path가 아니면 자동으로 JWT 검증
// c.get('user') → { userId: string, plan: string }
const user = c.get('user');
```

---

## Frontend 아키텍처 이해

### API 호출 흐름

```
Widget → ref.watch(someProvider) → Provider → apiClientProvider → ApiClient.method()
                                                                      │
                                                    ┌─────────────────┤
                                                    │                 │
                                              MockApiClient     S3ApiClient
                                              (현재 사용중)      (연결 필요)
```

### S3ApiClient 내부

```dart
// Dio interceptor가 자동으로:
// 1. JWT Bearer 토큰 첨부
// 2. Response envelope { success, data } → data만 추출
```

### 상태 관리 (Riverpod)

```
authProvider       → AsyncValue<String?>  (JWT token)
userProvider       → AsyncValue<User>     (credits, plan, slots)
presetsProvider    → AsyncValue<List<Preset>>
rulesProvider      → AsyncValue<List<Rule>>
paletteProvider    → PaletteState (selectedConcepts, protectConcepts)
workspaceProvider  → WorkspaceState (phase, images, job, results)
```

---

## 규칙

1. **workflow.md = SSoT** — API 스키마는 여기서 확인
2. **types.ts 수정 시 리드 승인** — 전체 타입 시스템에 영향
3. **각자 폴더만 작업** — 충돌 방지
4. **환경변수 하드코딩 금지** — .dev.vars / wrangler.toml secrets 사용
5. **DO는 wrangler deploy 시 자동 생성** — 별도 생성 불필요
6. **R2는 Dashboard에서 수동 활성화** — MCP로 생성 불가
