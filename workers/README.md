# S3 Workers — Cloudflare Workers API

> Hono + CF Workers + D1 + R2 + Durable Objects + Queues
>
> **14 API endpoints + health check**. 유일한 API 서버 — Frontend는 Workers만 호출.
> 모든 엔드포인트 구현 완료 (2026-02-19).

---

## Architecture

```
Flutter App → Workers (입구) → DO (뇌) → Queue → GPU Worker (근육)
                  ↓                ↓
                 D1              R2
             (영속 기록)      (이미지 저장)
```

| Component | Role |
|-----------|------|
| **Hono routes** | Auth, Presets, Rules, Jobs, User |
| **D1** | Users, rules, jobs_log, job_items_log, billing_events |
| **R2** | Presigned upload/download URLs for images |
| **UserLimiterDO** | Credits, concurrency limits, rule slot enforcement |
| **JobCoordinatorDO** | Job state machine, idempotent callbacks, progress tracking |
| **Queues** | `gpu-jobs` → GPU Worker dispatch + DLQ |

---

## API Endpoints (15 total = 14 business + 1 health)

Base: `https://s3-workers.clickaround8.workers.dev`

Auth: `Authorization: Bearer <JWT>` (HS256, Workers-issued)

Response envelope: `{ success, data, error, meta: { request_id, timestamp } }`

### Auth & User

| # | Method | Path | Handler | Auth |
|---|--------|------|---------|------|
| 0 | GET | `/health` | Workers | No |
| 1 | POST | `/auth/anon` | Workers → D1 (user 생성 + JWT 발급) | No |
| 2 | GET | `/me` | D1 plan → UserLimiterDO.getUserState() | JWT |

### Presets

| # | Method | Path | Handler | Auth |
|---|--------|------|---------|------|
| 3 | GET | `/presets` | Workers (하드코딩 interior + seller) | JWT |
| 4 | GET | `/presets/:id` | Workers | JWT |

### Rules CRUD

