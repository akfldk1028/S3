# 팀원 B: Workers DO + Jobs — Durable Objects + Job 엔드포인트

> **담당**: 두 DO(UserLimiter, JobCoordinator) + Jobs 7개 엔드포인트 + User 라우트
> **상태**: ✅ **전부 완료 + 배포됨** (2026-02-19)
> **브랜치**: master (머지 완료)

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
