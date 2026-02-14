# 팀원 A: Workers Core — Auth + JWT + Presets + Rules

> **담당**: Workers의 인증/인가 기반 + CRUD 엔드포인트
> **브랜치**: `feat/workers-auth`
> **동시 작업**: 팀원 B(DO+Jobs)와 동시 진행. types.ts 인터페이스 공유.

---

## 프로젝트 컨텍스트 (필독)

S3는 "도메인 팔레트 엔진 기반 세트 생산 앱"이다.
- **아키텍처**: Flutter → Cloudflare Workers(입구) + DO(뇌) → GPU Worker(근육)
- **Workers = 유일한 API 서버**: 인증, CRUD, presigned URL, DO 호출 모두 담당
- **SSoT**: `workflow.md` — API 스키마, 데이터 모델, 모든 계약
- **타입 정의**: `workers/src/_shared/types.ts` — 모든 타입이 여기에 정의됨 (수정 금지, 리드만 수정)

---

## 담당 파일 (작업 범위)

```
workers/src/
├── _shared/
│   ├── jwt.ts              ← [구현] JWT sign/verify (Web Crypto API)
│   └── r2.ts               ← [구현] R2 presigned URL 생성 (aws4fetch)
├── middleware/
│   └── auth.middleware.ts   ← [구현] JWT 검증 미들웨어
├── auth/
│   ├── auth.route.ts        ← [구현] POST /auth/anon
│   └── auth.service.ts      ← [구현] D1 user 생성 + JWT 발급
├── presets/
│   ├── presets.route.ts     ← [구현] GET /presets, GET /presets/:id
│   └── presets.data.ts      ← [완성됨] 프리셋 데이터 (수정 불필요)
└── rules/
    ├── rules.route.ts       ← [구현] CRUD 4개 엔드포인트
    ├── rules.service.ts     ← [구현] D1 쿼리 (INSERT/SELECT/UPDATE/DELETE)
    └── rules.validator.ts   ← [구현] Zod 스키마 (CreateRule, UpdateRule)
```

### 절대 건드리지 않는 파일

- `types.ts`, `errors.ts`, `response.ts` → 완성됨, 리드만 수정
- `do/` → 팀원 B 담당
- `jobs/`, `user/` → 팀원 B 담당
- `index.ts` → 리드가 통합 시 수정

---

## 구현 순서 (위→아래)

### Step 1: JWT (jwt.ts) — 모든 것의 기반

```typescript
// workers/src/_shared/jwt.ts
// Web Crypto API 사용 (CF Workers에서는 jsonwebtoken 사용 불가)
// hono/jwt 또는 직접 구현

import { sign, verify } from 'hono/jwt';
import type { JwtPayload } from './types';

export async function signJwt(userId: string, secret: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  return sign({ sub: userId, iat: now, exp: now + 2592000 }, secret); // 30일 (MVP)
  // v2: exp: now + 1800 (30분) + refresh token
}

export async function verifyJwt(token: string, secret: string): Promise<JwtPayload> {
  return verify(token, secret) as Promise<JwtPayload>;
}
```

**테스트**: `npx wrangler dev`로 로컬 실행 후 수동 호출

### Step 2: Auth Middleware (auth.middleware.ts)

```typescript
// Authorization: Bearer <token> 검증
// 성공 → c.set('user', { userId, plan }) 저장
// 실패 → 401 반환 (errors.ts의 ERR.AUTH_REQUIRED 사용)
// /auth/anon은 미들웨어 스킵 (공개 엔드포인트)
```

**참고**: `types.ts`의 `AuthUser` 타입, `response.ts`의 `error()` 함수 사용

### Step 3: Auth Route (auth.route.ts + auth.service.ts)

```typescript
// POST /auth/anon
// 1. D1에 user INSERT (id=crypto.randomUUID(), plan='free', credits=10)
// 2. JWT 서명 (sub=user_id)
// 3. 반환: { user_id, token }

// auth.service.ts
export async function createAnonUser(db: D1Database): Promise<{ userId: string }> {
  const userId = `u_${crypto.randomUUID().replace(/-/g, '').slice(0, 12)}`;
  await db.prepare('INSERT INTO users (id, plan, credits) VALUES (?, ?, ?)')
    .bind(userId, 'free', 10)
    .run();
  return { userId };
}
```

**D1 DDL 참고**: `workers/migrations/0001_init.sql`의 `users` 테이블

### Step 4: Presets Route (presets.route.ts)

```typescript
// GET /presets → 프리셋 목록 반환 (presets.data.ts에서 import)
// GET /presets/:id → 프리셋 상세 반환
// 인증 필요 (auth middleware 적용)
// 매우 간단 — presets.data.ts가 이미 완성됨
```

### Step 5: Rules CRUD (rules.route.ts + rules.service.ts + rules.validator.ts)

```typescript
// POST /rules   → 룰 저장 (UserLimiterDO.checkRuleSlot() 호출 필요)
// GET /rules    → 내 룰 목록 (D1 SELECT WHERE user_id=?)
// PUT /rules/:id   → 룰 수정
// DELETE /rules/:id → 룰 삭제 (UserLimiterDO.decrementRuleSlot() 호출 필요)

// ⚠️ POST/DELETE에서 DO 호출 필요 → 팀원 B의 UserLimiterDO에 의존
// → DO가 아직 없으면 stub으로 우회:
async function checkRuleSlotStub(): Promise<boolean> { return true; }
// → 팀원 B 완성 후 실제 DO 호출로 교체
```

