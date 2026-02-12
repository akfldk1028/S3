# S3 리드 가이드 — 설계 보완 + 통합 + Auto-Claude 관리

> 역할: 설계 갭 보완, workflow.md 관리, 팀원 작업 통합, 코드 리뷰, Auto-Claude 운영

---

## 1. 병렬 작업 전략

**전원 동시 시작. 의존성은 types.ts 인터페이스로 해결.**

```
Week 1-2: 전원 동시 작업
────────────────────────────────────────────────────
팀원 A ▓▓▓▓▓▓▓▓▓▓ JWT → Auth route → Presets → Rules
팀원 B ▓▓▓▓▓▓▓▓▓▓ UserLimiterDO → JobCoordinatorDO → Jobs routes
팀원 C ▓▓▓▓▓▓▓▓▓▓ SAM3 segmenter → applier → pipeline → adapter
팀원 D ▓▓▓▓▓▓▓▓▓▓ UI 컴포넌트 → 팔레트 → 업로드 → Mock API 연동

Week 3: 통합
────────────────────────────────────────────────────
리드   ▓▓▓▓▓▓▓▓▓▓ A+B 머지 → D Mock→실API 교체 → C 연결 → E2E
```

### 동시 진행이 가능한 이유

1. **types.ts 완성** — 모든 타입/인터페이스가 정의됨. A와 B가 같은 타입으로 코딩.
2. **DO는 독립 단위 테스트 가능** — B는 Auth 없이 DO 로직만 단독 테스트.
3. **GPU Worker 완전 독립** — Queue 메시지 JSON 스키마만 맞추면 됨.
4. **Frontend는 Mock API** — D는 UI 레이아웃 + 상태관리를 먼저 만들고, 나중에 실제 API 연결.

### 충돌 방지 규칙

| 규칙 | 설명 |
|------|------|
| **types.ts 수정 = 리드만** | 타입 변경은 반드시 리드가 하고 전체 공지 |
| **errors.ts 수정 = 리드만** | 에러 코드 추가도 리드만 |
| **각자 폴더만 작업** | A: auth/, presets/, rules/, middleware/, _shared/jwt.ts, _shared/r2.ts |
| | B: do/, jobs/, user/ |
| | C: gpu-worker/ 전체 |
| | D: frontend/ 전체 |
| **index.ts = 리드가 통합** | 라우트 마운트는 머지 시 리드가 |

---

## 2. 즉시 해야 할 일: 설계 갭 보완

> 팀원들이 작업 시작하기 전에 workflow.md에 추가

### 2-1. JWT Payload + TTL (→ workflow.md 섹션 9)

```typescript
interface JwtPayload {
  sub: string;   // user_id "u_abc123"
  iat: number;   // issued at (Unix)
  exp: number;   // iat + 30일 (2592000초). MVP는 긴 TTL
}
// plan, credits → DO에서 실시간 조회 (payload에 안 넣음)
// refresh → MVP 없음. 만료 시 /auth/anon 재호출
```

### 2-2. HTTP 에러 코드 매핑 (→ workflow.md 섹션 6)

```
400 → VALIDATION_FAILED
401 → AUTH_REQUIRED, TOKEN_EXPIRED
402 → CREDIT_INSUFFICIENT
403 → RULE_SLOT_EXCEEDED, CONCURRENCY_EXCEEDED
404 → NOT_FOUND
409 → INVALID_JOB_STATUS
500 → INTERNAL_ERROR
```

### 2-3. 부분 실패 크레딧 정책 (→ workflow.md 섹션 11)

```
- Job 생성 시: total_items × 1 크레딧 reserve
- 완료 시: done_items × 1 차감, (total - done) 환불
- billing_events: type="charge" + type="refund"
```

### 2-4. GPU 중간 데이터 포맷 (→ workflow.md 섹션 8)

```python
segment_result = {
    "masks": { "Floor": ndarray, "Wall": ndarray },  # H×W binary
    "instances": {
        "Floor": [
            {"id": 0, "mask": ndarray, "bbox": [x,y,w,h], "area": int},
        ]
    },
    "protect_mask": ndarray,  # 합산 보호 마스크
}
```

---

## 3. 통합 순서 (PR 머지)

```
1. 팀원 A PR 머지 (Auth + JWT + Presets + Rules) — 가장 먼저
2. 팀원 B PR 머지 (DO + Jobs) — A 머지 직후
3. 리드: index.ts에서 전체 라우트 마운트 + 통합 테스트
4. 팀원 C PR 머지 (GPU) — 독립적, 아무 때나
5. 팀원 D PR 머지 (Frontend) — Mock→실API 교체 후
6. E2E 통합 테스트
```

---

## 4. Auto-Claude 운영

### Daemon 시작

```powershell
set PYTHONUTF8=1
C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe ^
  C:\DK\S3\clone\Auto-Claude\apps\backend\runners\daemon_runner.py ^
  --project-dir "C:\DK\S3" ^
  --status-file "C:\DK\S3\.auto-claude\daemon_status.json" ^
  --use-worktrees --skip-qa ^
  --use-claude-cli ^
  --claude-cli-path "C:\Users\User\.local\bin\claude.exe"
```

### Task 생성

```powershell
set PYTHONUTF8=1
C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe ^
  C:\DK\S3\clone\Auto-Claude\apps\backend\runners\spec_runner.py ^
  --task "태스크 설명" --project-dir "C:\DK\S3" --no-build
```

### 상태 확인

```
파일: C:\DK\S3\.auto-claude\daemon_status.json
WS:   ws://127.0.0.1:18801
```

---

## 5. 코드 리뷰 체크리스트

- [ ] workflow.md API 스키마와 일치?
- [ ] types.ts 타입 사용? (직접 타입 선언 금지)
- [ ] errors.ts 에러 코드 사용?
- [ ] 환경변수 하드코딩 없음?
- [ ] 레이어 간 직접 import 없음?
- [ ] DO: 멱등성 보장?
- [ ] D1: batch() 트랜잭션 사용?
