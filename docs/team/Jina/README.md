# Jina — Workers 백엔드 확인사항

> 브랜치: `jina_workers` → DK-A에서 변경된 내용 머지 필요

## 반드시 확인

### 1. R2 키 패턴 변경됨
이전:
```
inputs/{userId}/{jobId}/{idx}.jpg
outputs/{userId}/{jobId}/{idx}_result.png
```

현재:
```
{userId}/{preset}/{jobId}/originals/{idx}.jpg
{userId}/{preset}/{jobId}/results/{idx}_result.png
{userId}/{preset}/{jobId}/previews/{idx}_thumb.jpg
```

- **파일**: `workers/src/jobs/jobs.service.ts:16-18`
- **파일**: `workers/src/jobs/jobs.route.ts:160-167`

### 2. types.ts — action 타입 변경
```typescript
// 이전
concepts: Record<string, { action: string; value: string }>;

// 현재
concepts: Record<string, { action: 'recolor' | 'generate'; value: string }>;
```
- **파일**: `workers/src/_shared/types.ts:85`

### 3. jobs.validator.ts — action enum + value max
```typescript
action: z.enum(['recolor', 'generate']),
value: z.string().min(1).max(500),
```
- **파일**: `workers/src/jobs/jobs.validator.ts:15-16`

### 4. index.ts — Queue consumer GPU guard
- `RUNPOD_ENDPOINT_ID` 없으면 graceful skip (msg.ack + continue)
- **파일**: `workers/src/index.ts:97~`

### 5. Secrets 현재 상태
| Secret | 상태 |
|--------|------|
| JWT_SECRET | ✅ |
| GPU_CALLBACK_SECRET | ✅ |
| RUNPOD_ENDPOINT_ID | ⚠️ endpoint 삭제됨 — 테스트 시 재설정 |
| RUNPOD_API_KEY | ✅ |
| R2_ACCOUNT_ID | ✅ |
| R2_ACCESS_KEY_ID | ✅ |
| R2_SECRET_ACCESS_KEY | ✅ |
| R2_BUCKET_NAME | ✅ |

### 6. Workers 배포
```bash
cd workers
npx tsc --noEmit   # 타입 체크
npx wrangler deploy
```

## 참고 문서
- `docs/ops/workers-deploy.md` — 배포 + secrets 전체 목록
- `docs/ops/architecture.md` — API 14개 목록
