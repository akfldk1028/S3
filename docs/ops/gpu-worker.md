# GPU Worker 운영 가이드

## ⚠️ 최우선 규칙: 테스트 후 반드시 endpoint 삭제!

**Runpod endpoint가 살아있으면 workersStandby=1 때문에 24시간 과금됨.**
- RTX 3090: ~$0.46/hr = **~$11/일**
- 테스트 끝나면 반드시 `delete-endpoint`

---

## GPU 켜기 (테스트 시작)

### 1. Runpod Endpoint 생성
```
MCP: mcp__runpod__create-endpoint
  name: "s3-gpu"
  templateId: "k9jc9psfs6"
  dataCenterIds: ["EU-CZ-1"]
  gpuTypeIds: ["NVIDIA GeForce RTX 3090", "NVIDIA RTX A4000", "NVIDIA GeForce RTX 4090", "NVIDIA RTX A6000"]
  workersMin: 0
  workersMax: 1
```

### 2. Workers에 새 endpoint ID 등록
```bash
cd workers
echo "<새_ENDPOINT_ID>" | npx wrangler secret put RUNPOD_ENDPOINT_ID
npx wrangler deploy
```

### 3. 테스트 (첫 요청에 cold start ~50초, 이후 즉시)

---

## GPU 끄기 (테스트 종료)

### 반드시 실행:
```
MCP: mcp__runpod__delete-endpoint
  endpointId: "<ENDPOINT_ID>"
```

### 확인:
```
MCP: mcp__runpod__list-endpoints
→ 빈 배열 [] 이면 OK
```

---

## Runpod 설정 정보

| 항목 | 값 |
|------|-----|
| Template ID | `k9jc9psfs6` |
| Docker Image | `jonghwan0309/sam3-worker:test` |
| DataCenter | EU-CZ-1 (SECURE 클라우드) |
| GPU 비용 | RTX 3090: $0.46/hr, RTX 4090: $0.59/hr |

## Template 환경변수 (이미 설정됨)

| 변수 | 설명 |
|------|------|
| R2_ACCOUNT_ID | CF R2 계정 ID |
| R2_ACCESS_KEY_ID | R2 접근 키 |
| R2_SECRET_ACCESS_KEY | R2 시크릿 |
| R2_BUCKET_NAME | s3-images |
| GPU_CALLBACK_SECRET | Workers callback 인증 시크릿 |
| WORKERS_API_URL | https://s3-workers.clickaround8.workers.dev |

## Dockerfile 주의사항

Runpod serverless에서 handler가 동작하려면:
```dockerfile
FROM python:3.11-slim
WORKDIR /                    # 반드시 / (NOT /app)
COPY handler.py /handler.py  # 절대경로
CMD ["python3", "-u", "/handler.py"]  # python3 (NOT python)
```

- `WORKDIR /app` 사용하면 crash loop 발생
- `python` 대신 `python3` 사용

## 현재 상태

- **test 이미지**: 더미 처리 (SAM3 없음). 파이프라인 검증용. E2E 성공 확인됨.
- **latest 이미지**: CUDA + SAM3 + 모델 가중치. 10.8GB. Dockerfile 패턴 수정 필요.
- **SAM3 통합 남음**: 가중치 다운로드 → Dockerfile 수정 → 빌드/push