# Gemini Inpaint 통합 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** SAM3 마스크 영역에 Gemini API(Imagen)로 프롬프트 기반 질감/패턴 AI 생성 추가

**Architecture:** GPU Worker에서 action=generate 시 google-genai SDK로 Imagen inpaint 호출. SAM3 마스크를 MASK_MODE_USER_PROVIDED로 전달. 기존 recolor는 유지.

**Tech Stack:** Python google-genai SDK, Imagen 3.0, TypeScript (Workers), Dart/Flutter

**Spec:** `docs/superpowers/specs/2026-03-29-gemini-inpaint-design.md`

---

## File Structure

| 파일 | 역할 | 변경 |
|------|------|------|
| `gpu-worker/engine/generator.py` | Gemini inpaint 모듈 | **CREATE** |
| `gpu-worker/engine/pipeline.py` | action 분기 (recolor/generate) | MODIFY |
| `gpu-worker/requirements.txt` | google-genai 의존성 | MODIFY |
| `gpu-worker/Dockerfile.prod` | requirements 반영 | MODIFY |
| `workers/src/_shared/types.ts` | action 타입 확장 | MODIFY |
| `workers/src/jobs/jobs.validator.ts` | generate action 검증 | MODIFY |
| `workers/src/jobs/jobs.service.ts` | R2 키 패턴 변경 | MODIFY |
| `workers/src/jobs/jobs.route.ts` | R2 키 패턴 적용 | MODIFY |
| `frontend/lib/features/rules/rules_screen.dart` | 프롬프트 입력 UI | MODIFY |

---

### Task 1: generator.py — Gemini Inpaint 모듈

**Files:**
- Create: `gpu-worker/engine/generator.py`
- Modify: `gpu-worker/requirements.txt`

- [ ] **Step 1: requirements.txt에 google-genai 추가**

`gpu-worker/requirements.txt` 끝에 추가:
```
# Gemini API (Imagen inpaint)
google-genai>=1.0.0
```

- [ ] **Step 2: generator.py 작성**

```python
"""
Generator — Gemini API Inpaint

SAM3 마스크 영역에 프롬프트 기반 AI 질감/패턴 생성.
google-genai SDK의 Imagen 3.0 edit_image API 사용.

Usage:
    result = generate_inpaint(image, mask, "화이트 대리석 질감", api_key)
"""

import io
import os
import logging

import numpy as np
from PIL import Image
from google import genai
from google.genai import types

logger = logging.getLogger(__name__)

# Imagen 모델 ID
IMAGEN_MODEL = os.getenv("IMAGEN_MODEL", "imagen-3.0-capability-001")


def _mask_to_image(mask: np.ndarray) -> Image.Image:
    """numpy 마스크(0-1 float or 0-255 uint8)를 PIL Image(L mode)로 변환."""
    if mask.dtype in [np.float32, np.float64]:
        mask_uint8 = (mask * 255).astype(np.uint8)
    elif mask.dtype == bool:
        mask_uint8 = (mask.astype(np.uint8) * 255)
    else:
        mask_uint8 = mask.astype(np.uint8)
    return Image.fromarray(mask_uint8, mode="L")


def _image_to_bytes(image: Image.Image, fmt: str = "PNG") -> bytes:
    """PIL Image를 bytes로 변환."""
    buf = io.BytesIO()
    image.save(buf, format=fmt)
    return buf.getvalue()


def generate_inpaint(
    image: Image.Image,
    mask: np.ndarray,
    prompt: str,
    api_key: str,
) -> Image.Image:
    """
    Gemini API(Imagen)로 마스크 영역 inpaint.

    Args:
        image: 원본 PIL Image (RGB)
        mask: SAM3 마스크 (H x W), 흰색=편집 영역
        prompt: "화이트 대리석 질감" 등 자연어 프롬프트
        api_key: Gemini/Google AI API key

    Returns:
        결과 PIL Image (마스크 영역만 AI 생성, 나머지 원본 유지)
    """
    logger.info(f"[Generator] inpaint prompt='{prompt}' mask_shape={mask.shape}")

    client = genai.Client(api_key=api_key)

    # 원본 이미지 → bytes
    image_rgb = image.convert("RGB")
    image_bytes = _image_to_bytes(image_rgb, "JPEG")

    # SAM3 마스크 → PIL Image → bytes
    mask_image = _mask_to_image(mask)
    # 마스크 크기를 원본과 맞춤
    if mask_image.size != image_rgb.size:
        mask_image = mask_image.resize(image_rgb.size, Image.NEAREST)
    mask_bytes = _image_to_bytes(mask_image, "PNG")

    # Gemini API 호출
    raw_ref = types.RawReferenceImage(
        reference_id=1,
        reference_image=types.Image(
            image_bytes=image_bytes,
            mime_type="image/jpeg",
        ),
    )

    mask_ref = types.MaskReferenceImage(
        reference_id=2,
        reference_image=types.Image(
            image_bytes=mask_bytes,
            mime_type="image/png",
        ),
        config=types.MaskReferenceConfig(
            mask_mode="MASK_MODE_USER_PROVIDED",
            mask_dilation=0.01,
        ),
    )

    response = client.models.edit_image(
        model=IMAGEN_MODEL,
        prompt=prompt,
        reference_images=[raw_ref, mask_ref],
        config=types.EditImageConfig(
            edit_mode="EDIT_MODE_INPAINT_INSERTION",
            number_of_images=1,
        ),
    )

    if not response.generated_images:
        raise RuntimeError(f"Gemini API returned no images for prompt: {prompt}")

    # 결과 추출
    result_bytes = response.generated_images[0].image.image_bytes
    result_image = Image.open(io.BytesIO(result_bytes)).convert("RGB")

    logger.info(f"[Generator] inpaint done — result size={result_image.size}")
    return result_image
```

