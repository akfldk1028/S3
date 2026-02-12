# 팀원 B: Workers DO + Jobs — Durable Objects + Job 엔드포인트

> **담당**: 두 DO(UserLimiter, JobCoordinator) + Jobs 6개 엔드포인트 + User 라우트
> **브랜치**: `feat/workers-do-jobs`
> **동시 작업**: 팀원 A(Auth)와 동시 진행. DO 로직은 독립 구현 가능.

---

## 프로젝트 컨텍스트 (필독)

S3는 "도메인 팔레트 엔진 기반 세트 생산 앱"이다.
- **DO(Durable Objects) = "뇌"**: 실시간 상태, 동시성 제어, 멱등성
- **D1 = 영속 기록**: Job 완료 시 flush (히스토리)
- **SSoT**: `workflow.md` — 섹션 5(데이터 모델), 섹션 6.5(Jobs API)
- **타입 정의**: `workers/src/_shared/types.ts` — 수정 금지

---

## 담당 파일 (작업 범위)

```
workers/src/
├── do/
│   ├── UserLimiterDO.ts      ← [구현] 크레딧, 동시성, 룰슬롯 관리
│   ├── JobCoordinatorDO.ts   ← [구현] Job 상태머신, 멱등성, D1 flush
│   └── do.helpers.ts         ← [완성됨] DO stub 조회 헬퍼
├── jobs/
│   ├── jobs.route.ts         ← [구현] 6개 엔드포인트
│   ├── jobs.service.ts       ← [구현] Queue push, presigned URL
│   └── jobs.validator.ts     ← [구현] Zod 스키마
└── user/
    └── user.route.ts         ← [구현] GET /me
```

### 절대 건드리지 않는 파일

- `types.ts`, `errors.ts`, `response.ts` → 리드만 수정
- `auth/`, `presets/`, `rules/` → 팀원 A 담당
- `middleware/` → 팀원 A 담당
- `_shared/jwt.ts`, `_shared/r2.ts` → 팀원 A 담당
- `index.ts` → 리드가 통합 시 수정

---

## 구현 순서

### Step 1: UserLimiterDO — 유저당 1개 인스턴스

```typescript
// workers/src/do/UserLimiterDO.ts
// Cloudflare Durable Objects (SQLite storage 사용)

export class UserLimiterDO extends DurableObject<Env> {
  // 상태: credits, active_jobs, rule_slots_used, plan
  // SQLite storage (this.ctx.storage.sql)로 관리

  // === 메서드 ===

  async getUserState(): Promise<UserLimiterState> {
    // storage에서 상태 로드 → 반환
  }

  async reserve(jobId: string, itemCount: number): Promise<{ allowed: boolean; reason?: string }> {
    // 1. 크레딧 확인 (credits >= itemCount)
    // 2. 동시성 확인 (active_jobs < max_concurrency)
    // 3. 성공 → credits -= itemCount, active_jobs++, locks.add(jobId)
    // 4. 실패 → reason 반환
  }

  async release(jobId: string, doneItems: number, totalItems: number): Promise<void> {
    // 1. active_jobs--
    // 2. 부분 환불: credits += (totalItems - doneItems)
    // 3. locks.delete(jobId)
  }

  async checkRuleSlot(): Promise<{ allowed: boolean }> {
    // rule_slots_used < max (free=2, pro=20)
  }

  async incrementRuleSlot(): Promise<void> {
    // rule_slots_used++
  }

  async decrementRuleSlot(): Promise<void> {
    // rule_slots_used--
  }
}
```

**타입 참고**: `types.ts`의 `UserLimiterState`, `PLAN_LIMITS`

### Step 2: JobCoordinatorDO — Job당 1개 인스턴스

