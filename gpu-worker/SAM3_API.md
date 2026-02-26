# SAM3 Segmentation API 사용법

> **담당**: 종환 (SAM)
> **최종 업데이트**: 2026-02-26
> **상태**: Production Ready

---

## Overview

SAM3 (Segment Anything Model 3)를 사용한 텍스트 기반 이미지 세그멘테이션 API.
이미지 URL과 개념(concept) 텍스트를 입력하면 해당 개념의 마스크를 반환.

---

## Endpoint 정보

| 항목 | 값 |
|------|-----|
| Base URL | `https://api.runpod.ai/v2/ool22vjm24rkma` |
| Sync Endpoint | `/runsync` (결과 대기) |
| Async Endpoint | `/run` (비동기) |
| Status Endpoint | `/status/{job_id}` |

---

## 인증

```
Authorization: Bearer <RUNPOD_API_KEY>
```

---

## Request Format

### POST /runsync

```json
{
  "input": {
    "image_url": "https://example.com/image.jpg",
    "concepts": ["wall", "door", "window"],
    "confidence_threshold": 0.3
  }
}
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `image_url` | string | Yes | - | 세그멘테이션할 이미지 URL |
| `concepts` | string[] | Yes | - | 찾을 개념 리스트 (예: ["wall", "door"]) |
| `confidence_threshold` | float | No | 0.5 | 최소 신뢰도 (0.0~1.0, 낮을수록 더 많은 마스크) |

---

## Response Format

### 성공 응답

```json
{
  "delayTime": 1120,
  "executionTime": 543,
  "id": "sync-xxxxx",
  "output": {
    "output": {
      "image_size": [800, 533],
      "results": {
        "wall": {
          "instance_count": 7,
          "masks_base64": ["iVBORw0KGgo...", "..."],
          "scores": [0.77, 0.48, ...]
        },
        "door": {
          "instance_count": 0,
          "masks_base64": [],
          "scores": []
        }
      }
    }
  },
  "status": "COMPLETED"
}
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `delayTime` | int | Cold start 대기 시간 (ms) |
| `executionTime` | int | 실제 실행 시간 (ms) |
| `status` | string | `COMPLETED`, `FAILED`, `IN_PROGRESS` |
| `output.output.image_size` | [int, int] | 원본 이미지 크기 [width, height] |
| `output.output.results` | object | 개념별 결과 |
| `results[concept].instance_count` | int | 발견된 인스턴스 개수 |
| `results[concept].masks_base64` | string[] | Base64 인코딩된 PNG 마스크들 |
| `results[concept].scores` | float[] | 각 마스크의 신뢰도 점수 |

### 에러 응답

```json
{
  "output": {
    "error": "Failed to download image: ..."
  },
  "status": "COMPLETED"
}
```

---

## 사용 예시

### cURL

```bash
curl -X POST "https://api.runpod.ai/v2/ool22vjm24rkma/runsync" \
  -H "Authorization: Bearer <RUNPOD_API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "image_url": "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800",
      "concepts": ["wall", "door"],
      "confidence_threshold": 0.3
    }
  }'
```

### JavaScript (Workers API)

```javascript
const RUNPOD_API_KEY = "<RUNPOD_API_KEY>";
const ENDPOINT_ID = "ool22vjm24rkma";

async function segmentImage(imageUrl, concepts, confidenceThreshold = 0.3) {
  const response = await fetch(
    `https://api.runpod.ai/v2/${ENDPOINT_ID}/runsync`,
    {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RUNPOD_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        input: {
          image_url: imageUrl,
          concepts: concepts,
          confidence_threshold: confidenceThreshold,
        },
      }),
    }
  );

  const result = await response.json();

  if (result.status === "COMPLETED" && result.output?.output) {
    return result.output.output;
  } else if (result.output?.error) {
    throw new Error(result.output.error);
  }

  throw new Error("Unexpected response");
}