- [ ] **Step 3: Commit**

```bash
git add gpu-worker/engine/generator.py gpu-worker/requirements.txt
git commit -m "feat: generator.py — Gemini API inpaint 모듈"
```

---

### Task 2: pipeline.py — action 분기 (recolor/generate)

**Files:**
- Modify: `gpu-worker/engine/pipeline.py:200-275` (process_single_item 함수)

- [ ] **Step 1: pipeline.py에 generator import 추가**

`gpu-worker/engine/pipeline.py` 상단 import에 추가:
```python
from .generator import generate_inpaint
```

- [ ] **Step 2: process_single_item에서 action별 분기**

`pipeline.py`의 `process_single_item` 함수 내부, `apply_rules` 호출 부분을 변경:

현재:
```python
result_image = apply_rules(image, all_masks, concepts, protect_mask)
```

변경:
```python
# action별 분기: 모든 concept이 같은 action이면 일괄, 아니면 순차
result_image = image.copy()
gemini_key = os.getenv("GEMINI_API_KEY", "")

# recolor concepts 모으기
recolor_concepts = {k: v for k, v in concepts.items() if v.get("action") == "recolor"}
# generate concepts 모으기
generate_concepts = {k: v for k, v in concepts.items() if v.get("action") == "generate"}

# 1. recolor 일괄 적용 (기존 로직)
if recolor_concepts:
    result_image = apply_rules(result_image, all_masks, recolor_concepts, protect_mask)

# 2. generate 순차 적용 (Gemini API)
if generate_concepts and gemini_key:
    for concept_name, rule in generate_concepts.items():
        if concept_name not in all_masks or not all_masks[concept_name]:
            continue
        # 인스턴스 마스크 합치기
        concept_masks = all_masks[concept_name]
        if isinstance(concept_masks, list) and len(concept_masks) > 0:
            combined = np.maximum.reduce(concept_masks) if len(concept_masks) > 1 else concept_masks[0]
        elif isinstance(concept_masks, np.ndarray):
            combined = concept_masks
        else:
            continue
        # protect 마스크 적용
        if protect_mask is not None:
            combined = combined * (1 - protect_mask.astype(np.float32))
        try:
            result_image = generate_inpaint(
                result_image, combined, rule["value"], gemini_key
            )
        except Exception as e:
            logger.warning(f"Gemini inpaint failed for {concept_name}: {e}")
            # fallback: 해당 concept은 건너뜀
elif generate_concepts and not gemini_key:
    logger.warning("GEMINI_API_KEY not set — skipping generate actions")
```

- [ ] **Step 3: Commit**

```bash
git add gpu-worker/engine/pipeline.py
git commit -m "feat: pipeline action 분기 — recolor + generate(Gemini)"
```

---

### Task 3: Dockerfile.prod — google-genai 의존성 추가

**Files:**
- Modify: `gpu-worker/Dockerfile.prod`

- [ ] **Step 1: Dockerfile.prod에 requirements.txt COPY + install 추가**

현재:
```dockerfile
FROM jonghwan0309/sam3-worker:latest
WORKDIR /app
COPY handler.py /app/handler.py
COPY engine/ /app/engine/
COPY presets/ /app/presets/
CMD ["python3", "-u", "handler.py"]
```

