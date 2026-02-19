# 팀원 A: Workers Core — Auth + JWT + Presets + Rules

> **담당**: Workers의 인증/인가 기반 + CRUD 엔드포인트
> **상태**: ✅ **전부 완료 + 배포됨** (2026-02-15)
> **브랜치**: master (머지 완료)

---

## 현재 상태 (2026-02-19)

### ✅ 완료된 작업

| 항목 | 상태 | 파일 |
|------|------|------|
| JWT sign/verify | ✅ 완료 | `workers/src/_shared/jwt.ts` |
| Auth middleware | ✅ 완료 | `workers/src/middleware/auth.middleware.ts` |
| POST /auth/anon | ✅ 완료 | `workers/src/auth/auth.route.ts` |
| Auth service (D1) | ✅ 완료 | `workers/src/auth/auth.service.ts` |
| GET /presets | ✅ 완료 | `workers/src/presets/presets.route.ts` |
| GET /presets/:id | ✅ 완료 | `workers/src/presets/presets.route.ts` |
| Presets data | ✅ 완료 | `workers/src/presets/presets.data.ts` |
| POST /rules | ✅ 완료 | `workers/src/rules/rules.route.ts` |
| GET /rules | ✅ 완료 | `workers/src/rules/rules.route.ts` |
| PUT /rules/:id | ✅ 완료 | `workers/src/rules/rules.route.ts` |
| DELETE /rules/:id | ✅ 완료 | `workers/src/rules/rules.route.ts` |
| Rules D1 CRUD | ✅ 완료 | `workers/src/rules/rules.service.ts` |
| Rules Zod validator | ✅ 완료 | `workers/src/rules/rules.validator.ts` |
| R2 presigned URL | ✅ 완료 | `workers/src/_shared/r2.ts` |
| TypeScript 0 errors | ✅ 완료 | `npx tsc --noEmit` |
| 배포 | ✅ 완료 | `npx wrangler deploy` |

---

## 남은 작업: 없음

모든 항목 구현 + 배포 완료. 유지보수 대기.

### 버그 발견 시 대응 가이드

1. **에러 로그 확인**:
   ```
   cloudflare-observability → query_worker_observability
   "s3-workers에서 auth/rules 관련 에러 보여줘"
   ```

2. **코드 확인할 파일**:
   - `workers/src/auth/auth.route.ts` — anon auth
   - `workers/src/auth/auth.service.ts` — D1 user 생성
   - `workers/src/middleware/auth.middleware.ts` — JWT 검증
   - `workers/src/rules/rules.route.ts` — 4개 CRUD
   - `workers/src/rules/rules.service.ts` — D1 쿼리
   - `workers/src/_shared/jwt.ts` — JWT sign/verify
   - `workers/src/_shared/r2.ts` — presigned URL
   - `workers/src/_shared/types.ts` — 타입 정의 (수정 금지)
   - `workers/src/_shared/errors.ts` — 에러 코드
   - `workers/src/_shared/response.ts` — ok()/error()

3. **로컬 테스트**:
   ```bash
   cd workers && npm install && npx wrangler dev
   npx tsc --noEmit
   ```

4. **재배포**:
   ```bash
   cd workers && npx wrangler deploy
   ```

---

## 완료 기준 (전부 ✅)

- [x] POST /auth/anon → JWT 발급 + D1 user 생성 동작
- [x] Auth middleware → 유효 JWT 통과, 무효 JWT 401 반환
- [x] GET /presets → 프리셋 목록 반환
- [x] GET /presets/:id → 프리셋 상세 반환
- [x] POST /rules → 룰 저장 (D1 INSERT)
- [x] GET /rules → 내 룰 목록
- [x] PUT /rules/:id → 룰 수정
- [x] DELETE /rules/:id → 룰 삭제
- [x] `npx tsc --noEmit` 에러 없음
- [x] `npx wrangler deploy` 배포 성공