```typescript
// workers/src/do/JobCoordinatorDO.ts
// 상태머신: created → uploaded → queued → running → done/failed
//           (any) → canceled

export class JobCoordinatorDO extends DurableObject<Env> {
  // 상태: status, items Map, done_items, failed_items, seen_idempotency_keys

  async create(data: { userId: string; preset: string; totalItems: number }): Promise<void> {
    // status = "created", items 초기화
  }

  async markUploaded(): Promise<void> {
    // status: created → uploaded (다른 상태면 거부)
  }

  async markQueued(concepts: object, protect: string[]): Promise<void> {
    // status: uploaded → queued
    // concepts, protect 저장
  }

  async getStatus(): Promise<JobCoordinatorState> {
    // 현재 상태 + progress 반환
  }

  async onItemResult(payload: CallbackPayload): Promise<void> {
    // 1. 멱등성: seen_idempotency_keys 체크
    // 2. items[idx] 업데이트
    // 3. 첫 callback → status: queued → running
    // 4. done_items++ 또는 failed_items++
    // 5. 전체 완료 (done + failed == total) →
    //    a. UserLimiterDO.release()
    //    b. D1 flush (jobs_log + job_items_log + billing_events)
    //    c. status → done (or failed if all failed)
  }

  async cancel(): Promise<void> {
    // status → canceled
    // UserLimiterDO.release() (전액 환불)
  }
}
```

**상태머신 전이 규칙:**
```
create()       → "created"
markUploaded() → "uploaded"  (only from "created")
markQueued()   → "queued"    (only from "uploaded")
onItemResult() → "running"   (first callback, from "queued")
               → "done"      (all items done, from "running")
               → "failed"    (all items done but all failed)
cancel()       → "canceled"  (from any except "done")
```

**D1 flush (Job 완료 시):**
```typescript
// D1 batch()로 트랜잭션
const stmts = [
  env.DB.prepare('INSERT INTO jobs_log ...').bind(...),
  ...items.map(item =>
    env.DB.prepare('INSERT INTO job_items_log ...').bind(...)
  ),
  env.DB.prepare('INSERT INTO billing_events ...').bind(...),
];
await env.DB.batch(stmts);
```

### Step 3: Jobs Routes (jobs.route.ts)

```typescript
// 6개 엔드포인트:

// POST /jobs — Job 생성 + presigned URL 반환
// 1. UserLimiterDO.reserve(itemCount)
// 2. JobCoordinatorDO.create()
// 3. R2 presigned URL 생성 (팀원 A의 r2.ts 사용)
// 4. 반환: { job_id, upload: [{ idx, url, key }], confirm_url }

// POST /jobs/:id/confirm-upload
// → JobCoordinatorDO.markUploaded()

// POST /jobs/:id/execute
// → JobCoordinatorDO.markQueued(concepts, protect)
// → Queue push (env.GPU_QUEUE.send(message))

// GET /jobs/:id — 상태 조회
// → JobCoordinatorDO.getStatus()
// → 완료된 item에 대해 R2 presigned download URL 생성

// POST /jobs/:id/callback — GPU Worker 콜백 (내부)
// → GPU_CALLBACK_SECRET 검증
// → JobCoordinatorDO.onItemResult(payload)

// POST /jobs/:id/cancel
// → JobCoordinatorDO.cancel()
```

### Step 4: User Route (user.route.ts)

```typescript
// GET /me — 유저 상태
// → UserLimiterDO.getUserState()
// → 반환: { user_id, plan, credits, active_jobs, rule_slots: { used, max } }
```

### Step 5: Validators (jobs.validator.ts)

```typescript
import { z } from 'zod';

export const CreateJobSchema = z.object({
  preset: z.enum(['interior', 'seller']),
  item_count: z.number().int().min(1).max(200),
});

export const ExecuteJobSchema = z.object({
  concepts: z.record(z.object({
    action: z.enum(['recolor', 'tone', 'texture', 'remove']),
    value: z.string(),
  })),
  protect: z.array(z.string()).optional(),
  rule_id: z.string().optional(),
  output_template: z.string().optional(),
});

export const CallbackSchema = z.object({
  idx: z.number().int().min(0),
  status: z.enum(['done', 'failed']),
  output_key: z.string().optional(),
  preview_key: z.string().optional(),
  error: z.string().nullable().optional(),
  idempotency_key: z.string(),
});
```