변경:
```dockerfile
FROM jonghwan0309/sam3-worker:latest
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir google-genai>=1.0.0
COPY handler.py /app/handler.py
COPY engine/ /app/engine/
COPY presets/ /app/presets/
CMD ["python3", "-u", "handler.py"]
```

- [ ] **Step 2: Commit**

```bash
git add gpu-worker/Dockerfile.prod
git commit -m "build: Dockerfile.prod에 google-genai 의존성 추가"
```

---

### Task 4: Workers types + validator — generate action 지원

**Files:**
- Modify: `workers/src/_shared/types.ts:85`
- Modify: `workers/src/jobs/jobs.validator.ts`

- [ ] **Step 1: types.ts GpuQueueMessage concepts 타입에 generate 추가**

`workers/src/_shared/types.ts`의 GpuQueueMessage:

현재:
```typescript
concepts: Record<string, { action: string; value: string }>;
```

이미 `string`이라 타입 변경 불필요. 하지만 주석 추가:
```typescript
concepts: Record<string, { action: string; value: string }>; // action: "recolor" | "generate"
```

- [ ] **Step 2: jobs.validator.ts에 generate action 추가**

`workers/src/jobs/jobs.validator.ts`의 ExecuteJobSchema concepts 검증:

현재 (`concepts`가 이미 `z.record(z.object({...}))` 형태인지 확인 후):
```typescript
concepts: z.record(z.object({
  action: z.string(),
  value: z.string(),
})),
```

변경 (action을 enum으로 제한):
```typescript
concepts: z.record(z.object({
  action: z.enum(["recolor", "generate"]),
  value: z.string().min(1),
})),
```

- [ ] **Step 3: Commit**

```bash
git add workers/src/_shared/types.ts workers/src/jobs/jobs.validator.ts
git commit -m "feat: Workers action 타입에 generate 추가"
```

---

### Task 5: Workers R2 키 패턴 변경

**Files:**
- Modify: `workers/src/jobs/jobs.service.ts:8-21`
- Modify: `workers/src/jobs/jobs.route.ts:160-167`

- [ ] **Step 1: jobs.service.ts — R2 키 생성 패턴 변경**

`workers/src/jobs/jobs.service.ts`의 `generateUploadUrls`:

현재:
```typescript
const key = `inputs/${userId}/${jobId}/${idx}.jpg`;
```

변경:
```typescript
const timestamp = new Date().toISOString().replace(/[-:T]/g, '').slice(0, 15); // 20260329_143000
const key = `${userId}/${preset}/${timestamp}/originals/${idx}.jpg`;
```

함수 시그니처에 `preset` 파라미터 추가:
```typescript
export async function generateUploadUrls(
  env: Env,
  userId: string,
  jobId: string,
  itemCount: number,
  preset: string,  // 추가
): Promise<Array<{ idx: number; url: string; key: string }>> {
```

- [ ] **Step 2: jobs.route.ts — execute에서 R2 키 패턴 변경**

`workers/src/jobs/jobs.route.ts`의 execute 핸들러 (line ~160-167):

현재:
```typescript
items.push({
  idx,
  input_key: `inputs/${user.userId}/${jobId}/${idx}.jpg`,
  output_key: `outputs/${user.userId}/${jobId}/${idx}_result.png`,
  preview_key: `previews/${user.userId}/${jobId}/${idx}_thumb.jpg`,
});
```

변경:
```typescript
const baseKey = `${user.userId}/${status.state.preset}/${jobId}`;
items.push({
  idx,
  input_key: `${baseKey}/originals/${idx}.jpg`,
  output_key: `${baseKey}/results/${idx}_result.png`,
  preview_key: `${baseKey}/previews/${idx}_thumb.jpg`,
});
```

> Note: timestamp 대신 jobId를 세션 키로 사용 (유일성 보장 + 기존 로직 호환).

- [ ] **Step 3: jobs.route.ts — createJob에서 preset 전달**

`generateUploadUrls` 호출부에 preset 추가:
```typescript
const presignedUrls = await generateUploadUrls(c.env, user.userId, jobId, item_count, preset);
```

- [ ] **Step 4: Workers 배포 + 테스트**

```bash
cd workers
npx tsc --noEmit
npx wrangler deploy
curl -s https://s3-workers.clickaround8.workers.dev/health
```

- [ ] **Step 5: Commit**

