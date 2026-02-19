# 팀원 B: Workers DO + Jobs — Durable Objects + Job 엔드포인트

> **담당**: 두 DO(UserLimiter, JobCoordinator) + Jobs 7개 엔드포인트 + User 라우트
> **상태**: ✅ **전부 완료 + 배포됨** (2026-02-19)
> **브랜치**: master (머지 완료)

---

## Durable Objects가 뭐고, 왜 쓰는가?

> 자세한 설명 + 공부 가이드: **[`docs/DO-쉬운설명.md`](../docs/DO-쉬운설명.md)** 참조

### Workers만으로 안 되는 이유

Workers는 **stateless** — 요청마다 전세계 아무 서버에서 새로 뜸. 상태가 없음.

```
유저 크레딧: 10

[서버 A] 요청1: "크레딧 10? OK, 8장 예약" → D1에서 10 읽음 → 2로 업데이트
[서버 B] 요청2: "크레딧 10? OK, 7장 예약" → D1에서 10 읽음 → 3으로 업데이트
                                            (서버A 반영 전에 읽음)
결과: 크레딧 10인데 15장 처리 → 과금 구멍
```

D1에 트랜잭션 걸면? **D1은 글로벌 분산이라 즉시 일관성(strong consistency) 보장 안 됨.**

### DO = "이 유저 전담 직원 1명"

```
은행 비유:
  Workers = 창구 100개 (아무 창구나 감)
  D1      = 중앙 장부 (업데이트 반영에 시간차 있음)
  DO      = 유저 전담 금고 + 1인 직원 (줄 서서 하나씩 처리)
```

DO 핵심 특징:
- **이름으로 1개만 존재**: `UserLimiterDO("user_abc")` → 전세계에 딱 1개
- **싱글 스레드**: 동시 요청이 와도 **줄 세워서 하나씩** 처리 (`blockConcurrencyWhile`)
- **내부 SQLite**: 로컬 디스크, 즉시 일관성, 빠름
- **자동 sleep/wake**: 안 쓰면 자고, 요청 오면 깨남 (비용 $0)

### 이 프로젝트에서 DO 2개의 역할

**UserLimiterDO (유저당 1개) — "과금/제한 관문"**

```
크레딧 관리:
  reserve(jobId, 8장)  → 10 - 8 = 2, 동시성 0→1  (원자적, 동시 요청 불가)
  commit(jobId)        → 확정 (영구 차감)
  rollback(jobId)      → 실패 → 크레딧 10으로 환불

룰 슬롯 관리:
  checkRuleSlot()      → Free 2개, Pro 20개 제한
  incrementRuleSlot()  → 슬롯 +1
  decrementRuleSlot()  → 슬롯 -1
```

**JobCoordinatorDO (Job당 1개) — "작업 상태머신"**

```
상태 전이 (순서 강제):
  created → uploaded → queued → running → done/failed/canceled

멱등성:
  GPU가 같은 callback을 2번 보내도 → Ring Buffer(512)로 중복 무시

진행률:
  done_items / total_items 실시간 추적

D1 flush:
  Job 완료 → 5초 뒤 alarm → D1에 히스토리 기록 (DO는 실시간, D1은 영속)
```

### DO vs D1 역할 분리

```
┌──────────────────┬─────────────────────┬──────────────────────┐
│                  │ DO (실시간)          │ D1 (영속)             │
├──────────────────┼─────────────────────┼──────────────────────┤
│ 크레딧 잔액       │ ✅ 여기서 관리       │ ❌                   │
│ 동시 Job 수       │ ✅ 여기서 관리       │ ❌                   │
│ Job 상태 (FSM)    │ ✅ 여기서 관리       │ 완료 후 flush        │
│ 유저 프로필       │ ❌                  │ ✅ users 테이블       │
│ 룰 저장          │ ❌                  │ ✅ rules 테이블       │
│ Job 히스토리      │ ❌                  │ ✅ jobs_log 테이블    │
└──────────────────┴─────────────────────┴──────────────────────┘

한 줄 요약: DO = "지금 판단", D1 = "나중에 조회"
```

---

## 현재 상태 (2026-02-19)

### ✅ 완료된 작업

