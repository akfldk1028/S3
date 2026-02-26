# Durable Objects — 왜 쓰고, Workers랑 뭐가 다른가

> 개발 경험 없어도 이해할 수 있게 쓴 문서.
> S3 프로젝트에서 DO가 왜 필요한지, 어떻게 작동하는지.

---

## 1. 먼저 알아야 할 것: Cloudflare Workers

### 일반 서버 vs CF Workers

```
일반 서버 (AWS EC2 등):
  내가 고른 컴퓨터 1대에서 돌아감.
  서울에 두면 서울에서만 돌아감.
  상태를 메모리에 들고 있을 수 있음.

CF Workers:
  전세계 300개+ 도시에 컴퓨터가 있음.
  유저가 서울이면 서울 컴퓨터가 처리.
  유저가 뉴욕이면 뉴욕 컴퓨터가 처리.
  → 빠르다! 하지만...
```

### Workers의 치명적 약점: 상태가 없다

Workers는 **요청 하나 처리하고 사라짐**. 다음 요청이 오면 완전히 새로운 Workers가 뜸.
심지어 **어느 나라 컴퓨터에서 뜰지도 모름**.

```
비유: 편의점 알바

  일반 서버 = 단골 편의점 알바 1명
    → "이 손님 아까 왔었지, 포인트 3개 남았어" (기억함)

  CF Workers = 전세계 편의점 300개, 알바 수천 명
    → 매번 다른 알바가 처리
    → "이 손님 누구지? 포인트? 모르는데?" (기억 못 함)
```

그래서 데이터는 **외부 저장소**에 넣어야 함:
- **D1** = 데이터베이스 (유저 정보, 룰, Job 기록)
- **R2** = 파일 저장소 (이미지)

---

## 2. 그러면 D1에 저장하면 되잖아? — 안 됨

D1도 전세계에 분산되어 있어서, **"지금 방금 쓴 데이터"를 "바로 다음에 읽으면" 반영 안 됐을 수 있음**.

### 실제 문제 시나리오

```
유저 크레딧: 10

  0.000초  [서울 Workers]  "크레딧 얼마?" → D1 읽음 → 10
  0.001초  [도쿄 Workers]  "크레딧 얼마?" → D1 읽음 → 10 (아직 서울이 안 씀)
  0.002초  [서울 Workers]  "8장 처리할게" → D1에 10-8=2 저장
  0.003초  [도쿄 Workers]  "7장 처리할게" → D1에 10-7=3 저장
                                          (서울이 2로 바꾼 걸 못 봄)

  결과: 크레딧 10인데 15장 처리됨.
        유저 무료, 우리만 GPU 비용 손해.
```

이건 이론적인 문제가 아니라 **유저가 많아지면 반드시 생기는 문제**.

---

## 3. Durable Objects = "전담 직원 1명"

DO는 이 문제를 **아주 단순하게** 해결함:

> **이 유저의 모든 요청을 전세계에서 딱 1곳으로 모아서, 1명이 줄 세워 처리한다.**

```
DO 없이:
  서울 Workers ──→ D1 ←── 도쿄 Workers    (동시 접근 = 충돌)

DO 있으면:
  서울 Workers ──→ UserLimiterDO("user_abc") ←── 도쿄 Workers
                        │
                   줄 서서 하나씩 처리
                   (동시에 절대 안 함)
```

### 은행 비유로 완벽 이해

```
Workers     = 은행 창구 300개 (전세계, 가까운 데로 감)
D1          = 중앙 장부 (업데이트가 좀 느림)
DO          = 유저 전용 금고 + 전담 직원 1명

  손님이 창구 A에서 "5만원 출금" → 전담 직원한테 전화
  손님이 창구 B에서 "3만원 출금" → 같은 전담 직원한테 전화
  전담 직원: "잠깐, 한 명씩. A 먼저 → 잔고 10-5=5. 다음 B → 잔고 5-3=2. OK."

  → 동시에 전화 와도 절대 동시에 안 열어줌. 순서대로.
```

---

## 4. 우리 프로젝트에서 DO 2개

### UserLimiterDO — "유저 전담 금고 직원"