```bash
git add workers/src/jobs/jobs.service.ts workers/src/jobs/jobs.route.ts
git commit -m "feat: R2 키 패턴 변경 — userId/preset/jobId/originals|results|previews"
```

---

### Task 6: Flutter — 프롬프트 입력 UI

**Files:**
- Modify: `frontend/lib/features/rules/rules_screen.dart`

- [ ] **Step 1: rules_screen.dart에 generate action + 프롬프트 입력 추가**

executeJob 호출 시 concepts 데이터에 action: "generate" + value: 프롬프트 텍스트 전달.

기존 recolor UI 옆에 "AI 생성" 토글 + 텍스트 입력 필드 추가:
```dart
// concept 선택 후 action 선택
SegmentedButton<String>(
  segments: const [
    ButtonSegment(value: 'recolor', label: Text('색상')),
    ButtonSegment(value: 'generate', label: Text('AI 생성')),
  ],
  selected: {_selectedAction},
  onSelectionChanged: (s) => setState(() => _selectedAction = s.first),
),

// action=generate일 때 프롬프트 입력
if (_selectedAction == 'generate')
  TextField(
    controller: _promptController,
    decoration: InputDecoration(
      hintText: '원하는 질감을 설명하세요 (예: 화이트 대리석)',
      border: OutlineInputBorder(),
    ),
  ),

// 추천 프롬프트 칩
if (_selectedAction == 'generate')
  Wrap(
    spacing: 8,
    children: ['화이트 대리석', '원목 헤링본', '콘크리트', '벽돌 패턴']
        .map((p) => ActionChip(
              label: Text(p),
              onPressed: () => _promptController.text = p,
            ))
        .toList(),
  ),
```

- [ ] **Step 2: executeJob 호출 시 action 포함**

```dart
await apiClient.executeJob(
  jobId,
  concepts: {
    selectedConcept: {
      'action': _selectedAction,  // "recolor" or "generate"
      'value': _selectedAction == 'recolor'
          ? _selectedColor   // "#FF5733"
          : _promptController.text,  // "화이트 대리석"
    },
  },
  protect: selectedProtect,
);
```

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/rules/rules_screen.dart
git commit -m "feat: Flutter rules UI — AI 생성 프롬프트 입력 추가"
```

---

### Task 7: Docker 빌드 + E2E 테스트

**Files:**
- No new files

- [ ] **Step 1: Docker 빌드 + push**

```bash
cd gpu-worker
docker build -f Dockerfile.prod -t jonghwan0309/sam3-worker:v2 .
docker push jonghwan0309/sam3-worker:v2
```

- [ ] **Step 2: Runpod template에 GEMINI_API_KEY 추가**

```
MCP: mcp__runpod__update-template
  templateId: "z56tvnfupt"
  env: { ...기존 env, "GEMINI_API_KEY": "<.env에서 가져옴>" }
```

- [ ] **Step 3: Runpod endpoint 생성**

```
MCP: mcp__runpod__create-endpoint
  name: "s3-gemini-test"
  templateId: "z56tvnfupt"
  dataCenterIds: ["EU-CZ-1"]
  gpuTypeIds: ["NVIDIA GeForce RTX 3090", ...]
  workersMin: 0, workersMax: 1
```

- [ ] **Step 4: Workers 업데이트**

```bash
cd workers
echo "<endpoint_id>" | npx wrangler secret put RUNPOD_ENDPOINT_ID
echo "<gemini_key>" | npx wrangler secret put GEMINI_API_KEY
npx wrangler deploy
```

- [ ] **Step 5: E2E 테스트**

```bash
# Auth + Job + Upload + Execute(generate) + Poll
curl -X POST .../jobs/{id}/execute \
  -d '{"concepts":{"Wall":{"action":"generate","value":"화이트 대리석 질감"}},"protect":[]}'
```

Expected: status=done, 결과 이미지에서 Wall 영역이 대리석 질감으로 변환.

- [ ] **Step 6: Endpoint 삭제 (비용!)**

```
MCP: mcp__runpod__delete-endpoint
MCP: mcp__runpod__list-endpoints → [] 확인
```

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: Gemini inpaint E2E 완료"
git push origin DK-A
```

---

## Sources

- [Google GenAI Python SDK](https://github.com/googleapis/python-genai)
- [Imagen Inpaint Insert Objects](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/image/edit-insert-objects)
- [Imagen Edit API Reference](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/model-reference/imagen-api-edit)
- [Firebase AI Logic - Edit Images](https://firebase.google.com/docs/ai-logic/edit-images-imagen-overview)
