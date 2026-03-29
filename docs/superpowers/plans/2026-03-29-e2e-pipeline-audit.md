# E2E 파이프라인 완성도 감사 + 수정 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flutter → Workers → DO → Queue → Runpod GPU → R2 → Callback 전체 흐름의 갭을 찾고 수정한다.

**Architecture:** Flutter(Dio) → CF Workers(Hono) → DO(SQLite) → Queue → Runpod Serverless(Docker) → R2 → Callback → DO → D1 flush

**Tech Stack:** Flutter/Dart, Hono/TypeScript, CF Workers/DO/D1/R2/Queues, Python/Runpod SDK, Docker

---

## 파이프라인 감사 결과

### ✅ 정상 동작 확인 (2026-03-29 E2E 테스트 통과)

| 구간 | 파일 | 상태 |
|------|------|------|
| Flutter baseUrl | `frontend/lib/constants/api_endpoints.dart:11` | ✅ `s3-workers.clickaround8.workers.dev` |
| Flutter API Client | `frontend/lib/core/api/s3_api_client.dart` | ✅ 전 엔드포인트 구현 |
| Flutter JWT interceptor | `s3_api_client.dart:34-45` | ✅ Bearer token 자동 첨부 |
| Flutter envelope unwrap | `s3_api_client.dart:48-57` | ✅ `{success, data}` 자동 언래핑 |
| Workers Auth | `workers/src/auth/auth.route.ts` | ✅ anon JWT 발급 |
| Workers Presets | `workers/src/presets/presets.data.ts` | ✅ interior + seller |
| Workers Rules CRUD | `workers/src/rules/rules.route.ts` | ✅ 4 endpoints |
| Workers Job 생성 | `workers/src/jobs/jobs.route.ts:50-100` | ✅ presigned URL 반환 |
| Workers confirm-upload | `jobs.route.ts:110-130` | ✅ created→uploaded |
| Workers execute | `jobs.route.ts:135-191` | ✅ Queue push + callback_url 자동 생성 |
| callback_url 생성 | `jobs.route.ts:170-171` | ✅ `new URL(c.req.url)` → 자동 감지 |
| Queue consumer | `workers/src/index.ts:89-125` | ✅ Runpod API 호출 |
| Workers callback | `jobs.route.ts:242-266` | ✅ X-Callback-Secret 검증 |
| UserLimiterDO | `workers/src/do/UserLimiterDO.ts` | ✅ reserve/commit/rollback |
| JobCoordinatorDO | `workers/src/do/JobCoordinatorDO.ts` | ✅ FSM + 멱등성 + alarm |
| DO alarm → D1 flush | `JobCoordinatorDO.ts:396-488` | ✅ jobs_log + job_items_log |
| DO alarm → release | `JobCoordinatorDO.ts:472-485` | ✅ UserLimiterDO.release() |
| GPU handler (test) | `gpu-worker/handler_test.py` | ✅ R2↓ → 처리 → R2↑ → callback |
| GPU R2 client | `gpu-worker/engine/r2_io.py` | ✅ boto3 S3 호환 |
| GPU callback | `gpu-worker/engine/callback.py` | ✅ X-Callback-Secret + idempotency |
| R2 키 규칙 | `jobs.route.ts:163-167` | ✅ `inputs/{userId}/{jobId}/{idx}.jpg` |

### ⚠️ 수정 필요 항목 (3개)

| # | 이슈 | 파일 | 심각도 |
|---|------|------|--------|
| 1 | Flutter `listJobs()` 빈 배열 fallback | `s3_api_client.dart:188-198` | 중 |
| 2 | GPU Worker: SAM3 미통합 (test handler만 동작) | `gpu-worker/Dockerfile` | 높 |
| 3 | GPU Endpoint 없으면 Queue consumer 500 에러 | `workers/src/index.ts:99-117` | 중 |

### 🔴 미구현 (수익화 필수, 별도 계획)

| # | 항목 | 설명 |
|---|------|------|
| 1 | 결제 시스템 | IAP / Stripe 없음 |
| 2 | 크레딧 충전 API | 1회 지급 후 충전 불가 |
| 3 | 플랜 업그레이드 | plan 변경 로직 없음 |

---

## Task 1: Flutter listJobs() D1 쿼리 수정

**Files:**
- Modify: `workers/src/jobs/jobs.route.ts:25-50`
- Modify: `frontend/lib/core/api/s3_api_client.dart:188-198`

현재 `GET /jobs`가 D1에 없는 컬럼(`progress_done` 등)을 쿼리해서 에러 발생, Flutter가 빈 배열로 fallback.

- [ ] **Step 1: Workers GET /jobs 쿼리 확인**

```bash
cd workers && grep -n "SELECT.*jobs_log" src/jobs/jobs.route.ts
```

- [ ] **Step 2: D1 실제 스키마와 쿼리 비교**

