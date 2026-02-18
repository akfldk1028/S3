# S3 Workers — Cloudflare Workers API

> Hono + CF Workers + D1 + R2 + Durable Objects + Queues
>
> 14 API endpoints + health check. 유일한 API 서버 — Frontend는 Workers만 호출.

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

## API Endpoints (14)

Base: `https://s3-workers.clickaround8.workers.dev`

Auth: `Authorization: Bearer <JWT>` (HS256, Workers-issued)

Response envelope: `{ success, data, error, meta: { request_id, timestamp } }`

| # | Method | Path | Handler |
|---|--------|------|---------|
| 1 | POST | `/auth/anon` | Workers → D1 |
| 2 | GET | `/me` | UserLimiterDO |
| 3 | GET | `/presets` | Workers (hardcoded) |
| 4 | GET | `/presets/{id}` | Workers |
| 5 | POST | `/rules` | UserLimiterDO → D1 |
| 6 | GET | `/rules` | D1 |
| 7 | PUT | `/rules/{id}` | D1 |
| 8 | DELETE | `/rules/{id}` | D1 + UserLimiterDO |
| 9 | POST | `/jobs` | UserLimiterDO → JobCoordinatorDO → R2 |
| 10 | POST | `/jobs/{id}/confirm-upload` | JobCoordinatorDO |
| 11 | POST | `/jobs/{id}/execute` | JobCoordinatorDO → Queue |
| 12 | GET | `/jobs/{id}` | JobCoordinatorDO |
| 13 | POST | `/jobs/{id}/callback` | JobCoordinatorDO (GPU internal) |
| 14 | POST | `/jobs/{id}/cancel` | JobCoordinatorDO → UserLimiterDO |

---

## Project Structure

```
workers/
├── src/
│   ├── index.ts              # Hono app entry + route mounts + queue consumer
│   ├── _shared/
│   │   └── types.ts          # Env, AuthUser, GpuQueueMessage, etc.
│   ├── auth/
│   │   └── auth.route.ts     # POST /auth/anon (JWT issuance)
│   ├── presets/
│   │   └── presets.route.ts  # GET /presets, GET /presets/:id
│   ├── rules/
│   │   └── rules.service.ts  # D1 CRUD for rules
│   ├── user/
│   │   └── user.route.ts     # GET /me
│   ├── jobs/
│   │   ├── jobs.route.ts     # 6 job endpoints
│   │   ├── jobs.service.ts   # R2 presigned URLs, Queue push
│   │   └── jobs.validator.ts # Zod schemas
│   ├── do/
│   │   ├── UserLimiterDO.ts  # Credits + concurrency + rule slots
│   │   └── JobCoordinatorDO.ts # Job state machine + idempotency
│   └── middleware/           # JWT verification, error handler
├── wrangler.toml             # D1, R2, DO, Queue bindings
├── package.json
└── tsconfig.json
```

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
npx wrangler d1 execute s3-db --local --file=schema.sql

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

## Key Design Decisions

- **DO = real-time state, D1 = persistent log** — source of truth is split
- **Queue consumer** in same Workers (MVP: log + ack, production: forward to GPU)
- **Presigned URLs** for R2 upload — Flutter uploads directly to R2, not through Workers
- **HS256 JWT** signed with Workers env secret — no external auth service needed
