# S3 Supabase — Database + Auth + Realtime

> PostgreSQL 데이터베이스, 인증, 실시간 알림을 제공하는 BaaS 레이어.

---

## Overview

- **Database**: PostgreSQL 15 (Supabase hosted)
- **Auth**: Supabase Auth (Email/Password, 추후 Google OAuth)
- **Realtime**: segmentation_results 테이블 구독
- **Edge Functions**: Deno runtime (webhook 처리)
- **Migration**: 타임스탬프 기반 (`YYYYMMDDHHmmss_description.sql`)

---

## Database Schema (4 Tables)

### ERD

```
┌──────────────────┐       ┌──────────────────────┐
│   users_profile   │       │      projects         │
│──────────────────│       │──────────────────────│
│ id (PK, =auth.id)│◀──┐   │ id (PK, UUID)         │
│ display_name      │   │   │ user_id (FK) ─────────┘
│ avatar_url        │   │   │ name                   │
│ tier (enum)       │   │   │ description            │
│ credits (int)     │   │   │ created_at             │
│ created_at        │   │   │ updated_at             │
│ updated_at        │   │   └──────────────────────┘
└──────────────────┘   │
        ▲               │   ┌──────────────────────────────┐
        │               │   │   segmentation_results        │
        │               │   │──────────────────────────────│
        │               ├──▶│ id (PK, UUID)                 │
        │               │   │ user_id (FK) ─────────────────┘
        │               │   │ project_id (FK, nullable) ────┐
        │               │   │ source_image_url               │→ projects.id
        │               │   │ mask_image_url                 │
        │               │   │ text_prompt                    │
        │               │   │ status (enum)                  │
        │               │   │ labels (JSONB)                 │
        │               │   │ metadata (JSONB)               │
        │               │   │ created_at, updated_at         │
        │               │   └──────────────────────────────┘
        │               │
        │               │   ┌──────────────────────┐
        │               └──▶│    usage_logs          │
        │                   │──────────────────────│
        └───────────────────│ user_id (FK)          │
                            │ id (PK, UUID)         │
                            │ action (enum)         │
                            │ credits_used (int)    │
                            │ metadata (JSONB)      │
                            │ created_at            │
                            └──────────────────────┘
```

### Enum Values

| Column | Values |
|--------|--------|
| `users_profile.tier` | `'free'`, `'pro'`, `'enterprise'` |
| `segmentation_results.status` | `'pending'`, `'processing'`, `'done'`, `'error'` |
| `usage_logs.action` | `'segmentation'`, `'upload'` |

---

## RLS Policies

| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| `users_profile` | `auth.uid() = id` | `auth.uid() = id` | `auth.uid() = id` | `auth.uid() = id` |
| `projects` | `auth.uid() = user_id` | `auth.uid() = user_id` | `auth.uid() = user_id` | `auth.uid() = user_id` |
| `segmentation_results` | `auth.uid() = user_id` | `auth.uid() = user_id` | `auth.uid() = user_id` | `auth.uid() = user_id` |
| `usage_logs` | `auth.uid() = user_id` | `WITH CHECK (true)` * | - | - |

\* `usage_logs` INSERT는 service_role에서만 사용 (Backend/Edge가 직접 삽입)

---

## File Map

```
supabase/
├── config.toml                                          ✅ 프로젝트 설정
├── migrations/
│   ├── 20260209120000_create_users_profile.sql          ✅ 테이블 + RLS + trigger
│   ├── 20260209120001_create_projects.sql               ✅ 테이블 + RLS
│   ├── 20260209120002_create_segmentation_results.sql   ✅ 테이블 + RLS + Realtime
│   └── 20260209120003_create_usage_logs.sql             ✅ 테이블 + RLS
├── functions/
│   ├── _shared/                                         공유 코드 (배포 안됨)
│   │   ├── cors.ts                                      ✅ CORS 헤더
│   │   └── supabase-client.ts                           ✅ Admin client factory
│   └── process-webhook/                                 Edge Function
│       └── index.ts                                     🔲 webhook 처리 (stub)
├── seed.sql                                             ✅ 시드 데이터 (빈 파일)
└── README.md                                            ← 이 파일
```

**범례:** ✅ = 구현 완료 | 🔲 = stub (TODO)

---

## Agent 작업 가이드

