# S3 API Contracts

> **이 파일은 더 이상 SSoT가 아닙니다.**
> **SSoT = `workflow.md` 섹션 6 (API 엔드포인트)**
>
> 아키텍처가 Supabase 기반 → Cloudflare 네이티브 (Workers + D1 + DO + Queues + R2)로 전환됨.
> 모든 API 스키마는 `workflow.md`를 참조하세요.

---

## 아키텍처 (현행)

```
Flutter App → Workers (Hono + D1 + DO + Queues + R2) → GPU Worker (Docker + Runpod)
```

- **Workers = 유일한 API 서버** — 14개 엔드포인트
- **GPU Worker = 추론 전용** — Queue 소비 + Workers callback
- **Supabase 제거** — D1 + DO로 완전 대체

## API 엔드포인트 (14개)

> Base: `https://s3-api.{domain}.workers.dev`
> Auth: `Authorization: Bearer <JWT>` (Workers 자체 HS256 서명)
> Envelope: `{ success, data, error, meta: { request_id, timestamp } }`

| # | Method | Path | 설명 |
|---|--------|------|------|
| 1 | POST | `/auth/anon` | 익명 유저 생성 + JWT |
| 2 | GET | `/me` | 유저 상태 (credits, plan, rule_slots) |
| 3 | GET | `/presets` | 도메인 프리셋 목록 |
| 4 | GET | `/presets/{id}` | 프리셋 상세 |
| 5 | POST | `/rules` | 룰 저장 |
| 6 | GET | `/rules` | 내 룰 목록 |
| 7 | PUT | `/rules/{id}` | 룰 수정 |
| 8 | DELETE | `/rules/{id}` | 룰 삭제 |
| 9 | POST | `/jobs` | Job 생성 + presigned URLs |
| 10 | POST | `/jobs/{id}/confirm-upload` | 업로드 완료 확인 |
| 11 | POST | `/jobs/{id}/execute` | 룰 적용 실행 (Queue push) |
| 12 | GET | `/jobs/{id}` | 상태/진행률 조회 |
| 13 | POST | `/jobs/{id}/callback` | GPU Worker 콜백 (내부) |
| 14 | POST | `/jobs/{id}/cancel` | Job 취소 + 크레딧 환불 |

## 상세 스키마

**→ `workflow.md` 섹션 6 참조** (Request/Response body, status codes, 서버 처리 로직 모두 포함)

## Response Envelope

```typescript
interface ApiResponse<T> {
  success: boolean;
  data: T | null;
  error: { code: string; message: string } | null;
  meta: {
    request_id: string;
    timestamp: string;
  };
}
```

## Error Codes

| Code | HTTP | Description |
|------|------|-------------|
| `AUTH_REQUIRED` | 401 | JWT 없음 |
| `AUTH_INVALID` | 401 | JWT 만료/유효하지 않음 |
| `NOT_FOUND` | 404 | 리소스 없음 |
| `INVALID_REQUEST` | 400 | 잘못된 요청 |
| `INSUFFICIENT_CREDITS` | 402 | 크레딧 부족 |
| `RULE_SLOT_FULL` | 403 | 룰 슬롯 초과 (free=2, pro=20) |
| `CONCURRENCY_LIMIT` | 429 | 동시 Job 초과 (free=1, pro=3) |
| `JOB_NOT_FOUND` | 404 | Job 없음 |
| `JOB_WRONG_STATE` | 409 | Job 상태 불일치 (예: uploaded 아닌데 execute 시도) |
| `INTERNAL_ERROR` | 500 | 내부 에러 |

## Rate Limits

| Tier | 동시 Job | 룰 슬롯 | 1 Job 최대 장수 |
|------|----------|---------|----------------|
| **free** | 1 | 2 | 10 |
| **pro** | 3 | 20 | 200 |