---

## 팀원 A와의 인터페이스

**A가 먼저 완성해야 B가 사용하는 것들:**
- `jwt.ts` → callback 라우트의 GPU_CALLBACK_SECRET 검증과 별도 (callback은 JWT 아닌 secret 비교)
- `auth.middleware.ts` → jobs/user 라우트에 적용 (A가 완성 전까진 미들웨어 없이 테스트 가능)
- `r2.ts` → presigned URL 생성 (A가 완성 전까진 stub URL 반환)

**B가 독립으로 할 수 있는 것들 (A 필요 없음):**
- UserLimiterDO 전체 로직 + 단위 테스트
- JobCoordinatorDO 전체 로직 + 상태머신 + D1 flush
- Validator (Zod 스키마)

**통합 타이밍:**
- A의 auth middleware + r2.ts 완성 → B의 라우트에 연결
- 라우트 핸들러에서는 A의 모듈을 import해서 사용

---

## 참고 문서

| 문서 | 위치 | 참고 섹션 |
|------|------|----------|
| DO 데이터 모델 | `workflow.md` | 섹션 5.1, 5.2 |
| Jobs API | `workflow.md` | 섹션 6.5 |
| Queue 메시지 | `workflow.md` | 섹션 7 |
| 타입 | `workers/src/_shared/types.ts` | JobStatus, UserLimiterState, etc. |
| D1 DDL | `workers/migrations/0001_init.sql` | jobs_log, job_items_log, billing_events |

---

## 환경 설정

```bash
cd workers/
npm install
cp .dev.vars.example .dev.vars
npx wrangler d1 execute s3-db --local --file=migrations/0001_init.sql
npx wrangler dev
```

---

## CF Durable Objects 핵심 패턴

```typescript
// DO 내부 상태 관리 (SQLite storage)
export class MyDO extends DurableObject<Env> {
  private state: MyState | null = null;

  private async loadState(): Promise<MyState> {
    if (this.state) return this.state;
    this.state = await this.ctx.storage.get<MyState>('state') ?? DEFAULT_STATE;
    return this.state;
  }

  private async saveState(): Promise<void> {
    await this.ctx.storage.put('state', this.state);
  }

  // RPC 메서드 (Workers에서 stub.methodName()으로 호출)
  async myMethod(): Promise<Result> {
    const state = await this.loadState();
    // 로직...
    await this.saveState();
    return result;
  }
}
```

```typescript
// Workers에서 DO 호출 (do.helpers.ts 사용)
import { getUserLimiterStub, getJobCoordinatorStub } from '../do/do.helpers';

const limiter = getUserLimiterStub(env, userId);
const result = await limiter.reserve(jobId, itemCount);
```

---

## 완료 기준

- [ ] UserLimiterDO: reserve/release/checkRuleSlot 동작
- [ ] JobCoordinatorDO: 전체 상태머신 전이 동작
- [ ] JobCoordinatorDO: 멱등성 (같은 idempotency_key 재전송 시 무시)
- [ ] JobCoordinatorDO: D1 flush (batch INSERT)
- [ ] POST /jobs → presigned URL 반환
- [ ] POST /jobs/:id/confirm-upload → status 변경
- [ ] POST /jobs/:id/execute → Queue push
- [ ] GET /jobs/:id → 진행률 반환
- [ ] POST /jobs/:id/callback → item 결과 처리
- [ ] POST /jobs/:id/cancel → 취소 + 환불
- [ ] GET /me → 유저 상태 반환
- [ ] `npx tsc --noEmit` 에러 없음