// 사용 예시
const result = await segmentImage(
  "https://example.com/room.jpg",
  ["wall", "floor", "ceiling"],
  0.3
);

console.log(result.results.wall.instance_count); // 벽 개수
console.log(result.results.wall.masks_base64[0]); // 첫 번째 벽 마스크 (Base64 PNG)
```

### Python

```python
import requests
import base64
from PIL import Image
from io import BytesIO

RUNPOD_API_KEY = "<RUNPOD_API_KEY>"
ENDPOINT_ID = "ool22vjm24rkma"

def segment_image(image_url, concepts, confidence_threshold=0.3):
    response = requests.post(
        f"https://api.runpod.ai/v2/{ENDPOINT_ID}/runsync",
        headers={
            "Authorization": f"Bearer {RUNPOD_API_KEY}",
            "Content-Type": "application/json",
        },
        json={
            "input": {
                "image_url": image_url,
                "concepts": concepts,
                "confidence_threshold": confidence_threshold,
            }
        }
    )

    result = response.json()
    return result["output"]["output"]

# Base64 마스크를 이미지로 변환
def decode_mask(base64_str):
    img_data = base64.b64decode(base64_str)
    return Image.open(BytesIO(img_data))

# 사용 예시
result = segment_image(
    "https://example.com/room.jpg",
    ["wall", "door"],
    0.3
)

for concept, data in result["results"].items():
    print(f"{concept}: {data['instance_count']} masks")
    for i, mask_b64 in enumerate(data["masks_base64"]):
        mask_img = decode_mask(mask_b64)
        mask_img.save(f"{concept}_{i}.png")
```

---

## 마스크 데이터 처리

### Base64 → PNG 디코딩

마스크는 **Grayscale PNG** (L mode)로 인코딩되어 있음.
- 0 (검정): 배경
- 255 (흰색): 해당 개념 영역

### R2 저장 예시 (Workers)

```javascript
// Base64 마스크를 R2에 저장
async function saveMaskToR2(env, maskBase64, key) {
  const maskBuffer = Uint8Array.from(atob(maskBase64), c => c.charCodeAt(0));

  await env.R2_BUCKET.put(key, maskBuffer, {
    httpMetadata: {
      contentType: "image/png",
    },
  });

  return `https://your-r2-domain.com/${key}`;
}
```

---

## 성능 참고

| 항목 | 값 |
|------|-----|
| Cold Start | ~1-2초 (첫 요청) |
| Warm Execution | ~0.5초/이미지 |
| GPU | RTX 4090 / A6000 / A5000 |
| Max Workers | 3 (auto-scale) |
| Idle Timeout | 10초 |

---

## 주의사항

1. **이미지 URL 접근성**: 이미지 URL은 public이어야 함 (인증 필요 URL 불가)
2. **이미지 크기**: 큰 이미지는 자동 리사이즈됨
3. **confidence_threshold**:
   - 높으면 (0.7+): 확실한 것만 반환
   - 낮으면 (0.3): 더 많은 후보 반환
4. **Cold Start**: 첫 요청이나 10초 이상 유휴 후 요청은 느림

---

## 에러 처리

| 에러 메시지 | 원인 | 해결 |
|------------|------|------|
| `Failed to download image` | 이미지 URL 접근 불가 | public URL 확인 |
| `Model file not found` | 모델 로딩 실패 | 재시도 또는 관리자 문의 |
| `Segmentation failed` | 추론 실패 | 이미지 형식 확인 |

---

## 관련 파일

- `gpu-worker/handler.py` - Runpod 핸들러
- `gpu-worker/engine/segmenter.py` - SAM3 래퍼
- `gpu-worker/Dockerfile` - Docker 이미지 설정
- `gpu-worker/jh.md` - 작업 기록

---

## 담당자

- **GPU Worker**: 종환 (@jonghwan0309)
- **Workers API 연동**: 지나, 승현
