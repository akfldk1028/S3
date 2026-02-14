# S3 Workflow — 도메인 팔레트 엔진 기반 세트 생산 앱

> v3.0 (2026-02-11) — 제품 비전 통합 + 아키텍처 확정 + 실행 로드맵 + 자동화

---

## 1. 제품 정체성

> **"지우는 앱"이 아니라 "도메인 구성요소를 잡고, 규칙으로 세트를 찍어내는 앱"**

### 한 줄 요약

SAM3 기반으로 "컨셉(개념) → 전체 인스턴스 → 보호 → 룰 → 세트"를,
도메인 팔레트 + 인스턴스 리스트 + 보호 레이어 + 멀티샷 규칙 + 결과물 세트라는
제품 UX로 '세트 생산'에 박아 넣는 것.

### 경쟁 앱과의 차별

| 기능 | 경쟁 앱 10개 (SnapEdit, Photoroom, Picsart 등) | S3 |
|------|----------------------------------------------|-----|
| 배치 처리 | YES (대부분 지원) | YES |
| 컨셉(텍스트) → 전체 인스턴스 선택 | **NO** (0/10) | **YES** |
| 인스턴스 리스트 (#1~#N) | **NO** (0/10) | **YES** |
| 보호 레이어 (망가짐 방지) | 부분 (기본 리파인 수준) | **YES** (핵심 기능) |
| 룰 저장/재사용 | 부분 (템플릿 수준) | **YES** (BM 핵심) |
| 결과물 세트 (패키지 출력) | **NO** (0/10) | **YES** |

### 제품 목표

| 우선순위 | 목표 |
|---------|------|
| 1 | **"세트 생산"을 1~2분 컷**으로 느끼게 — 워크플로우 단축이 전부 |
| 2 | **런칭 최우선** — CF Workers + DO + Queues + R2 + D1 + Runpod Serverless |
| 3 | **GPU 이동성** — Docker 표준화로 Runpod ↔ Vast ↔ 기타 간 adapter만 교체 |
| 4 | **유지보수 단순화** — 상태/동시성/멱등성/크레딧을 DO에 집중 |

---

## 2. 도메인 팔레트 엔진 (제품 코어)

### 공통 5단 구조 (모든 도메인 동일)

```
1. Palette    → 도메인 구성요소 버튼 (예: Wall/Floor/Tile/Grout)
2. Instances  → 동일 개념 다수 → #1~#N 카드 (체크/잠금/제외)
3. Protect    → 텍스트/로고/경계/하이라이트 등 "룰이 침범 못 하게" 고정
4. Rules      → 1회 설정 룰 → 앨범 전체 적용 (저장/재사용)
5. Output Sets → "1장"이 아니라 "패키지"로 내보내기 (템플릿)
```

### SAM3의 역할

| 단계 | SAM3가 하는 일 |
|------|--------------|
| Palette | 텍스트 concept → 해당 개념의 마스크 생성 |
| Instances | 동일 개념 여러 개 → 인스턴스 분리 + ID 유지 |
| Protect | 보호 대상 concept → 보호 마스크 생성 (룰 적용 시 제외 영역) |
| Rules | 마스크 기반으로 영역별 변환 적용 (recolor, tone, texture 등) |

### MVP 타겟 도메인 (2개)

#### 건축/인테리어 (가장 차별 선명)

| 항목 | 내용 |
|------|------|
| **Palette** | Wall, Floor, Ceiling, Window, Door, Frame&Molding, Tile, Grout, Cabinet, Countertop, Light, Handle |
| **Instances** | Window #1~#N, Light #1~#N, Cabinet door #1~#N, Tile zone #1~#N |
| **Protect** | 줄눈/몰딩 경계, 유리 반사 하이라이트, 손잡이/스위치, 가전 로고 |
| **Rules** | 공간 앨범 일괄 (거실12+주방8+욕실10장), 룰 저장/복제/부분적용 |
| **Output** | 시안 3안 패키지 (모던/내추럴/호텔), 고객 공유 카드 (Before+After+팔레트 요약) |
| **킬러 데모** | 줄눈/몰딩/유리 하이라이트 보호 + 룰 3안 시안팩 |

#### 쇼핑/셀러 (돈이 바로 보임)

| 항목 | 내용 |
|------|------|
| **Palette** | Body, Label Text, Logo, Gloss(하이라이트), Parts, Accessories(구성품) |
| **Instances** | Product #1~#6(옵션샷), Main/Cable/Box/Manual(구성품) |
| **Protect** | 라벨/로고/하이라이트/패턴 경계 |
| **Rules** | 메인/디테일/착용/패키지 샷 타입별 룰 저장, 옵션 색상별 톤 동기화 |
| **Output** | 메인1 + 디테일4 + 착용1 + 패키지1 + 썸네일8 + 옵션보드1 |
| **킬러 데모** | 라벨/로고/광택 보호 + 옵션샷 #1~#N 동기화 + 상품팩 자동 출력 |

### Phase 2 도메인 (2개 추가)

- **프로필/브랜딩**: Hair/Face/Skin tone/Glasses → 피부톤 보호 → LinkedIn/Resume/Company ID 세트
- **패션/OOTD**: Top/Bottom/Shoes/Bag/Pattern → 피부톤/패턴 보호 → 3x3 피드 세트/카드뉴스

---

## 3. 아키텍처 (확정)

### 3계층: 입구 — 뇌 — 근육

```
┌──────────────┐      ┌─────────────────────────────────┐      ┌──────────────────┐
│   Flutter    │─────▶│  Cloudflare                     │─────▶│  Runpod GPU      │
│   App        │◀─────│  Workers (입구) + DO (뇌)       │◀─────│  Docker Worker   │
│              │      │  + Queues + R2 + D1             │      │  (근육)          │
└──────────────┘      └─────────────────────────────────┘      └──────────────────┘
```

| 계층 | 역할 | 기술 |
|------|------|------|
| **Workers (입구)** | 인증, 요청검증, presigned URL 발급, DO 호출, 프리셋/룰 CRUD | Hono + CF Workers |
| **DO (뇌)** | 상태머신, 동시성 제한, 크레딧 차감, 룰 슬롯 제한, 멱등성 | Durable Objects (UserLimiter, JobCoordinator) |
| **Queues** | GPU 작업 분산, 재시도 | CF Queues |
| **R2** | 원본/결과/인스턴스 마스크 이미지 저장 (S3 호환) | CF R2 |
| **D1** | 영속 기록 (유저, job, 룰, 프리셋, 정산) | CF D1 (SQLite) |
| **GPU Worker (근육)** | SAM3 segment + rule apply + R2 업로드 + 콜백 | Docker + Runpod Serverless |

### Supabase 제거 결정

> Cloudflare만으로 Auth, DB, 동시성, 실시간 상태를 모두 처리 가능.
> Supabase Realtime은 MVP에서 polling으로 대체, v2에서 DO WebSocket으로 대체.

---

## 4. 데이터 흐름

> 핵심: "업로드"와 "실행(룰 적용)"을 분리 — 유저가 사진 올린 후 천천히 설정 가능

```
 1. User → Flutter → POST /auth/anon → JWT 획득 (최초 1회)
 2. User → 도메인 선택 → GET /presets/interior → concepts/protect 로드
 3. User → 사진 선택 → POST /jobs { preset, item_count } → presigned URLs + job_id
 4. Flutter → R2 직접 업로드 (N회) → POST /jobs/{id}/confirm-upload (status: "uploaded")
 5. [User가 Flutter에서 concept 선택, protect 설정, 룰 구성 — 로컬 상태]
 6. User → "적용" → POST /jobs/{id}/execute { concepts, protect, rule_id? }
 7. Workers → JobCoordinatorDO.markQueued() → Queue push
 8. Runpod GPU Worker → R2에서 이미지 다운 → SAM3 segment → rule apply → 결과 R2 업로드
 9. GPU Worker → POST /jobs/{id}/callback (item별 완료 보고)
10. JobCoordinatorDO → 진행률 갱신, 전체 완료 시 UserLimiterDO.release() + D1 flush
11. Flutter → GET /jobs/{id} (polling 3초) → 결과 표시
12. User → 결과 확인 → 세트 템플릿 선택 → 패키지 내보내기 (Flutter 로컬)
```

### 시안 비교 시나리오 (같은 이미지에 다른 룰)

```
Job A: 30장 업로드 → 룰 "모던" 적용 → 결과 A
Job B: 같은 30장 참조 → 룰 "내추럴" 적용 → 결과 B
Job C: 같은 30장 참조 → 룰 "호텔" 적용 → 결과 C
→ 유저가 3안 비교 → 마음에 드는 안 선택
```

> v2 최적화: segment 결과 캐시 (같은 이미지 → 같은 마스크) → apply만 재실행

---

## 5. 데이터 모델

### 5.1 DO: UserLimiter (유저당 1개)

```
user_id: string
plan: "free" | "pro"
credits: int
active_jobs: int
max_concurrency: int       // free=1, pro=3
rule_slots_used: int       // free 최대 2, pro 최대 20
locks: Set<job_id>
```

### 5.1.1 크레딧 원자성 (reserve / commit / rollback)

```
reserve(jobId, itemCount):
  1. credits >= itemCount 확인 → 실패 시 402 CREDITS_EXHAUSTED
  2. active_jobs < max_concurrency 확인 → 실패 시 429 CONCURRENCY_LIMIT
  3. credits -= itemCount (예약 차감)
  4. active_jobs++
  5. locks.add(jobId)
  → DO 상태에 즉시 반영 (낙관적 차감)

commit(jobId, doneItems, failedItems):
  1. 부분 환불: credits += failedItems (실패한 항목만 환불)
  2. active_jobs--
  3. locks.delete(jobId)
  → Job 정상 완료 시 호출

rollback(jobId, totalItems):
  1. 전액 환불: credits += totalItems
  2. active_jobs--
  3. locks.delete(jobId)
  → Job 취소 또는 전체 실패 시 호출
```

> **핵심**: reserve 시점에 크레딧을 차감하고, 실패/취소 시 환불.
> 이 패턴으로 "크레딧 부족한데 Job이 실행되는" 경쟁 조건 방지.

### 5.2 DO: JobCoordinator (job당 1개)

```
job_id: string
user_id: string
status: "created" | "uploaded" | "queued" | "running" | "done" | "failed" | "canceled"
preset: string
concepts_json: string      // {"Floor":"oak_a","Wall":"offwhite_b"}
protect_json: string       // ["Grout","Molding"]
rule_id: string?           // 저장된 룰 사용 시
total_items: int
done_items: int
failed_items: int
items: Map<idx, { status, input_key, output_key, error? }>
seen_idempotency_keys: RingBuffer
```

> Source of Truth: 실시간 상태 = DO, 영속 기록 = D1

### 5.2.1 D1 Flush 타이밍

```
매 callback (onItemResult):
  → D1 job_items_log UPSERT (해당 item만) — 진행 상태 영속화
  → 실패 시 DO 상태에만 반영 (D1은 최종 flush에서 재시도)

전체 완료 시 (done + failed == total):
  → D1 batch() 트랜잭션:
    1. jobs_log INSERT (최종 상태)
    2. job_items_log UPSERT (모든 item — 확정)
    3. billing_events INSERT (크레딧 정산)
  → UserLimiterDO.commit() 또는 rollback() 호출
  → DO 상태: status → "done" 또는 "failed"
```

> **MVP 단순화**: 매 callback마다 D1 upsert는 선택사항.
> 최소한 전체 완료 시 batch flush는 필수.
> DO가 죽어도 D1에 최종 기록이 남아야 복구 가능.

### 5.3 D1: 영속 기록

```sql
-- 유저 (MVP: anon만, v2: 소셜 로그인)
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  created_at TEXT DEFAULT (datetime('now')),
  plan TEXT DEFAULT 'free',
  credits INTEGER DEFAULT 10,
  auth_provider TEXT DEFAULT 'anon',
  email TEXT,
  device_hash TEXT
);

-- 유저 룰 저장 (BM 핵심: 무료 2슬롯, 유료 20슬롯)
CREATE TABLE rules (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  preset_id TEXT NOT NULL,
  concepts_json TEXT NOT NULL,
  protect_json TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT
);

-- Job 히스토리
CREATE TABLE jobs_log (
  job_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  finished_at TEXT,
  status TEXT,
  preset TEXT,
  rule_id TEXT,
  concepts_json TEXT,
  protect_json TEXT,
  params_json TEXT,
  cost_estimate INTEGER,
  error TEXT
);

-- Item 히스토리
CREATE TABLE job_items_log (
  job_id TEXT NOT NULL,
  idx INTEGER NOT NULL,
  status TEXT,
  input_key TEXT,
  output_key TEXT,
  error TEXT,
  PRIMARY KEY (job_id, idx)
);

-- 정산
CREATE TABLE billing_events (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL,
  amount INTEGER NOT NULL,
  ref TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);
```

### 5.4 프리셋 데이터 (Workers 하드코딩 — MVP)

> MVP에서 4개 프리셋은 Workers 코드에 static으로. v2에서 D1 이전 가능.

```typescript
const PRESETS = {
  interior: {
    name: "건축/인테리어",
    concepts: ["Wall","Floor","Ceiling","Window","Door","Frame_Molding",
               "Tile","Grout","Cabinet","Countertop","Light","Handle"],
    protect_defaults: ["Grout","Frame_Molding","Glass_highlight"],
    output_templates: ["시안3안팩","전후비교","고객공유카드"]
  },
  seller: {
    name: "쇼핑/셀러",
    concepts: ["Body","Label_Text","Logo","Gloss","Parts","Accessories"],
    protect_defaults: ["Label_Text","Logo","Gloss"],
    output_templates: ["상품팩","옵션보드","썸네일8종"]
  }
  // v2: profile, ootd
}
```

### 5.5 R2: 파일 키 규칙

```
inputs/{userId}/{jobId}/{idx}.jpg                    // 원본
outputs/{userId}/{jobId}/{idx}_result.png            // 최종 결과 (룰 적용 완료)
masks/{userId}/{jobId}/{idx}_instances.json          // 인스턴스 메타 (v2: 개별 제어용)
masks/{userId}/{jobId}/{idx}_{concept}.png           // concept별 마스크 (디버그/캐시)
previews/{userId}/{jobId}/{idx}_thumb.jpg            // 미리보기
```

---

## 6. API 엔드포인트 (Workers)

> Base: `https://s3-api.{domain}.workers.dev`
> Auth: `Authorization: Bearer <JWT>` (Workers 자체 서명)
> Response envelope: `{ success, data, error, meta: { request_id, timestamp } }`

### 6.1 Auth

#### `POST /auth/anon` — 익명 유저 생성 + JWT 발급

**Response:**
```json
{ "user_id": "u_abc123", "token": "eyJ..." }
```
**서버:** D1 INSERT → Workers JWT 서명 (HS256) → 반환

### 6.2 User

#### `GET /me` — 유저 상태

**Response:**
```json
{ "user_id": "u_abc", "plan": "free", "credits": 8, "active_jobs": 1, "rule_slots": { "used": 1, "max": 2 } }
```
**서버:** `UserLimiterDO.getUserState()`

### 6.3 Presets

#### `GET /presets` — 도메인 프리셋 목록

**Response:**
```json
[
  { "id": "interior", "name": "건축/인테리어", "concept_count": 12 },
  { "id": "seller", "name": "쇼핑/셀러", "concept_count": 6 }
]
```

#### `GET /presets/{id}` — 프리셋 상세

**Response:**
```json
{
  "id": "interior",
  "name": "건축/인테리어",
  "concepts": ["Wall","Floor","Ceiling","Window",...],
  "protect_defaults": ["Grout","Frame_Molding","Glass_highlight"],
  "output_templates": [
    { "id": "시안3안팩", "name": "시안 3안 패키지", "description": "모던/내추럴/호텔 각 공간별 6~10장" },
    { "id": "전후비교", "name": "전/후 비교 세트", "description": "Before+After 나란히 10장" }
  ]
}
```

### 6.4 Rules CRUD

#### `POST /rules` — 룰 저장

**Request:**
```json
{
  "name": "우리집-모던",
  "preset_id": "interior",
  "concepts": { "Floor": { "action": "recolor", "value": "oak_a" }, "Wall": { "action": "recolor", "value": "offwhite_b" } },
  "protect": ["Grout", "Frame_Molding"]
}
```
**서버:** `UserLimiterDO.checkRuleSlot()` → D1 INSERT → rule_id 반환

#### `GET /rules` — 내 룰 목록

**Response:**
```json
[
  { "id": "rule_abc", "name": "우리집-모던", "preset_id": "interior", "created_at": "..." }
]
```

#### `PUT /rules/{id}` — 룰 수정

#### `DELETE /rules/{id}` — 룰 삭제

**서버:** D1 DELETE → `UserLimiterDO.decrementRuleSlot()`

### 6.5 Jobs

#### `POST /jobs` — Job 생성 (업로드 준비)

**Request:**
```json
{
  "preset": "interior",
  "item_count": 30
}
```

**Response:**
```json
{
  "job_id": "job_123",
  "upload": [
    { "idx": 0, "url": "https://r2-presigned/...", "key": "inputs/u/job_123/0.jpg" }
  ],
  "confirm_url": "/jobs/job_123/confirm-upload"
}
```
**서버:** `UserLimiterDO.reserve(credits)` → `JobCoordinatorDO.create()` → R2 presigned URLs

#### `POST /jobs/{jobId}/confirm-upload` — 업로드 완료 확인

**서버:** `JobCoordinatorDO.markUploaded()` (status: created → uploaded)

#### `POST /jobs/{jobId}/execute` — 룰 적용 실행 (Queue push)

> 업로드 완료 후, 유저가 concept/protect/rule 설정을 마치고 "적용" 시 호출

**Request:**
```json
{
  "concepts": {
    "Floor": { "action": "recolor", "value": "oak_a" },
    "Wall": { "action": "recolor", "value": "offwhite_b" }
  },
  "protect": ["Grout", "Frame_Molding", "Glass_highlight"],
  "rule_id": "rule_abc",
  "output_template": "시안3안팩"
}
```
> `rule_id`가 있으면 저장된 룰의 concepts/protect를 사용 (inline 값 무시)

**서버:** `JobCoordinatorDO.markQueued(concepts, protect)` → Queue push

#### `GET /jobs/{jobId}` — 상태 조회

**Response:**
```json
{
  "job_id": "job_123",
  "status": "running",
  "preset": "interior",
  "progress": { "done": 17, "failed": 0, "total": 30 },
  "outputs_ready": [
    { "idx": 0, "result_url": "https://r2-presigned/...", "preview_url": "https://r2-presigned/..." }
  ]
}
```
**서버:** `JobCoordinatorDO.getStatus()` → presigned download URLs

#### `POST /jobs/{jobId}/callback` — GPU Worker 콜백 (내부)

**Request:**
```json
{
  "idx": 0,
  "status": "done",
  "output_key": "outputs/u/job_123/0_result.png",
  "preview_key": "previews/u/job_123/0_thumb.jpg",
  "error": null,
  "idempotency_key": "job_123:0:attempt1"
}
```
**서버:** `JobCoordinatorDO.onItemResult()` → 멱등성 체크 → 진행률 갱신 → 전체 완료 시 `UserLimiterDO.release()` + D1 flush

#### `POST /jobs/{jobId}/cancel` — 취소

**서버:** `JobCoordinatorDO.cancel()` → `UserLimiterDO.release()` → 환불 정책

### API 엔드포인트 요약 (14개)

| # | Method | Path | 설명 |
|---|--------|------|------|
| 1 | POST | /auth/anon | 익명 유저 생성 + JWT |
| 2 | GET | /me | 유저 상태 (credits, plan, rule_slots) |
| 3 | GET | /presets | 도메인 프리셋 목록 |
| 4 | GET | /presets/{id} | 프리셋 상세 (concepts, protect, templates) |
| 5 | POST | /rules | 룰 저장 |
| 6 | GET | /rules | 내 룰 목록 |
| 7 | PUT | /rules/{id} | 룰 수정 |
| 8 | DELETE | /rules/{id} | 룰 삭제 |
| 9 | POST | /jobs | Job 생성 + presigned URLs |
| 10 | POST | /jobs/{id}/confirm-upload | 업로드 완료 |
| 11 | POST | /jobs/{id}/execute | 룰 적용 실행 (Queue push) |
| 12 | GET | /jobs/{id} | 상태/진행률 조회 |
| 13 | POST | /jobs/{id}/callback | GPU 콜백 (내부) |
| 14 | POST | /jobs/{id}/cancel | 취소 |

### 6.6 에러 응답 카탈로그

> 모든 에러는 envelope `{ success: false, data: null, error: { code, message }, meta }` 형식

| HTTP | error.code | 발생 조건 | 관련 엔드포인트 |
|------|------------|----------|----------------|
| 400 | `VALIDATION_ERROR` | Zod 스키마 불일치 (body/params) | 모든 POST/PUT |
| 401 | `AUTH_REQUIRED` | Authorization 헤더 없음 | 인증 필요 엔드포인트 전체 |
| 401 | `TOKEN_EXPIRED` | JWT exp 초과 | 인증 필요 엔드포인트 전체 |
| 401 | `TOKEN_INVALID` | JWT 서명 불일치 / 파싱 실패 | 인증 필요 엔드포인트 전체 |
| 402 | `CREDITS_EXHAUSTED` | 크레딧 부족 (credits < item_count) | POST /jobs |
| 403 | `RULE_SLOT_FULL` | 룰 슬롯 한도 초과 (free=2, pro=20) | POST /rules |
| 403 | `CALLBACK_UNAUTHORIZED` | GPU_CALLBACK_SECRET 불일치 | POST /jobs/{id}/callback |
| 404 | `NOT_FOUND` | 리소스 없음 (job, rule, preset) | GET/PUT/DELETE by ID |
| 404 | `JOB_NOT_FOUND` | job_id 미존재 | /jobs/{id}/* |
| 404 | `RULE_NOT_FOUND` | rule_id 미존재 | /rules/{id} |
| 409 | `INVALID_TRANSITION` | 상태머신 전이 불가 (예: uploaded→created) | confirm-upload, execute, cancel |
| 409 | `ALREADY_CANCELED` | 이미 취소된 Job | /jobs/{id}/execute, /cancel |
| 429 | `CONCURRENCY_LIMIT` | 동시 Job 한도 초과 (free=1, pro=3) | POST /jobs |
| 500 | `INTERNAL_ERROR` | 서버 내부 오류 | 모든 엔드포인트 |

### 6.7 콜백 인증 (GPU Worker → Workers)

```
1. GPU Worker → POST /jobs/{id}/callback
2. Headers: { "Authorization": "Bearer <GPU_CALLBACK_SECRET>" }
3. Workers 미들웨어:
   a. Authorization header에서 Bearer token 추출
   b. env.GPU_CALLBACK_SECRET과 일치 여부 검증
   c. 불일치 → 403 CALLBACK_UNAUTHORIZED
   d. 일치 → JobCoordinatorDO.onItemResult() 호출
```

> **중요**: 이 콜백은 JWT 인증이 아님. 단순 shared secret 비교.
> GPU Worker `.env`의 `GPU_CALLBACK_SECRET`과 Workers `.dev.vars`의 `GPU_CALLBACK_SECRET`이 동일해야 함.

---

## 7. Queue 메시지 계약

> GPU Worker가 어디서 돌든 동일하게 이해하는 표준 스키마

```json
{
  "job_id": "job_123",
  "user_id": "u_abc",
  "preset": "interior",
  "concepts": {
    "Floor": { "action": "recolor", "value": "oak_a" },
    "Wall": { "action": "recolor", "value": "offwhite_b" }
  },
  "protect": ["Grout", "Frame_Molding", "Glass_highlight"],
  "items": [
    {
      "idx": 0,
      "input_key": "inputs/u_abc/job_123/0.jpg",
      "output_key": "outputs/u_abc/job_123/0_result.png",
      "preview_key": "previews/u_abc/job_123/0_thumb.jpg"
    }
  ],
  "callback_url": "https://s3-api.example.workers.dev/jobs/job_123/callback",
  "idempotency_prefix": "job_123",
  "batch_concurrency": 4
}
```

---

## 8. GPU Worker (Docker + Adapter 패턴)

### 2단계 추론 파이프라인

```
Input Image
    │
    ▼
┌─────────────────────────────────────────┐
│  Phase A: SAM3 Segment (GPU 필수)       │
│  concept text → SAM3 → N개 인스턴스 마스크 │
│  protect concepts → protect 마스크들      │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│  Phase B: Rule Apply (CPU/GPU)          │
│  원본 + 인스턴스 마스크 + protect 마스크   │
│  + rule params → 영역별 변환 → 결과 이미지 │
└─────────────────────────────────────────┘
    │
    ▼
R2 Upload (result + preview + masks)
    │
    ▼
Callback → Workers
```

### 디렉토리 구조

```
gpu-worker/
├── engine/
│   ├── pipeline.py          # segment → apply → postprocess → upload (2단계)
│   ├── segmenter.py         # SAM3 wrapper: concept text → instance masks
│   ├── applier.py           # Rule apply: masks + params → result image
│   ├── r2_io.py             # S3 호환 업/다운로드
│   ├── callback.py          # item 완료/실패 보고
│   └── idempotency.py       # 중복 처리 방지
├── presets/
│   ├── interior.py          # 건축 도메인 concept 매핑 + default protect
│   └── seller.py            # 셀러 도메인 concept 매핑
├── adapters/
│   ├── runpod_serverless.py # Runpod handler (MVP)
│   ├── queue_pull.py        # polling 방식 (Vast/Pod용)
│   └── http_trigger.py      # 옵션
├── Dockerfile               # 2단 빌드 (base + app)
├── main.py
└── .env.example
```

### 환경변수 계약 (플랫폼 독립)

```env
STORAGE_S3_ENDPOINT=        # R2 endpoint
STORAGE_ACCESS_KEY=
STORAGE_SECRET_KEY=
STORAGE_BUCKET=s3-images
BATCH_CONCURRENCY=4
MODEL_CACHE_DIR=/models
CALLBACK_TIMEOUT_SEC=10
LOG_LEVEL=info
# queue_pull 모드일 때만:
QUEUE_ENDPOINT=
QUEUE_TOKEN=
```

### Docker 이미지 전략

| Layer | 내용 | 변경 빈도 |
|-------|------|----------|
| **Base Image** | CUDA runtime + Python + PyTorch + ffmpeg/opencv/pillow | 거의 없음 |
| **App Image** | worker 코드 + preset/rule 로직 + adapter | 자주 |

> 모델 가중치는 이미지에 안 넣음 → /models 볼륨 마운트 or 런타임 다운로드

### GPU 이동성

```
Runpod Serverless → adapters/runpod_serverless.py (handler)
Vast Instance     → adapters/queue_pull.py (polling)
자체 서버         → adapters/http_trigger.py (HTTP)
```

> engine/ + Dockerfile은 동일. adapter만 교체.

---

## 9. 인증

### MVP: Workers 자체 JWT (anon)

```
1. Flutter 최초 실행 → POST /auth/anon
2. Workers → D1에 user 생성 → JWT 서명 (HS256, Workers 환경변수 secret)
3. Flutter → 이후 모든 요청에 Authorization: Bearer <JWT>
4. Workers 미들웨어 → JWT 검증 → sub=user_id 추출
```

### JWT 규격

| 필드 | 값 | 설명 |
|------|------|------|
| `alg` | HS256 | Workers 환경변수 `JWT_SECRET`로 서명 |
| `sub` | `u_abc123` | 유저 ID |
| `iat` | Unix timestamp | 발급 시각 |
| `exp` | iat + 2592000 (30일) | MVP 만료 (v2: 30분 + refresh token) |

> **MVP**: access token 30일 (단순화). plan 정보는 JWT에 넣지 않음 — DO가 Source of Truth.
> **v2**: access token 30분 + D1 `refresh_tokens` 테이블 + `POST /auth/refresh` 엔드포인트 추가.

### JWT 에러 응답

| 상황 | HTTP | error.code | error.message |
|------|------|------------|---------------|
| 토큰 없음 | 401 | `AUTH_REQUIRED` | `Authorization header required` |
| 토큰 만료 | 401 | `TOKEN_EXPIRED` | `Token expired, re-authenticate` |
| 토큰 위조/잘못됨 | 401 | `TOKEN_INVALID` | `Invalid token` |

### v2: 소셜 로그인 추가

- 선택지 A: Workers에서 OAuth2 직접 구현 (Google/Apple)
- 선택지 B: Supabase Auth만 선택적 사용 (나머지는 CF)
- 선택지 C: Cloudflare Access (내부 어드민용만)

> B2C 일반 유저에 Cloudflare Access는 비추. Workers OAuth2 or Supabase Auth 선택.

---

## 10. 실시간 진행률

### MVP: Polling

```dart
// Flutter — 3초마다 polling
Timer.periodic(Duration(seconds: 3), (_) async {
  final response = await api.getJob(jobId);
  if (response.status == 'done' || response.status == 'failed') {
    timer.cancel();
  }
  updateUI(response.progress);
});
```

### v2: DO WebSocket

```
1. Flutter → wss://s3-api.workers.dev/jobs/{id}/ws
2. Workers → JobCoordinatorDO.fetch() (WebSocket upgrade)
3. DO → item 완료 시 connected clients에 push
4. Flutter → onMessage로 실시간 갱신
```

> Durable Objects는 WebSocket을 네이티브 지원. Supabase Realtime 대체 가능.

---

## 11. 수익화 (BM)

### 과금이 자연스러운 지점: 세트/일괄/룰

| 항목 | Free | Pro |
|------|------|-----|
| 룰 저장 슬롯 | 2 | 20 |
| 멀티샷 처리 장수 (1 job) | 10장 | 200장 |
| 결과물 세트 템플릿 | 기본 1종 | 다수 (상품팩/시안팩/프로필팩) |
| 동시 Job | 1 | 3 |
| 고해상도 출력 | 워터마크 | 워터마크 없음 |
| (2차) 영상 추적 | - | Pro 전용 |

### UserLimiterDO에서 관리하는 제한

```typescript
interface UserLimits {
  credits: number;           // 잔여 크레딧
  maxConcurrency: number;    // free=1, pro=3
  maxRuleSlots: number;      // free=2, pro=20
  maxItemsPerJob: number;    // free=10, pro=200
}
```

---

## 12. 런칭 로드맵

### Phase 1: MVP (런칭)

| # | 태스크 | 레이어 | 의존성 | 병렬 그룹 |
|---|--------|--------|--------|----------|
| 1 | D1 스키마 (users, rules, jobs_log, job_items_log, billing_events) | Workers | - | A |
| 2 | Workers Auth (anon JWT 발급/검증 미들웨어) | Workers | 1 | A |
| 3 | Workers Presets API (하드코딩 interior+seller) | Workers | 2 | A |
| 4 | Workers Rules CRUD API | Workers | 2 | A |
| 5 | UserLimiterDO (크레딧/동시성/룰 슬롯 제한) | Workers | 2 | A |
| 6 | JobCoordinatorDO (상태머신/멱등성/execute 분리) | Workers | 5 | A |
| 7 | R2 presigned URL + Queues 연결 | Workers | 6 | A |
| 8 | GPU Worker Docker: SAM3 segment + rule apply | GPU | - | B |
| 9 | GPU Worker: Runpod adapter | GPU | 8 | B |
| 10 | Workers callback + 상태 갱신 + D1 flush | Workers | 7,9 | A+B |
| 11 | Flutter: Auth (anon) + 온보딩 | Frontend | 2 | C |
| 12 | Flutter: 도메인 선택 + 팔레트 UI + 인스턴스 리스트 | Frontend | 3 | C |
| 13 | Flutter: 이미지 업로드 + 보호 토글 + 룰 적용/저장 | Frontend | 4,7 | C |
| 14 | Flutter: 진행률(polling) + 결과 + 세트 내보내기 | Frontend | 10 | C |
| 15 | E2E 통합 테스트 | All | 10,14 | - |

### 병렬 실행 전략

```
Group A (Workers): 1 → 2 → [3,4,5 병렬] → 6 → 7 → 10
Group B (GPU):     8 → 9 ─────────────────────┘
Group C (Frontend): 11 → 12 → 13 → 14
                         (3 완료 후 시작)  (4,7 완료 후 시작)
```

### Phase 2: 확장

| 태스크 | 설명 |
|--------|------|
| 소셜 로그인 | Google/Apple OAuth2 on Workers |
| DO WebSocket | 실시간 진행률 (polling 대체) |
| 결제 연동 | Stripe → D1 billing_events |
| GPU 이동성 | Vast adapter 추가, 비용 비교 |
| 도메인 추가 | profile, ootd 프리셋 |
| Segment 캐시 | 같은 이미지 재사용 시 segment 스킵 → apply만 |
| 영상 추적 (Pro) | 짧은 클립(≤10초) SAM3 추적 + 룰 유지 |
| 어드민 대시보드 | CF Access + D1 조회 |

---

## 13. 디렉토리 매핑 (현재 → 새 아키텍처)

### 현재 구조

```
S3/
├── edge/          # Hono Workers (Supabase 기반 — 아키텍처 A)
├── cf-backend/    # FastAPI SAM3 추론 (빈 scaffolding)
├── ai-backend/    # 모델 노트북/스크립트
├── frontend/      # Flutter (~30%)
├── supabase/      # 마이그레이션 4개 (아키텍처 A)
└── clone/         # Auto-Claude
```

### 전환 계획

| 현재 | 전환 후 | 액션 |
|------|---------|------|
| `edge/` | `workers/` | Hono 유지, Supabase → D1/DO로 교체. R2/response utils 재사용 |
| `cf-backend/` | `gpu-worker/` | FastAPI 제거 → Docker engine + adapter 패턴으로 재작성 |
| `ai-backend/` | `gpu-worker/engine/` | 모델 스크립트를 engine 하위로 통합 |
| `supabase/` | 삭제 (D1로 이전) | 스키마 참고하여 D1 DDL 작성 |
| `frontend/` | `frontend/` (유지) | API 호출부만 변경 (Supabase SDK → REST) |

> 전환 비용은 낮음: edge/의 실질 코드가 scaffolding 수준, cf-backend은 빈 상태.

---

## 14. MVP 성공 기준

### 기술

- [ ] 배치 30장 job이 중복 처리 없이 완료 (멱등성)
- [ ] 동시 사용자 50명 접수 가능 (Queue 백프레셔)
- [ ] free/pro 동시성/룰슬롯 제한이 깨지지 않음 (UserLimiterDO)
- [ ] GPU 공급자 교체 시 adapter만 변경 (이동성)
- [ ] 업로드→실행 분리가 안정적 (uploaded 상태에서 대기 가능)

### UX (제품 5단 파이프라인)

- [ ] 도메인 팔레트에서 concept 선택 → SAM3가 전체 인스턴스 감지
- [ ] 보호 레이어 토글 → 보호 영역이 룰 적용에서 제외
- [ ] 룰 저장/불러오기 → 같은 룰을 다른 앨범에 재적용
- [ ] "세트 생산"을 1~2번 클릭으로 완료
- [ ] 진행률이 신뢰 가능 (item 단위)
- [ ] 결과를 템플릿(세트)으로 내보내기

### 킬러 데모 2개 (30초 안에 "다르다" 체감)

1. **(건축)** 줄눈/몰딩/유리 하이라이트 보호 + 룰 3안 시안팩
2. **(셀러)** 라벨/로고/광택 보호 + 옵션샷 #1~#N 동기화 + 상품팩 자동 출력

---

## 15. Docker 함정 TOP 5

| # | 함정 | 해결 |
|---|------|------|
| 1 | 호스트 드라이버/CUDA mismatch | base image에 CUDA runtime 버전 고정 |
| 2 | torch-cuda 불일치 | `torch==2.7.0+cu121` 명시 |
| 3 | 모델을 이미지에 넣어 콜드스타트 폭발 | /models 볼륨 or 런타임 다운로드 |
| 4 | ffmpeg 누락 | base image에 포함 |
| 5 | 배치 concurrency 과다 → OOM | `BATCH_CONCURRENCY` 환경변수로 제어 |

---

## 16. Auto-Claude (24/7 자동 빌드)

### Daemon 실행

```powershell
set PYTHONUTF8=1
C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe ^
  C:\DK\S3\clone\Auto-Claude\apps\backend\runners\daemon_runner.py ^
  --project-dir "C:\DK\S3" ^
  --status-file "C:\DK\S3\.auto-claude\daemon_status.json" ^
  --use-worktrees ^
  --skip-qa
```

> **중요**: `--use-claude-cli` 사용 금지 — MCP 서버가 전달되지 않는 버그 있음.
> run.py 모드(기본)를 사용하면 MCP 서버가 정상 연결됨.

### Task 생성 (Daemon 자동 픽업)

```powershell
set PYTHONUTF8=1
C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe ^
  C:\DK\S3\clone\Auto-Claude\apps\backend\runners\spec_runner.py ^
  --task "Workers API + D1 마이그레이션 구현" ^
  --project-dir "C:\DK\S3" ^
  --no-build
```

### Claude Code 스킬

```
/s3-auto-task "Workers API + D1 마이그레이션 구현"
```

### 커스텀 에이전트 (6개)

| Agent | 담당 |
|-------|------|
| `s3_edge_api` | Workers + DO + D1 + Queues + R2 |
| `s3_backend_inference` | GPU Worker Docker + SAM3 engine |
| `s3_supabase` | (레거시) D1 마이그레이션으로 전환 예정 |
| `s3_frontend_auth` | Flutter Auth UI |
| `s3_frontend_segmentation` | 이미지 업로드 + 팔레트 + 인스턴스 + 보호 + 룰 |
| `s3_frontend_gallery` | 결과 갤러리 + 세트 내보내기 |

### 상태 확인

- Status JSON: `C:\DK\S3\.auto-claude\daemon_status.json`
- WebSocket: `ws://127.0.0.1:18801`
- Specs: `C:\DK\S3\.auto-claude\specs\`

---

## 17. 다음 액션 (즉시)

> 이 문서 확정 후 동기화 필요:

1. **CLAUDE.md 업데이트** — 제품 정체성 + D1/DO 아키텍처 반영
2. **api-contracts.md 재작성** — 14개 엔드포인트 (위 섹션 6 기준)
3. **커스텀 에이전트 프롬프트 업데이트** — 새 아키텍처 + 제품 5단 파이프라인 반영
4. **디렉토리 리네이밍** — `edge/` → `workers/`, `cf-backend/` → `gpu-worker/`
5. **첫 Auto-Claude 태스크** — Phase 1 순서 1번 (D1 스키마) 부터 시작