**Zod 스키마 (rules.validator.ts)**:
```typescript
import { z } from 'zod';

export const CreateRuleSchema = z.object({
  name: z.string().min(1).max(50),
  preset_id: z.enum(['interior', 'seller']),
  concepts: z.record(z.object({
    action: z.enum(['recolor', 'tone', 'texture', 'remove']),
    value: z.string(),
  })),
  protect: z.array(z.string()).optional(),
});
```

### Step 6: R2 Presigned URL (r2.ts)

```typescript
// aws4fetch 패키지 사용
// generatePresignedUrl(bucket, key, method, expiresIn)
// Jobs 라우트(팀원 B)에서 사용하지만, 유틸리티이므로 A가 구현

import { AwsClient } from 'aws4fetch';

export function createR2Client(env: Env): AwsClient {
  return new AwsClient({
    accessKeyId: env.R2_ACCESS_KEY_ID,     // wrangler.toml 또는 .dev.vars
    secretAccessKey: env.R2_SECRET_ACCESS_KEY,
    region: 'auto',
  });
}

export async function generatePresignedUrl(
  client: AwsClient, bucket: string, key: string, method: 'GET' | 'PUT', expiresIn = 3600
): Promise<string> {
  // R2 presigned URL 생성 로직
}
```

---

## 참고 문서

| 문서 | 위치 | 참고 섹션 |
|------|------|----------|
| API 스키마 | `workflow.md` | 섹션 6 (6.1~6.4) |
| D1 DDL | `workers/migrations/0001_init.sql` | users, rules 테이블 |
| 타입 정의 | `workers/src/_shared/types.ts` | 전체 |
| 에러 코드 | `workers/src/_shared/errors.ts` | 전체 |
| 응답 헬퍼 | `workers/src/_shared/response.ts` | ok(), error() |
| 프리셋 데이터 | `workers/src/presets/presets.data.ts` | PRESETS 객체 |

---

## 환경 설정

```bash
cd workers/
npm install

cp .dev.vars.example .dev.vars
# JWT_SECRET=your-dev-secret-32-chars-minimum
# GPU_CALLBACK_SECRET=your-callback-secret

# D1 로컬 마이그레이션
npx wrangler d1 execute s3-db --local --file=migrations/0001_init.sql

# 로컬 실행
npx wrangler dev

# 타입 체크
npx tsc --noEmit
```

---

## Cloudflare MCP 활용 (필수)

> Cloudflare를 몰라도 MCP가 대신해줍니다. 아래 패턴을 꼭 활용하세요.

### 코드 작성 전: 공식 문서 먼저

```
"Hono에서 미들웨어 작성하는 방법 알려줘"
→ context7: resolve-library-id → query-docs

"D1에서 prepare().bind().run() 사용법 알려줘"
→ cloudflare-observability: search_cloudflare_documentation
```

### 배포 후: 에러 확인

```
"s3-api Workers에서 최근 에러 보여줘"
→ cloudflare-observability: query_worker_observability

"배포된 코드 확인해줘"
→ cloudflare-observability: workers_get_worker_code
```

### JWT 구현 시 참고

```
"hono/jwt에서 sign과 verify 사용법"
→ context7로 Hono 문서 조회
```

> **중요 변경 (v3.0)**: JWT에 `plan` 필드를 넣지 않음. `sub`(user_id), `iat`, `exp`만.
> plan은 UserLimiterDO가 Source of Truth. auth middleware에서 `c.set('user', { userId })`만 설정.

---

## 코딩 규칙

1. **Hono 패턴**: 각 route 파일 = 독립 Hono 인스턴스 → `export default app`
2. **D1 쿼리**: `env.DB.prepare(sql).bind(...).run()` / `.first()` / `.all()`
3. **응답**: 반드시 `ok(data)` 또는 `error(ERR.XXX)` 사용 (response.ts)
4. **인증**: auth middleware 통과 후 `c.get('user')?.userId`로 접근
5. **타입**: `types.ts`에서 import. 새 타입 필요하면 리드에게 요청
6. **에러**: `errors.ts`의 `ERR` 객체 사용. 새 에러 필요하면 리드에게 요청

---

## 팀원 B와의 인터페이스

팀원 B(DO+Jobs)가 사용할 것들:
- **jwt.ts** → B의 callback 인증에서 사용
- **auth.middleware.ts** → B의 jobs/user 라우트에 적용
- **r2.ts** → B의 jobs 라우트에서 presigned URL 생성

**약속**: Step 1~2 (JWT + Auth middleware)를 최우선 완성 → B가 활용 가능.
B 완성 전까지 Rules의 DO 호출은 stub 사용.

---

## 완료 기준

- [ ] POST /auth/anon → JWT 발급 + D1 user 생성 동작
- [ ] Auth middleware → 유효 JWT 통과, 무효 JWT 401 반환
- [ ] GET /presets → 프리셋 목록 반환
- [ ] GET /presets/:id → 프리셋 상세 반환
- [ ] POST /rules → 룰 저장 (D1 INSERT)
- [ ] GET /rules → 내 룰 목록
- [ ] PUT /rules/:id → 룰 수정
- [ ] DELETE /rules/:id → 룰 삭제
- [ ] `npx tsc --noEmit` 에러 없음
- [ ] `npx wrangler dev`로 로컬 테스트 통과
