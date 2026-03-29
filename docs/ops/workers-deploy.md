# Workers 배포 가이드

## 배포 명령

```bash
cd workers
npx wrangler deploy
```

## Secrets 목록 (wrangler secret put)

| Secret | 설명 | 상태 |
|--------|------|------|
| JWT_SECRET | JWT HS256 서명키 | ✅ 설정됨 |
| GPU_CALLBACK_SECRET | GPU Worker callback 인증 | ✅ `oj_Q5FMtEPnWy6crOSOyre3hbRt0b1UtJqTHcK2ZMpI` |
| RUNPOD_ENDPOINT_ID | Runpod Serverless endpoint ID | ⚠️ endpoint 생성 시마다 변경 |
| RUNPOD_API_KEY | Runpod API 키 | ✅ 설정됨 |
| R2_ACCOUNT_ID | CF R2 계정 ID | ✅ 설정됨 |
| R2_ACCESS_KEY_ID | R2 접근 키 | ✅ 설정됨 |
| R2_SECRET_ACCESS_KEY | R2 시크릿 키 | ✅ 설정됨 |
| R2_BUCKET_NAME | R2 버킷명 (s3-images) | ✅ 설정됨 |

## 바인딩 (wrangler.toml)

| 바인딩 | 리소스 |
|--------|--------|
| DB | D1: s3-db |
| R2 | R2: s3-images |
| USER_LIMITER | DO: UserLimiterDO |
| JOB_COORDINATOR | DO: JobCoordinatorDO |
| GPU_QUEUE | Queue: gpu-jobs |

## 코드 수정 후 체크리스트

1. `npx tsc --noEmit` — 타입 에러 확인
2. `npx wrangler deploy` — 배포
3. `curl https://s3-workers.clickaround8.workers.dev/health` — 헬스 체크
4. GPU 테스트 필요하면 → `docs/ops/gpu-worker.md` 참조