| # | Method | Path | Handler | Auth |
|---|--------|------|---------|------|
| 5 | POST | `/rules` | UserLimiterDO.checkRuleSlot → D1 INSERT → incrementSlot | JWT |
| 6 | GET | `/rules` | D1 SELECT (user's rules) | JWT |
| 7 | PUT | `/rules/:id` | D1 UPDATE | JWT |
| 8 | DELETE | `/rules/:id` | D1 DELETE → UserLimiterDO.decrementSlot | JWT |

### Jobs Pipeline

| # | Method | Path | Handler | Auth |
|---|--------|------|---------|------|
| 9 | GET | `/jobs` | D1 SELECT (user's jobs list) | JWT |
| 10 | POST | `/jobs` | UserLimiterDO.reserve → JobCoordinatorDO.create → R2 presigned PUT | JWT |
| 11 | POST | `/jobs/:id/confirm-upload` | JobCoordinatorDO.confirmUpload (created→uploaded) | JWT |
| 12 | POST | `/jobs/:id/execute` | JobCoordinatorDO.markQueued → Queue push (uploaded→queued) | JWT |
| 13 | GET | `/jobs/:id` | JobCoordinatorDO.getStatus + R2 presigned GET (download URLs) | JWT |
| 14 | POST | `/jobs/:id/callback` | JobCoordinatorDO.onItemResult (idempotent) | `X-Callback-Secret` |
| 15 | POST | `/jobs/:id/cancel` | JobCoordinatorDO.cancel + UserLimiterDO.rollback | JWT |

---

## Project Structure

```
workers/
├── src/
│   ├── index.ts                     # Hono app entry + route mounts + queue consumer
│   │
│   ├── _shared/                     # ── 공유 유틸리티 ──
│   │   ├── types.ts                 #   모든 타입 SSoT (Env, Auth, Job, Queue 메시지)
│   │   ├── response.ts             #   ok(data) / error(code, message) 래퍼
│   │   ├── errors.ts               #   에러 코드 상수 (ERR.AUTH_REQUIRED 등)
│   │   ├── jwt.ts                  #   HS256 sign / verify (hono/jwt)
│   │   └── r2.ts                   #   AWS SDK → R2 presigned URL 생성
│   │
│   ├── middleware/
│   │   └── auth.middleware.ts      #   JWT Bearer 검증
│   │                                #   skip: /health, /auth/anon, /jobs/*/callback
│   │
│   ├── auth/                        # ── 인증 ──
│   │   ├── auth.route.ts           #   POST /auth/anon → JWT 발급
│   │   └── auth.service.ts         #   createOrGetUser() + createAuthToken()
│   │
│   ├── user/                        # ── 유저 상태 ──
│   │   └── user.route.ts           #   GET /me → UserLimiterDO.getUserState()
│   │
│   ├── presets/                     # ── 프리셋 ──
│   │   ├── presets.route.ts        #   GET /presets, GET /presets/:id
│   │   └── presets.data.ts         #   하드코딩: interior (12 concepts), seller (6 concepts)
│   │
│   ├── rules/                       # ── 룰 CRUD ──
│   │   ├── rules.route.ts          #   POST / GET / PUT / DELETE /rules
│   │   ├── rules.service.ts        #   D1 CRUD 5개 함수
│   │   └── rules.validator.ts      #   Zod: CreateRuleSchema, UpdateRuleSchema
│   │
│   ├── jobs/                        # ── Job 파이프라인 (7 endpoints) ──
│   │   ├── jobs.route.ts           #   GET /jobs (목록)
│   │   │                            #   POST /jobs (생성 + presigned upload URLs)
│   │   │                            #   POST /jobs/:id/confirm-upload (created→uploaded)
│   │   │                            #   POST /jobs/:id/execute (Queue push)
│   │   │                            #   GET /jobs/:id (상태 + download URLs)
│   │   │                            #   POST /jobs/:id/callback (GPU 콜백, X-Callback-Secret)
│   │   │                            #   POST /jobs/:id/cancel (취소 + 크레딧 환불)
│   │   ├── jobs.service.ts         #   generateUploadUrls(), generateDownloadUrls(), pushToQueue()
│   │   └── jobs.validator.ts       #   Zod: CreateJobSchema, ExecuteJobSchema, CallbackSchema
│   │
│   └── do/                          # ── Durable Objects (뇌) ──
│       ├── UserLimiterDO.ts         #   유저당 1개: 크레딧/동시성/룰슬롯
│       │                            #   init, getUserState, reserve, commit, rollback, release
│       │                            #   checkRuleSlot, incrementRuleSlot, decrementRuleSlot
│       ├── JobCoordinatorDO.ts      #   Job당 1개: FSM 상태머신
│       │                            #   create, confirmUpload, markQueued, onItemResult
│       │                            #   getStatus, cancel, alarm (D1 flush + release)
│       │                            #   멱등성 ring buffer (512)
│       └── do.helpers.ts            #   getUserLimiterStub(), getJobCoordinatorStub()
│
├── migrations/
│   └── 0001_init.sql                # D1 스키마: 5 tables + 4 indexes
│
├── wrangler.toml                    # CF 바인딩: D1(s3-db), R2(s3-images), DO×2, Queue(gpu-jobs)
├── package.json                     # hono, zod, @aws-sdk/client-s3, @cloudflare/workers-types
├── tsconfig.json                    # ES2022, strict
└── .dev.vars.example                # JWT_SECRET, GPU_CALLBACK_SECRET, R2 credentials
```

---

## Job FSM (State Machine)

```
created → uploaded → queued → running → done
                                     → failed
    ↓         ↓         ↓        ↓
          canceled (any non-terminal → canceled)
```

| Transition | Trigger | Route |
|-----------|---------|-------|
| → created | POST /jobs (UserLimiterDO.reserve 성공) | POST /jobs |
| created → uploaded | confirmUpload() | POST /jobs/:id/confirm-upload |
| uploaded → queued | markQueued() + Queue push | POST /jobs/:id/execute |
| queued → running | 첫 번째 onItemResult() callback | POST /jobs/:id/callback |
| running → done | done + failed == total, done > 0 | POST /jobs/:id/callback |
| running → failed | done + failed == total, done == 0 | POST /jobs/:id/callback |
| any → canceled | cancel() + rollback() | POST /jobs/:id/cancel |

Terminal states trigger alarm → D1 flush + UserLimiterDO.release()

---

## Env Bindings (wrangler.toml)

| Binding | Type | Name/Value |
|---------|------|------------|
| `DB` | D1Database | `s3-db` |
| `R2` | R2Bucket | `s3-images` |
| `USER_LIMITER` | DurableObjectNamespace | UserLimiterDO class |
| `JOB_COORDINATOR` | DurableObjectNamespace | JobCoordinatorDO class |
| `GPU_QUEUE` | Queue | `gpu-jobs` |
| `JWT_SECRET` | Secret | .dev.vars / CF Dashboard |
| `GPU_CALLBACK_SECRET` | Secret | .dev.vars / CF Dashboard |
| `R2_ACCOUNT_ID` | Secret | R2 presigned URL 생성용 |
| `R2_ACCESS_KEY_ID` | Secret | R2 presigned URL 생성용 |
| `R2_SECRET_ACCESS_KEY` | Secret | R2 presigned URL 생성용 |
| `R2_BUCKET_NAME` | Var | `s3-images` |

---

## Cloudflare Resources

| Resource | Name/ID |
|----------|---------|
| **Workers** | `s3-workers` |
| **D1** | `s3-db` (`9e2d53af-ba37-4128-9ef8-0476ace30efa`) |
| **R2** | `s3-images` |
| **Queues** | `gpu-jobs` + `gpu-jobs-dlq` |
| **DO** | UserLimiterDO, JobCoordinatorDO |
| **Account** | `2c1b8299e2d8cec3f82a016fa88368aa` |

---

## Commands

```bash
# Install
npm install

# Local dev (D1/R2/DO simulated)
npx wrangler dev

# Deploy
npx wrangler deploy

# D1 migration
npx wrangler d1 execute s3-db --local --file=migrations/0001_init.sql

# Type check
npx tsc --noEmit
```

---

## Route Mounting

Routes are mounted directly at root (NO `/api/` prefix):

```typescript
// index.ts
app.route('/auth', authRoutes);
app.route('/presets', presetRoutes);
app.route('/rules', rulesRoutes);
app.route('/jobs', jobsRoutes);
app.route('/me', userRoutes);
```

---

## Module Dependency Rules

```
routes ──▶ validators (Zod) ──▶ parse request body
routes ──▶ services ──▶ D1 (queries) + R2 (presigned URLs) + Queue (push)
routes ──▶ DO stubs (UserLimiterDO, JobCoordinatorDO) ──▶ state management
middleware ──▶ _shared/jwt ──▶ verify Bearer token
DO ──▶ D1 (alarm-based flush to jobs_log, job_items_log)
DO ✕──▶ DO (직접 호출 금지, route가 중개)
```

---

## Key Design Decisions

- **DO = real-time state, D1 = persistent log** — source of truth is split
- **Queue consumer** in same Workers (MVP: log + ack, production: forward to GPU)
- **Presigned URLs** for R2 upload — Flutter uploads directly to R2, not through Workers
- **HS256 JWT** signed with Workers env secret — no external auth service needed
- **Callback auth** via `X-Callback-Secret` header (NOT JWT) — GPU Worker doesn't have JWT
- **Idempotency** via ring buffer (512 keys) in JobCoordinatorDO — duplicate callbacks safe
- **Alarm-based D1 flush** — terminal states trigger 5s delayed alarm for batch writing

---

## For AI Agents

**수정 전 반드시 읽을 파일:**

| 무엇을 할 때 | 이 파일을 읽어라 |
|-------------|----------------|
| 타입 추가/변경 | `src/_shared/types.ts` |
| 에러 코드 추가 | `src/_shared/errors.ts` |
| 새 라우트 추가 | 기존 `rules.route.ts` 패턴 참조 |
| DO 메서드 호출 | `src/do/UserLimiterDO.ts`, `JobCoordinatorDO.ts` |
| R2 URL 생성 | `src/_shared/r2.ts` |
| Zod 스키마 추가 | `src/jobs/jobs.validator.ts` 참조 |
| D1 쿼리 추가 | `src/rules/rules.service.ts` 참조 |
| 전체 API 스펙 | 루트 `workflow.md` 섹션 6 |