유저마다 1개. 이런 걸 관리:

```
┌─────────────────────────────────────┐
│  UserLimiterDO("user_abc")          │
│                                     │
│  크레딧: 10                          │
│  동시 Job: 0 / 최대 1 (Free)        │
│  룰 슬롯: 1 / 최대 2 (Free)         │
│                                     │
│  [reserve] "8장 처리 요청"           │
│    → 크레딧 10 ≥ 8? ✅              │
│    → 동시 Job 0 < 1? ✅             │
│    → 크레딧 10→2, 동시 Job 0→1      │
│    → "허가"                         │
│                                     │
│  [release] "Job 끝남"               │
│    → 동시 Job 1→0                   │
│                                     │
│  [rollback] "Job 실패, 환불"         │
│    → 크레딧 2→10                    │
└─────────────────────────────────────┘
```

**왜 DO여야 하나**: 동시에 2개 요청이 와도 줄 세워서 처리 → 크레딧 이중 차감 불가능.

### JobCoordinatorDO — "작업 감독관"

Job마다 1개. 이런 걸 관리:

```
┌─────────────────────────────────────┐
│  JobCoordinatorDO("job_xyz")        │
│                                     │
│  상태: created → uploaded → queued  │
│        → running → done             │
│                                     │
│  전체: 10장                          │
│  완료: 7장                           │
│  실패: 1장                           │
│  남음: 2장                           │
│                                     │
│  [callback] "3번 이미지 완료"        │
│    → 이미 처리한 건 아닌지 확인      │
│    → 완료 7→8                       │
│    → 8+1 < 10 → 아직 진행 중        │
│                                     │
│  [callback] "마지막 이미지 완료"     │
│    → 완료 9+실패 1 = 10 = 전체      │
│    → 상태: running → done           │
│    → 5초 뒤 D1에 기록 저장          │
└─────────────────────────────────────┘
```

**왜 DO여야 하나**:
- GPU가 동시에 여러 callback을 보냄 → 줄 세워서 진행률 정확히 계산
- 같은 callback 2번 보내도 → 중복 무시 (멱등성)
- 상태 순서 강제: `created`에서 갑자기 `done`으로 못 감

---

## 5. 전체 그림: Workers + DO + D1

```
┌─ Flutter 앱 ─┐
│ "8장 처리해줘" │
└──────┬───────┘
       │
       ▼
┌─ Workers (편의점 창구) ──────────────────────────┐
│                                                   │
│  1. JWT 확인 (이 사람 누구?)                       │
│  2. 요청 검증 (8장, interior 프리셋)               │
│  3. UserLimiterDO 호출 → "크레딧 있어?"            │
│  4. JobCoordinatorDO 생성 → "Job 시작"             │
│  5. R2 presigned URL 발급 → "여기에 사진 올려"      │
│  6. Queue push → "GPU야, 이거 처리해"              │
│                                                   │
│  Workers 자체는 아무것도 기억 안 함.                │
│  판단은 DO에게, 기록은 D1에게 위임.                 │
└───────────────────────────────────────────────────┘
       │                    │
       ▼                    ▼
┌─ DO (전담 직원) ─┐  ┌─ D1 (장부) ──────┐
│ 실시간 판단:      │  │ 나중에 조회:      │
│ - 크레딧 충분?   │  │ - 유저 프로필     │
│ - 동시 Job 한도? │  │ - 룰 목록        │
│ - Job 상태 뭐?   │  │ - Job 히스토리    │
│ - 중복 callback? │  │ - 정산 기록       │
│                  │  │                  │
│ ※ 빠르고 정확    │  │ ※ 느리지만 영구   │
└──────────────────┘  └──────────────────┘
```

### 핵심: 역할 분리

| | Workers | DO | D1 |
|---|---|---|---|
| **비유** | 편의점 창구 | 전담 금고 직원 | 중앙 장부 |
| **수명** | 요청 1번이면 사라짐 | 계속 살아있음 | 영구 |
| **상태** | 없음 | 있음 (메모리+SQLite) | 있음 (SQLite) |
| **속도** | 빠름 | 빠름 | 약간 느림 |
| **동시성** | 여러 개 동시 | **1개씩 순서대로** | 동시 가능 (충돌 위험) |
| **용도** | 문 열어주기 | 판단하기 | 기록하기 |