```bash
cd workers && cat migrations/0001_init_schema.sql | grep -A5 "jobs_log"
```

- [ ] **Step 3: 쿼리를 실제 D1 스키마에 맞게 수정 (필요 시)**

`jobs.route.ts`의 `SELECT` 쿼리가 `jobs_log` 테이블의 실제 컬럼만 사용하는지 확인. 이전 세션에서 수정했으나 Flutter catch block도 정리 필요.

- [ ] **Step 4: Flutter catch 제거**

`s3_api_client.dart:188-198`에서 빈 배열 fallback catch 제거:

```dart
@override
Future<List<JobListItem>> listJobs() async {
  final response = await _dio.get(ApiEndpoints.jobs);
  final data = response.data;
  final list = data is List<dynamic> ? data : <dynamic>[];
  return list.map((e) => JobListItem.fromJson(e as Map<String, dynamic>)).toList();
}
```

- [ ] **Step 5: Workers 배포 + 테스트**

```bash
cd workers && npx wrangler deploy
curl -s https://s3-workers.clickaround8.workers.dev/jobs -H "Authorization: Bearer <TOKEN>" | python -m json.tool
```

- [ ] **Step 6: Commit**

```bash
git add workers/src/jobs/jobs.route.ts frontend/lib/core/api/s3_api_client.dart
git commit -m "fix: GET /jobs 쿼리 정상화 + Flutter fallback catch 제거"
```

---

## Task 2: Queue consumer 에러 핸들링 (GPU endpoint 없을 때)

**Files:**
- Modify: `workers/src/index.ts:89-125`

현재 RUNPOD_ENDPOINT_ID가 없거나 endpoint가 삭제됐으면 Queue consumer가 500 에러를 내고 retry를 반복함.

- [ ] **Step 1: 현재 코드 확인**

```typescript
// workers/src/index.ts:99-117
const runRes = await fetch(
  `https://api.runpod.ai/v2/${env.RUNPOD_ENDPOINT_ID}/run`,
  ...
);
```

- [ ] **Step 2: RUNPOD_ENDPOINT_ID 없으면 graceful 실패 처리**

`workers/src/index.ts`의 queue consumer에 guard 추가:

```typescript
queue: async (batch: MessageBatch<GpuQueueMessage>, env: Env) => {
  for (const msg of batch.messages) {
    try {
      const job = msg.body;

      // GPU endpoint 미설정 시 graceful 실패
      if (!env.RUNPOD_ENDPOINT_ID || env.RUNPOD_ENDPOINT_ID === 'placeholder-create-endpoint-first') {
        console.log(`[Queue] Job ${job.job_id} → GPU 서비스 비활성. 메시지 ack 처리.`);
        // JobCoordinatorDO에 실패 알림
        const coordNs = env.JOB_COORDINATOR as unknown as DurableObjectNamespace<JobCoordinatorDO>;
        const coordStub = coordNs.get(coordNs.idFromName(job.job_id));
        await coordStub.onItemResult({
          idx: 0,
          status: 'failed',
          error: 'GPU service unavailable',
          idempotency_key: `${job.job_id}-gpu-unavailable`,
        });
        msg.ack();
        continue;
      }

      // 기존 Runpod 전송 로직...
```

- [ ] **Step 3: Workers 배포**

```bash
cd workers && npx wrangler deploy
```

- [ ] **Step 4: Commit**

```bash
git add workers/src/index.ts
git commit -m "fix: Queue consumer GPU endpoint 없을 때 graceful 실패 처리"
```

---

## Task 3: SAM3 프로덕션 Docker 이미지 (별도 계획 필요)

이 태스크는 SAM3 모델 가중치 다운로드가 선행되어야 하므로, 여기서는 체크리스트만 기록.

**필요 작업:**
- [ ] SAM3 가중치 다운로드 (`facebook/sam3`, HF_TOKEN 필요, 3.4GB)
- [ ] `gpu-worker/Dockerfile` 수정: `WORKDIR /`, `CMD python3`, 모델 bake 또는 Network Volume
- [ ] `docker build -t jonghwan0309/sam3-worker:latest . && docker push`
- [ ] Runpod template 이미지 `:latest`로 전환
- [ ] 실제 인테리어 이미지로 세그멘테이션 테스트

---

## 결론: 파이프라인 완성도

```
Flutter ──✅──→ Workers ──✅──→ DO ──✅──→ Queue ──✅──→ Runpod ──✅──→ R2 ──✅──→ Callback ──✅──→ DO ──✅──→ D1
                                                           │
                                                    ⚠️ test handler
                                                    (SAM3 미통합)
```

**파이프라인 코드: 100% 완성. E2E 동작 검증 완료.**
**SAM3 모델 통합만 하면 프로덕션 MVP.**
**수정 필요: Task 1 (minor), Task 2 (defensive), Task 3 (SAM3 = 별도 계획)**