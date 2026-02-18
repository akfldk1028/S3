# Wrangler vs Durable Objects — 팀 가이드

> S3 프로젝트에서 사용하는 Cloudflare 기술 설명

---

## 한 줄 요약

| | 역할 | 비유 |
|---|---|---|
| **Workers** | HTTP 요청 처리 (서버리스 함수) | Express/Fastify 서버 |
| **Wrangler** | Workers 개발/배포 CLI 도구 | npm/yarn 같은 도구 |
| **Durable Objects (DO)** | 상태 유지 + 단일 스레드 보장 | Redis + 뮤텍스 |

---

## Workers (입구)

Cloudflare의 **서버리스 함수**. 전 세계 300+ edge에서 실행됨.

```
[클라이언트] → [Workers (Hono)] → [응답]
                   ↓ ↓ ↓
                  D1  R2  DO
```

### 특징
- **Stateless**: 요청 간 상태 공유 안 됨 (매 요청이 독립적)
- **빠름**: Cold start < 5ms
- **제한**: 실행 시간 30초 (Free), CPU 10ms (Free)

### S3에서의 역할
- JWT 인증, 요청 검증
- D1 CRUD (rules, jobs_log)
- R2 presigned URL 발급
- DO 호출 (상태 관리 위임)
- Queue push (GPU 작업 분배)

### 코드 위치
```
workers/src/
├── index.ts              # Hono 앱 엔트리
├── auth/                 # POST /auth/anon
├── presets/              # GET /presets
├── rules/                # CRUD /rules
├── jobs/                 # 6 endpoints /jobs
├── user/                 # GET /me
├── middleware/            # JWT 검증
└── _shared/              # types, response utils, errors
```

---

## Wrangler (도구)

Workers 개발/배포를 위한 **CLI 도구**. Workers 자체가 아님!

### 자주 쓰는 명령어
```bash
npx wrangler dev              # 로컬 개발 서버
npx wrangler deploy           # 프로덕션 배포
npx wrangler d1 execute       # D1 SQL 실행
npx wrangler secret put       # Secrets 설정
npx wrangler tail             # 실시간 로그 스트리밍
```

### wrangler.toml
Workers 설정 파일. 어떤 리소스를 바인딩할지 정의:
```toml
name = "s3-workers"           # Workers 이름
main = "src/index.ts"         # 엔트리 포인트

[durable_objects]             # DO 바인딩
bindings = [
  { name = "USER_LIMITER", class_name = "UserLimiterDO" },
  { name = "JOB_COORDINATOR", class_name = "JobCoordinatorDO" }
]

[[d1_databases]]              # D1 바인딩
binding = "DB"

[[r2_buckets]]                # R2 바인딩
binding = "R2"

[[queues.producers]]          # Queue 바인딩
binding = "GPU_QUEUE"
```

---

## Durable Objects (뇌)

Workers 안에서 **상태를 유지**하는 특별한 클래스.

### Workers vs DO 핵심 차이

| | Workers | Durable Objects |
|---|---|---|
| 상태 | Stateless (매 요청 독립) | **Stateful** (메모리 + SQLite) |
| 인스턴스 | 수천 개 동시 실행 | **ID당 전 세계에 1개만** |
| 동시성 | 여러 요청 동시 처리 | **단일 스레드** (자동 직렬화) |
| 저장소 | 외부 (D1, R2) | **내장 SQLite** |
| 용도 | HTTP 라우팅/검증 | 상태머신, 동시성 제어, 실시간 |

### 왜 DO가 필요한가?

**문제**: "유저가 동시에 2개 Job을 만들면?"
- Workers만으로는 race condition 발생 (두 요청이 동시에 크레딧 차감)
- DB lock으로 해결? → 분산 환경에서 복잡

**DO 해결**: UserLimiterDO
- `userId`당 전 세계에 **1개의 인스턴스만** 존재
- 모든 요청이 **순서대로** 처리됨 (자동 뮤텍스)
- 크레딧 차감 → 동시성 체크 → 결과 반환 (원자적)