> 이 레이어를 개발할 에이전트를 위한 **단계별 지침**.

### Step 1: 로컬 Supabase 시작 + 마이그레이션 검증

```bash
supabase start          # Docker 기반 로컬 Supabase 시작
supabase db push        # 마이그레이션 적용
supabase status         # URL, API keys 확인
```

- 4개 테이블 생성 확인 (Studio: http://localhost:54323)
- RLS 정책 확인
- `handle_new_user()` trigger 확인: 회원가입 → users_profile 자동 생성

### Step 2: process-webhook Edge Function 구현

**파일:** `functions/process-webhook/index.ts`
**목표:** Backend 추론 완료 시 호출되는 webhook

구현할 내용:
1. API Key 검증 (`X-API-Key` 헤더)
2. `segmentation_results` UPDATE (status, mask_image_url, labels, metadata)
3. `usage_logs` INSERT (credits 차감)
4. `users_profile` UPDATE (credits 감소)

```bash
# 로컬 테스트
supabase functions serve
curl -X POST http://localhost:54321/functions/v1/process-webhook \
  -H "Content-Type: application/json" \
  -d '{"task_id":"...", "status":"done", "mask_url":"...", "labels":[]}'
```

### Step 3: 추가 Edge Functions (선택)

필요 시 추가:
- `credit-check/` — 크레딧 잔액 확인
- `cleanup-old-results/` — 오래된 결과 정리 (cron)

### Step 4: RLS 정책 테스트

다양한 유저 시나리오로 RLS 검증:
- 유저 A가 유저 B의 데이터 접근 시도 → 거부 확인
- service_role로 usage_logs INSERT → 성공 확인
- 인증 없이 접근 → 거부 확인

### Step 5: Realtime 구독 테스트

`segmentation_results` 테이블에 Realtime 활성화 확인:
- INSERT/UPDATE 시 클라이언트에 이벤트 전달
- Flutter에서 `supabase.from('segmentation_results').stream(...)` 구독

---

## 의존하는 계약

| 대상 | 설명 | 파일 |
|------|------|------|
| Frontend → Supabase Auth | 로그인/회원가입 (SDK 직접 사용) | `docs/contracts/api-contracts.md` Auth Flow |
| Frontend → Supabase DB | 결과 조회 (Realtime 구독 포함) | `supabase/migrations/` |
| Edge → Supabase | **모든 CRUD** 담당 (anon key + JWT, RLS 적용) | `edge/.dev.vars` |
| Backend → Supabase | 추론 완료 시 **결과 UPDATE만** (service_role) | `backend/.env` SUPABASE_SERVICE_KEY |
| Backend → process-webhook | 추론 완료 시 webhook 호출 (선택) | `supabase/functions/process-webhook/` |

---

## 코드 패턴

### 새 마이그레이션 추가

```bash
# Supabase CLI가 타임스탬프 자동 생성
supabase migration new add_payment_table
# → migrations/20260210143000_add_payment_table.sql 생성
```

```sql
-- 항상 RLS 활성화
CREATE TABLE IF NOT EXISTS payments (...);
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "..." ON payments FOR SELECT USING (auth.uid() = user_id);
```

### 새 Edge Function 추가

```bash
supabase functions new function-name
# → functions/function-name/index.ts 생성 (kebab-case 필수)
```

```typescript
// functions/function-name/index.ts
import { createSupabaseAdmin } from '../_shared/supabase-client.ts';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }
  const supabase = createSupabaseAdmin();
  // ...
});
```

```toml
# config.toml에 추가
[functions.function-name]
verify_jwt = true  # 또는 false (webhook용)
```

---

## 규칙

- **마이그레이션 네이밍**: `YYYYMMDDHHmmss_description.sql` (타임스탬프)
- **Edge Functions**: kebab-case 디렉토리명
- **공유 코드**: `_shared/` (언더스코어 접두사 = 배포 안됨)
- **모든 테이블 RLS 활성화**
- **Trigger**: `update_updated_at()` 공유 함수 사용

---

## Setup & Run

```bash
supabase start          # 로컬 Supabase 시작
supabase db push        # 마이그레이션 적용
supabase db reset       # 초기화 + seed.sql
supabase status         # URL, API keys 확인
supabase functions serve # Edge Functions 로컬 실행
```
