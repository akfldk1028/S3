# S3 Edge — Full API on Cloudflare Workers

> Flutter 앱의 **유일한 API 서버**.
> Auth, CRUD, R2 저장, Supabase 연동, Backend 추론 프록시 **모두** 담당.

---

## Overview

- **Framework**: [Hono](https://hono.dev/) (Cloudflare Workers 표준 프레임워크)
- **Runtime**: Cloudflare Workers (V8 isolate)
- **Storage**: Cloudflare R2 (이미지 직접 업로드)
- **DB**: Supabase REST API (모든 CRUD 담당)
- **Auth**: Supabase JWT 검증
- **Language**: TypeScript (ES2022)
- **Entry Point**: `src/index.ts` → `export default app`

### 역할 분담

| 담당 | Edge (이 서버) | Backend (Vast.ai GPU) |
|------|---------------|----------------------|
| Auth | ★ Supabase JWT 검증 | X-API-Key만 확인 |
| R2 Upload | ★ 사용자 이미지 직접 업로드 | 마스크 업로드 (boto3) |
| Supabase CRUD | ★ 모든 INSERT/SELECT (anon key + JWT) | UPDATE만 (service_role) |
| 크레딧 확인 | ★ 확인 + 차감 | - |
| 추론 | Backend 프록시 (비동기) | ★ SAM3 추론 |

---

## API Endpoints (Public — Flutter가 호출)

> Base URL: `https://s3-api.{domain}.workers.dev`
> Auth: `Authorization: Bearer <supabase_jwt>`
> 상세 Request/Response: `docs/contracts/api-contracts.md`

| Method | Path | Auth | Description | 처리 |
|--------|------|------|-------------|------|
| `GET` | `/health` | No | 서버 헬스체크 | 직접 |
| `POST` | `/api/v1/upload` | Yes | 이미지 → R2 저장 | R2 직접 |
| `POST` | `/api/v1/segment` | Yes | 세그멘테이션 요청 | Supabase INSERT → Backend 프록시 |
| `GET` | `/api/v1/tasks/:id` | Yes | 작업 상태 조회 | Supabase SELECT |
| `GET` | `/api/v1/results` | Yes | 결과 목록 | Supabase SELECT |
| `GET` | `/api/v1/results/:id` | Yes | 결과 상세 | Supabase SELECT |

---

## File Map

```
edge/
├── src/
│   ├── index.ts                       ✅ Hono entry + route mount + global middleware
│   ├── routes/
│   │   ├── upload.ts                  ✅ POST /upload (Full 구현)
│   │   ├── segment.ts                 ✅ POST /segment (Full 구현)
│   │   └── results.ts                 ✅ GET /tasks/:id, /results, /results/:id (Full 구현)
│   ├── middleware/
│   │   └── auth.ts                    🔲 Supabase JWT 검증 (stub, Bearer 유무만 확인)
│   ├── services/
│   │   ├── r2.ts                      ✅ R2 업로드/다운로드/URL 생성
│   │   ├── vastai.ts                  ✅ Backend 추론 프록시
│   │   └── supabase.ts               ✅ Supabase REST API CRUD
│   ├── utils/
│   │   ├── response.ts               ✅ Response envelope (ok/error)
│   │   └── validation.ts             ✅ 요청 검증 (파일 크기/타입, 세그멘테이션 요청)
│   └── types/
│       └── index.ts                   ✅ Env, AuthUser, ApiResponse, TaskStatus, SegmentationResultRow
├── wrangler.jsonc                     ✅ R2 binding 설정
├── package.json                       ✅ hono ^4.7.0
├── tsconfig.json                      ✅ ES2022 + strict
├── .dev.vars.example                  ✅ 환경변수 템플릿
└── README.md                          ← 이 파일
```

**범례:** ✅ = 구현 완료 | 🔲 = stub (TODO)

---

## Agent 작업 가이드

> 이 레이어를 개발할 에이전트를 위한 **단계별 지침**.
> **주의:** Edge가 Full API. 모든 CRUD/Auth/R2 업로드를 여기서 처리.

### Step 1: Auth 미들웨어 (`src/middleware/auth.ts`)

**목표:** Supabase JWKS 검증으로 JWT 토큰 디코딩

- Supabase의 `/.well-known/jwks.json` 에서 공개키 가져오기
- JWT 디코딩 → `sub` (user_id) + `user_metadata.tier` 추출
- `c.set('user', { userId, tier, jwt: token })` 로 context에 저장
- **중요:** `jwt` 필드는 Supabase REST API 호출 시 Authorization 헤더로 사용
- **검증:** `curl -H "Authorization: Bearer <valid_jwt>" http://localhost:8787/api/v1/results` → 200

### Step 2: Supabase Client 테스트 (`src/services/supabase.ts`)

**목표:** Supabase REST API 호출 검증

- `getUserCredits()` — 유저 크레딧 조회
- `createSegmentationResult()` — segmentation_results INSERT
- `getSegmentationResult()` — 단일 결과 조회
- `listSegmentationResults()` — 목록 조회 (pagination)
- **검증:** wrangler dev에서 실제 Supabase 연동 테스트

### Step 3: R2 서비스 테스트 (`src/services/r2.ts`)

**목표:** R2 binding으로 이미지 업로드/다운로드 검증

- `uploadToR2(r2, key, data, contentType)` — 구현 완료
- `getFromR2(r2, key)` — 구현 완료
- `getR2PublicUrl(env, key)` — TODO: 프로덕션 URL
- **검증:** wrangler dev에서 실제 R2 업로드 테스트

### Step 4: Upload 라우트 테스트 (`src/routes/upload.ts`)

**목표:** multipart/form-data 이미지 → R2 저장 → URL 반환 검증

- 파일 크기/타입 검증 확인
- R2 업로드 정상 동작 확인

### Step 5: Segment 라우트 테스트 (`src/routes/segment.ts`)

**목표:** 전체 세그멘테이션 요청 흐름 검증

- 크레딧 확인 → Supabase INSERT → Backend 프록시 → 즉시 응답
- `waitUntil` 비동기 처리 확인

### Step 6: Rate Limiting (선택)

**목표:** KV Namespace로 per-user rate limit

- `wrangler.jsonc`에 KV binding 추가
- sliding window counter 패턴
- tier별 제한: free=10/min, pro=100/min

---

## 의존하는 계약

| 대상 | 설명 | 파일 |
|------|------|------|
| Frontend → Edge | Flutter가 `Authorization: Bearer <jwt>` 로 호출 | `docs/contracts/api-contracts.md` |
| Edge → Backend | `X-API-Key` 헤더로 predict 호출 (비동기) | `docs/contracts/api-contracts.md` |
| Edge → R2 | wrangler.jsonc R2 binding (`c.env.R2`) | `edge/wrangler.jsonc` |
| Edge → Supabase | JWT + anon key로 모든 CRUD | `edge/.dev.vars` |

---

## 코드 패턴

### Response Envelope 사용 (response.ts)

```typescript
import { ok, error } from '../utils/response';

// 성공
return c.json(ok({ image_url: '...', image_id: '...' }), 200);

// 실패
return c.json(error('FILE_TOO_LARGE', 'File exceeds 10MB limit'), 413);
```

### Supabase REST API 호출 (supabase.ts)

```typescript
import { getUserCredits, createSegmentationResult } from '../services/supabase';

// 유저 크레딧 확인
const userInfo = await getUserCredits(c.env, user.userId, user.jwt);
if (!userInfo || userInfo.credits <= 0) {
  return c.json(error('INSUFFICIENT_CREDITS', 'Not enough credits'), 402);
}

// segmentation_results INSERT
await createSegmentationResult(c.env, user.jwt, { ... });
```

### 새 라우트 추가

```typescript
// 1. src/apiroutes/new-route.ts — 독립 Hono 인스턴스
import { Hono } from 'hono';
import { authMiddleware, type AuthVariables } from '../middleware/auth';
import { ok, error } from '../utils/response';
import type { Env } from '../types';

const app = new Hono<{ Bindings: Env; Variables: AuthVariables }>();
app.use('*', authMiddleware);

app.get('/', async (c) => {
  const user = c.get('user');
  return c.json(ok({ userId: user.userId }));
});

export default app;

// 2. src/index.ts에 마운트
import newRoute from './apiroutes/new-route';
app.route('/api/v1/new', newRoute);
```

---

## Setup & Run

```bash
# 의존성
npm install

# 환경변수
cp .dev.vars.example .dev.vars

# 로컬 개발
npx wrangler dev

# 타입 체크
npx tsc --noEmit

# 배포
npx wrangler deploy
```

---

## Environment Variables

`.dev.vars` (로컬) / Cloudflare Dashboard (프로덕션):

| Variable | Description |
|----------|-------------|
| `VASTAI_BACKEND_URL` | Backend GPU 서버 URL (추론 프록시용) |
| `API_SECRET_KEY` | Backend 인증 키 |
| `SUPABASE_URL` | Supabase 프로젝트 URL |
| `SUPABASE_ANON_KEY` | Supabase Anon Key (CRUD용) |

R2 Binding은 `wrangler.jsonc`에서 설정 (`c.env.R2`).