### S3의 DO 2개

#### UserLimiterDO (유저당 1개)
```
역할: 크레딧 관리, 동시성 제한, 룰 슬롯 제한
ID: userId
내부 상태: { plan, credits, active_jobs, rule_slots_used }

동작:
- checkAndDebit(cost) → 크레딧 충분? → 차감 + active_jobs++
- release(jobId)     → active_jobs-- (Job 완료 시)
- checkRuleSlot()    → 슬롯 여유? → 허용/거부
```

#### JobCoordinatorDO (Job당 1개)
```
역할: Job 상태머신, 진행률 추적, 멱등성 보장
ID: jobId
내부 상태: { status, items[], done_count, failed_count, seen_keys[] }

상태 전이:
created → uploaded → queued → running → done/failed/canceled

동작:
- create(preset, itemCount) → presigned URLs 생성
- confirmUpload()           → created → uploaded
- markQueued()              → uploaded → queued
- handleCallback(idx, result) → 진행률 갱신 (멱등)
- getState()                → 현재 상태 반환
```

### DO 호출 방법 (Workers 코드에서)

```typescript
// 1. ID 생성 (userId 또는 jobId 기반)
const id = c.env.USER_LIMITER.idFromName(userId);

// 2. stub 획득 (전 세계에서 해당 인스턴스를 찾음)
const stub = c.env.USER_LIMITER.get(id);

// 3. fetch로 RPC (내부 HTTP)
const response = await stub.fetch(
  new Request('http://internal/check-credit', {
    method: 'POST',
    body: JSON.stringify({ cost: 5 })
  })
);
```

### DO 코드 위치
```
workers/src/do/
├── UserLimiterDO.ts      # 크레딧/동시성/룰슬롯
├── JobCoordinatorDO.ts   # 상태머신/멱등성/D1 flush
└── do.helpers.ts         # DO 유틸 함수
```

---

## 데이터 흐름 (전체)

```
Flutter App
    │
    ▼
Workers (Hono) ─── stateless ── D1 (영속 기록)
    │                            R2 (이미지)
    │
    ▼ (DO 호출)
UserLimiterDO ─── stateful ── 크레딧/동시성 실시간 관리
JobCoordinatorDO ── stateful ── Job 상태머신
    │
    ▼ (Queue push)
GPU_QUEUE → GPU Worker → callback → JobCoordinatorDO
```

### Source of Truth 분리
| 데이터 | 실시간 (DO) | 영속 (D1) |
|--------|------------|----------|
| 유저 크레딧 | UserLimiterDO.credits | billing_events |
| Job 상태 | JobCoordinatorDO.status | jobs_log |
| 룰 슬롯 수 | UserLimiterDO.rule_slots | rules (COUNT) |

---

## FAQ

### Q: DO를 별도로 만들어야 하나요?
**A: 아니오.** Workers 배포(`wrangler deploy`) 시 `wrangler.toml`의 설정에 따라 자동 생성됩니다.

### Q: DO 인스턴스는 몇 개 생기나요?
**A:** 유저 수 × 1 (UserLimiter) + Job 수 × 1 (JobCoordinator). 사용하지 않으면 자동 sleep.

### Q: DO가 죽으면 데이터는?
**A:** DO 내장 SQLite에 저장됨. 재시작 시 자동 복구. 추가로 D1에도 flush하므로 이중 백업.

### Q: Workers와 DO의 차이를 코드로 보면?
```typescript
// Workers: 요청마다 실행, 상태 없음
app.get('/presets', async (c) => {
  const data = await c.env.DB.prepare('SELECT * FROM presets').all();
  return c.json(data);
});

// DO: ID별 싱글톤, 상태 유지, 자동 직렬화
export class UserLimiterDO extends DurableObject {
  private credits: number = 0;  // 메모리에 상태 유지!

  async checkAndDebit(cost: number) {
    if (this.credits < cost) throw new Error('Not enough');
    this.credits -= cost;  // 동시 호출이 와도 순서대로 처리
  }
}
```
