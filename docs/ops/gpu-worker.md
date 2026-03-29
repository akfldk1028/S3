# GPU Worker 운영 가이드

## ⚠️ 최우선 규칙: 테스트 후 반드시 endpoint 삭제!

**Runpod endpoint가 살아있으면 workersStandby=1 때문에 24시간 과금됨.**
- RTX 3090: ~$0.46/hr = **~$11/일**
- 테스트 끝나면 반드시 `delete-endpoint`

---

## 성능 (2026-03-29 실측)

| 시나리오 | 시간 | 설명 |
|---------|------|------|
| Cold start (첫 요청) | ~3분 | 이미지 pull + SAM3 모델 GPU 로딩 |
| **Warm (모델 로드 후)** | **~16초** | R2↓ + SAM3 segment + recolor + R2↑ + callback |
| 프로덕션 (workersMin=1) | **~16초** | cold start 없음 |

---

## GPU 켜기 (전체 명령어)

### Step 1: Runpod Endpoint 생성
```
MCP 도구: mcp__runpod__create-endpoint

파라미터:
  name: "s3-gpu"
  templateId: "z56tvnfupt"
  dataCenterIds: ["EU-CZ-1"]
  gpuTypeIds: ["NVIDIA GeForce RTX 3090", "NVIDIA RTX A4000", "NVIDIA GeForce RTX 4090", "NVIDIA RTX A6000"]
  workersMin: 0
  workersMax: 1
```

### Step 2: Workers에 새 endpoint ID 등록 + 배포
```bash
cd workers
echo "<새_ENDPOINT_ID>" | npx wrangler secret put RUNPOD_ENDPOINT_ID
npx wrangler deploy
```

### Step 3: 테스트 (첫 요청 cold start ~3분, 이후 ~16초)
```bash
# Health check
curl -s https://s3-workers.clickaround8.workers.dev/health

# 전체 E2E 테스트는 docs/ops/e2e-test.md 참조
```

---

## GPU 끄기 (반드시 실행!)

```
MCP 도구: mcp__runpod__delete-endpoint
파라미터: endpointId: "<ENDPOINT_ID>"
```

확인:
```
MCP 도구: mcp__runpod__list-endpoints
→ 빈 배열 [] 이면 OK (과금 $0)
```

---

## Runpod 설정 정보

| 항목 | 값 |
|------|-----|
| Template ID | `z56tvnfupt` (containerDisk=30GB) |
| Docker Image | `jonghwan0309/sam3-worker:v2` |
| DataCenter | EU-CZ-1 (SECURE 클라우드) |
| Docker Hub 계정 | jonghwan0309 |

## Template 환경변수 (이미 설정됨 — 건드리지 말 것)

| 변수 | 설명 |
|------|------|
| R2_ACCOUNT_ID | CF R2 계정 ID |
| R2_ACCESS_KEY_ID | R2 접근 키 |
| R2_SECRET_ACCESS_KEY | R2 시크릿 |
| R2_BUCKET_NAME | s3-images |
| GPU_CALLBACK_SECRET | Workers callback 인증 |
| WORKERS_API_URL | https://s3-workers.clickaround8.workers.dev |

## Docker 이미지

| 태그 | 용도 | 상태 |
|------|------|------|
| `v2` | **프로덕션** — SAM3 + 현재 handler | ✅ E2E 성공 |
| `test` | 파이프라인만 검증 (SAM3 없음) | ✅ 동작 |
| `latest` | ❌ 구 handler — **사용 금지** | ❌ |

## Docker 이미지 빌드 (코드 수정 시)

```bash
cd gpu-worker

# 프로덕션 (v2 기반, handler/engine만 교체)
docker build -f Dockerfile.prod -t jonghwan0309/sam3-worker:v2 .
docker push jonghwan0309/sam3-worker:v2

# 테스트 (SAM3 없음, 빠른 빌드)
docker build -f Dockerfile.test -t jonghwan0309/sam3-worker:test .
docker push jonghwan0309/sam3-worker:test

# Docker Hub 로그인 필요 시 (.env에서 DOCKER_HUB_PAT 확인)
echo "<DOCKER_HUB_PAT>" | docker login -u jonghwan0309 --password-stdin
```

## Dockerfile 주의사항

Runpod serverless 공식 패턴:
```dockerfile
WORKDIR /app              # 또는 /
CMD ["python3", "-u", "handler.py"]   # python이 아닌 python3
```

## SAM3 세그멘테이션 결과 (실측)

- **Wall recolor 파란색** → 벽 영역 정확히 인식 + 변환 ✅
- **Floor recolor** → 러그로 덮인 바닥은 인식 안 됨 (노출된 바닥만 인식)
- 개념(concept) 이름이 정확해야 SAM3가 잘 잡음