---

## 6. "DO 없이 하면 안 돼?" — 대안과 비교

| 방법 | 장점 | 단점 | 결론 |
|------|------|------|------|
| D1만 쓰기 | 간단 | 동시성 문제, 크레딧 이중 차감 | ❌ |
| D1 + SELECT FOR UPDATE | DB 락 | CF D1은 지원 안 함 | ❌ |
| 외부 Redis (Upstash) | 익숙함 | 추가 비용, 레이턴시 증가, CF 밖 | ❌ |
| **DO** | 동시성 보장, CF 네이티브, 무료 | DO 개념 학습 필요 | **✅ 채택** |

DO가 CF 생태계에서 **유일하게 strong consistency + 싱글 스레드를 보장**하는 방법.

---

## 7. 공부 가이드: 어떻게 배우나

### Level 1: 개념 이해 (30분)

1. **이 문서를 끝까지 읽기** — 비유로 이해
2. Cloudflare 공식 블로그 읽기:
   - "Durable Objects — now in open beta" (검색)
   - 핵심 문장: *"a single instance, running in a single thread, with a consistent view of its own state"*

### Level 2: 우리 코드 읽기 (1시간)

이 순서로 읽으면 됨:

```
1. workers/src/_shared/types.ts          ← 타입 정의 먼저 (UserLimiterState 등)
2. workers/src/do/do.helpers.ts          ← DO stub 가져오는 헬퍼 (3줄)
3. workers/src/do/UserLimiterDO.ts       ← 간단한 DO부터 (크레딧 관리)
4. workers/src/do/JobCoordinatorDO.ts    ← 복잡한 DO (상태머신)
5. workers/src/jobs/jobs.route.ts        ← 라우트에서 DO를 어떻게 호출하는지
```

**읽을 때 주의점:**
- `this.ctx.storage.sql.exec(...)` = DO 내부 SQLite 쿼리 (로컬, 빠름)
- `this.env.DB.prepare(...)` = D1 쿼리 (글로벌, 느림)
- `blockConcurrencyWhile` = "이 안의 코드가 끝날 때까지 다른 요청 대기"

### Level 3: 로컬 실험 (30분)

```bash
cd workers
npx wrangler dev

# 터미널 다른 창에서:
# 1. 유저 생성
curl -X POST http://localhost:8787/auth/anon

# 2. 받은 JWT로 유저 상태 확인 (DO 호출됨)
curl -H "Authorization: Bearer <JWT>" http://localhost:8787/me

# 3. wrangler dev 콘솔에서 DO 로그 확인
#    [UserLimiterDO][init] userId=xxx plan=free
#    [UserLimiterDO][getUserState] ...
```

### Level 4: 공식 문서 (필요할 때)

- [Cloudflare Durable Objects docs](https://developers.cloudflare.com/durable-objects/)
- 핵심 페이지:
  - "How it works" — 싱글턴 보장 원리
  - "SQLite storage" — DO 내부 SQLite
  - "Alarms" — 타이머 (우리는 D1 flush에 사용)

---

## 8. 자주 하는 질문

### Q: DO를 따로 만들어야 하나?
**A: 아니오.** `npx wrangler deploy` 하면 `wrangler.toml` 보고 자동 생성됨.

### Q: DO가 죽으면 데이터 날아감?
**A: 아니오.** DO 내부에 SQLite가 있어서 재시작해도 복구됨. 추가로 D1에도 기록하므로 이중 백업.

### Q: 비용은?
**A: 사실상 무료.** Free Plan으로 충분. 안 쓸 때는 자동 sleep.

### Q: 유저 100만 명이면 DO 100만 개?
**A: 맞음.** 하지만 동시에 깨어있는 건 활성 유저 수만큼. 나머지는 sleep. CF가 알아서 관리.

### Q: Workers에서 DO 호출이 느리지 않나?
**A: 아니오.** 같은 CF 네트워크 안이라 1~5ms. 외부 Redis보다 빠름.
