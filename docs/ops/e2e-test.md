# E2E 테스트 방법

## 사전 조건
- GPU endpoint가 켜져 있어야 함 → `docs/ops/gpu-worker.md` 참조
- Workers가 최신 배포되어 있어야 함

## 전체 파이프라인 테스트 (curl)

```bash
BASE="https://s3-workers.clickaround8.workers.dev"

# 1. Auth
AUTH=$(curl -s -X POST "$BASE/auth/anon" -H "Content-Type: application/json")
TOKEN=$(echo "$AUTH" | python -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")
echo "Token: $TOKEN"

# 2. Job 생성
JOB=$(curl -s -X POST "$BASE/jobs" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"preset":"interior","item_count":1}')
JOB_ID=$(echo "$JOB" | python -c "import sys,json; print(json.load(sys.stdin)['data']['job_id'])")
PRESIGNED=$(echo "$JOB" | python -c "import sys,json; print(json.load(sys.stdin)['data']['presigned_urls'][0]['url'])")
echo "Job: $JOB_ID"

# 3. 이미지 업로드 (아무 jpg 파일)
curl -s -o /dev/null -w "Upload: %{http_code}\n" -X PUT "$PRESIGNED" \
  -H "Content-Type: image/jpeg" --data-binary @test_image.jpg

# 4. Confirm + Execute
curl -s -X POST "$BASE/jobs/$JOB_ID/confirm-upload" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json"
curl -s -X POST "$BASE/jobs/$JOB_ID/execute" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"concepts":{"Floor":{"action":"recolor","value":"#FF5733"}},"protect":[]}'

# 5. 결과 polling (5초 간격)
for i in $(seq 1 30); do
  sleep 5
  STATUS=$(curl -s "$BASE/jobs/$JOB_ID" -H "Authorization: Bearer $TOKEN")
  ST=$(echo "$STATUS" | python -c "import sys,json; print(json.load(sys.stdin)['data']['job']['status'])")
  echo "[$i] status=$ST"
  if [ "$ST" = "done" ] || [ "$ST" = "failed" ]; then
    echo "$STATUS" | python -m json.tool
    break
  fi
done
```

## 기대 결과

```json
{
  "status": "done",
  "done_items": 1,
  "failed_items": 0,
  "download_urls": [
    { "idx": 0, "output_url": "...", "preview_url": "..." }
  ]
}
```

## GPU 없이 테스트 (Workers만)

```bash
# Health check
curl -s https://s3-workers.clickaround8.workers.dev/health

# Auth
curl -s -X POST https://s3-workers.clickaround8.workers.dev/auth/anon \
  -H "Content-Type: application/json" | python -m json.tool

# Presets
curl -s https://s3-workers.clickaround8.workers.dev/presets \
  -H "Authorization: Bearer <TOKEN>" | python -m json.tool
```

이 테스트는 GPU 없이도 동작함. Job execute까지는 가능하지만 GPU 처리는 안 됨.