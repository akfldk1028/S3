# S3 Cloudflare 리소스 현황

> 최종 업데이트: 2026-02-15
> Account: Clickaround8@gmail.com (`2c1b8299e2d8cec3f82a016fa88368aa`)
> Subdomain: `clickaround8.workers.dev`

---

## 생성된 리소스 요약

| 리소스 | 이름 | 요금 | 비고 |
|--------|------|------|------|
| **Workers** | `s3-workers` | Free (100K req/day) | Hono + DO + Queue consumer |
| **D1** | `s3-db` | Free (5M rows/day read, 100K write) | SQLite, 5 tables |
| **R2** | `s3-images` | Free (10GB storage, 10M Class B/month) | 이미지 저장 |
| **Durable Objects** | UserLimiterDO, JobCoordinatorDO | Workers 요금에 포함 | SQLite backing |
| **Queues** | `gpu-jobs`, `gpu-jobs-dlq` | Free (1M msgs/month) | GPU 작업 분배 |

> **총 비용: $0 (Free Plan)** — 트래픽 증가 시 Workers Paid ($5/mo) 전환 필요

---

## Workers

- **URL**: `https://s3-workers.clickaround8.workers.dev`
- **Entry**: `workers/src/index.ts`
- **Framework**: Hono
- **Bindings**: DB (D1), R2, GPU_QUEUE (Queue), USER_LIMITER (DO), JOB_COORDINATOR (DO)

### Endpoints (14개)
```
POST   /auth/anon              # 익명 JWT 발급
GET    /me                     # 유저 상태 조회
GET    /presets                 # 프리셋 목록
GET    /presets/:id             # 프리셋 상세
POST   /rules                  # 룰 저장
GET    /rules                  # 내 룰 목록
PUT    /rules/:id              # 룰 수정
DELETE /rules/:id              # 룰 삭제
POST   /jobs                   # Job 생성 + presigned URLs
POST   /jobs/:id/confirm-upload # 업로드 확인
POST   /jobs/:id/execute       # 실행 (Queue push)
GET    /jobs/:id               # 상태 조회
POST   /jobs/:id/callback      # GPU 콜백 (내부)
POST   /jobs/:id/cancel        # 취소
GET    /health                 # 헬스체크
```

### Secrets (wrangler secret put)
```
JWT_SECRET              # JWT HS256 서명키 (32+ chars)
GPU_CALLBACK_SECRET     # GPU Worker 콜백 인증키
```

---

## D1 Database

- **Name**: `s3-db`
- **ID**: `9e2d53af-ba37-4128-9ef8-0476ace30efa`
- **Binding**: `DB`

### 테이블 (5개)
```sql
users              -- 유저 (id, plan, credits, device_hash, created_at)
rules              -- 룰 저장 (user_id, name, preset_id, concepts_json, protect_json)
jobs_log           -- Job 히스토리 (user_id, status, preset, rule_id, cost_estimate)
job_items_log      -- Item 히스토리 (job_id, idx, status, input_key, output_key)
billing_events     -- 정산 (user_id, type, amount, ref)
```

### 인덱스 (4개)
```sql
idx_rules_user_id
idx_jobs_log_user_id
idx_job_items_log_job_id
idx_billing_events_user_id
```

### 마이그레이션
```bash
# 로컬
npx wrangler d1 execute DB --local --file=workers/migrations/0001_schema.sql

# 프로덕션
npx wrangler d1 execute s3-db --file=workers/migrations/0001_schema.sql
```

---

## R2 Storage

- **Bucket**: `s3-images`
- **Binding**: `R2`
- **S3 호환 Endpoint**: `https://2c1b8299e2d8cec3f82a016fa88368aa.r2.cloudflarestorage.com`

### 키 규칙
```
inputs/{userId}/{jobId}/{idx}.jpg                  # 원본 이미지
outputs/{userId}/{jobId}/{idx}_result.png           # 결과 이미지
masks/{userId}/{jobId}/{idx}_{concept}.png          # concept 마스크
masks/{userId}/{jobId}/{idx}_instances.json         # 인스턴스 메타
previews/{userId}/{jobId}/{idx}_thumb.jpg           # 미리보기
```

### R2 API Token (presigned URL용)
- Dashboard → R2 → Manage R2 API Tokens → Create API Token
- 권한: Object Read & Write on `s3-images`
- Workers `.dev.vars`에 설정:
```
R2_ACCESS_KEY_ID=<token_access_key>
R2_SECRET_ACCESS_KEY=<token_secret_key>
R2_ACCOUNT_ID=2c1b8299e2d8cec3f82a016fa88368aa
```

---

## Durable Objects

Workers 배포 시 자동 생성됨 (별도 생성 불필요).

### UserLimiterDO
- **Binding**: `USER_LIMITER`
- **Class**: `UserLimiterDO`
- **ID**: `userId` 기반
- **역할**: 크레딧 관리, 동시성 제한, 룰 슬롯 제한
- **Storage**: SQLite (DO 내장)

### JobCoordinatorDO
- **Binding**: `JOB_COORDINATOR`
- **Class**: `JobCoordinatorDO`
- **ID**: `jobId` 기반
- **역할**: Job 상태머신 (created → uploaded → queued → running → done/failed/canceled)
- **Storage**: SQLite (DO 내장)

---

## Queues

### gpu-jobs (주 큐)
- **Binding**: `GPU_QUEUE`
- **Max batch size**: 10
- **Max retries**: 3
- **Dead letter**: `gpu-jobs-dlq`

### gpu-jobs-dlq (실패 큐)
- 3회 재시도 실패한 메시지가 여기로 이동
- 모니터링 필요

---

## 로컬 개발

```bash
cd workers

# 로컬 서버 (D1/R2/DO 시뮬레이션)
npx wrangler dev

# 타입 체크
npx tsc --noEmit

# D1 로컬 마이그레이션
npx wrangler d1 execute DB --local --file=migrations/0001_schema.sql
```

### .dev.vars (gitignore됨)
```
JWT_SECRET=dev-secret-minimum-32-characters-long
GPU_CALLBACK_SECRET=dev-callback-secret
R2_ACCOUNT_ID=2c1b8299e2d8cec3f82a016fa88368aa
R2_ACCESS_KEY_ID=<your-token>
R2_SECRET_ACCESS_KEY=<your-token>
R2_BUCKET_NAME=s3-images
```

---

## 배포

```bash
cd workers

# Secrets 설정 (최초 1회)
npx wrangler secret put JWT_SECRET
npx wrangler secret put GPU_CALLBACK_SECRET

# 배포
npx wrangler deploy

# 확인
curl https://s3-workers.clickaround8.workers.dev/health
```

---

## 모니터링

### Cloudflare Dashboard
- Workers & Pages → s3-workers → Logs/Analytics

### MCP (Claude Code)
```
1. cloudflare-observability → accounts_list
2. cloudflare-observability → set_active_account (2c1b8299...)
3. cloudflare-observability → workers_list
4. cloudflare-observability → query_worker_observability (s3-workers)
```

---

## Free Plan 한도

| 리소스 | Free 한도 | 초과 시 |
|--------|-----------|---------|
| Workers | 100,000 req/day | $5/mo Paid plan |
| D1 | 5M read rows/day, 100K write rows/day | Paid plan |
| R2 | 10GB storage, 10M Class B, 1M Class A/month | $0.015/GB/month |
| Queues | 1M messages/month | $0.40/million |
| DO | Included with Workers | Workers Paid plan |