| 항목 | 상태 | 파일 |
|------|------|------|
| UserLimiterDO | ✅ 완료 | `workers/src/do/UserLimiterDO.ts` |
| JobCoordinatorDO | ✅ 완료 | `workers/src/do/JobCoordinatorDO.ts` |
| DO helpers | ✅ 완료 | `workers/src/do/do.helpers.ts` |
| GET /jobs (목록) | ✅ 완료 | `workers/src/jobs/jobs.route.ts` |
| POST /jobs (생성) | ✅ 완료 | `workers/src/jobs/jobs.route.ts` |
| POST /jobs/:id/confirm-upload | ✅ 완료 | `workers/src/jobs/jobs.route.ts` |
| POST /jobs/:id/execute | ✅ 완료 | `workers/src/jobs/jobs.route.ts` |
| GET /jobs/:id (상태) | ✅ 완료 | `workers/src/jobs/jobs.route.ts` |
| POST /jobs/:id/callback | ✅ 완료 | `workers/src/jobs/jobs.route.ts` |
| POST /jobs/:id/cancel | ✅ 완료 | `workers/src/jobs/jobs.route.ts` |
| Jobs service | ✅ 완료 | `workers/src/jobs/jobs.service.ts` |
| Jobs validator (Zod) | ✅ 완료 | `workers/src/jobs/jobs.validator.ts` |
| GET /me | ✅ 완료 | `workers/src/user/user.route.ts` |
| Queue consumer | ✅ 완료 | `workers/src/index.ts` |
| TypeScript 0 errors | ✅ 완료 | `npx tsc --noEmit` |
| 배포 | ✅ 완료 | `npx wrangler deploy` |

### 버그 수정 이력

| 날짜 | 파일 | 수정 내용 |
|------|------|----------|
| 02-15 | `jobs.route.ts` L472 | `/on-item-result` → `/callback` (DO path mismatch) |
| 02-15 | `jobs.route.ts` L502 | `/status` → `/state` (DO path mismatch) |
| 02-18 | `JobCoordinatorDO.ts` | `transitionState()` async → sync (sql.exec은 동기) |
| 02-18 | `rules.route.ts` | POST/DELETE에서 DO init() 누락 수정 |
| 02-18 | `user.route.ts` | 응답 필드명 snake_case 통일 |

---

## 남은 작업: 없음

모든 항목 구현 + 배포 완료. E2E 테스트에서 버그 발견 시 대응.

### 버그 발견 시 대응 가이드

1. **에러 로그 확인**:
   ```
   cloudflare-observability → query_worker_observability
   "s3-workers에서 jobs/DO 관련 에러 보여줘"
   ```

2. **코드 확인할 파일**:
   - `workers/src/jobs/jobs.route.ts` — 7개 엔드포인트
   - `workers/src/jobs/jobs.service.ts` — presigned URL, queue push
   - `workers/src/jobs/jobs.validator.ts` — Zod 스키마
   - `workers/src/do/UserLimiterDO.ts` — 크레딧/동시성/룰슬롯
   - `workers/src/do/JobCoordinatorDO.ts` — FSM 상태머신
   - `workers/src/do/do.helpers.ts` — DO stub 조회
   - `workers/src/user/user.route.ts` — GET /me
   - `workers/src/_shared/types.ts` — 타입 정의 (수정 금지)

3. **DO 상태 확인 패턴**:
   ```typescript
   // UserLimiterDO — 반드시 init() 먼저
   const userRow = await c.env.DB
     .prepare('SELECT plan FROM users WHERE id = ?')
     .bind(user.userId)
     .first<{ plan: 'free' | 'pro' }>();
   const plan = userRow?.plan ?? 'free';
   const limiterStub = limiterNs.get(limiterNs.idFromName(user.userId));
   await limiterStub.init(user.userId, plan);
   ```

4. **주의**: DO sync/async 구분
   - `confirmUpload()`, `markQueued()`: **sync** (await 불필요)
   - `create()`, `init()`, `reserve()`: **async** (await 필요)

5. **로컬 테스트**:
   ```bash
   cd workers && npx wrangler dev
   npx tsc --noEmit
   ```

---

## 완료 기준 (전부 ✅)

- [x] UserLimiterDO: reserve/release/checkRuleSlot 동작
- [x] JobCoordinatorDO: 전체 상태머신 전이 동작
- [x] JobCoordinatorDO: 멱등성 (같은 idempotency_key 재전송 시 무시)
- [x] JobCoordinatorDO: D1 flush (batch INSERT)
- [x] POST /jobs → presigned URL 반환
- [x] POST /jobs/:id/confirm-upload → status 변경
- [x] POST /jobs/:id/execute → Queue push
- [x] GET /jobs/:id → 진행률 반환
- [x] POST /jobs/:id/callback → item 결과 처리
- [x] POST /jobs/:id/cancel → 취소 + 환불
- [x] GET /jobs → 목록
- [x] GET /me → 유저 상태 반환
- [x] `npx tsc --noEmit` 에러 없음
- [x] `npx wrangler deploy` 배포 성공
