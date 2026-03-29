# Gemini Inpaint 통합 설계

## 목표

SAM3 세그멘테이션 마스크 영역에 Gemini API(나노바나나2)로 프롬프트 기반 질감/패턴 생성.
단순 recolor → AI 생성으로 제품 가치 대폭 상승.

## 아키텍처

기존 파이프라인 유지. GPU Worker에서 Gemini API 호출 추가.

```
Flutter → Workers → Queue → GPU Worker
                              ├── SAM3 segment (마스크 생성)
                              ├── action=recolor → applier.py (기존, 유지)
                              ├── action=generate → generator.py (NEW, Gemini API)
                              ├── R2 업로드
                              └── Workers callback
```

## Rule Action 확장

```json
// 기존 (유지)
{"Floor": {"action": "recolor", "value": "#FF5733"}}

// 신규
{"Floor": {"action": "generate", "value": "원목 헤링본 바닥"}}
{"Wall":  {"action": "generate", "value": "화이트 대리석 질감"}}
```

- `recolor`: 기존 색상 덮기 (빠름, API 호출 없음)
- `generate`: Gemini API inpaint (프롬프트 기반 AI 생성)

## GPU Worker 모듈 구조

```
gpu-worker/
├── engine/
│   ├── pipeline.py        # 오케스트레이터 — action별 분기
│   ├── segmenter.py       # SAM3 (유지)
│   ├── applier.py         # recolor (유지)
│   ├── generator.py       # NEW — Gemini API inpaint
│   ├── r2_io.py           # R2 (유지)
│   └── callback.py        # callback (유지)
├── presets/                # 프롬프트 매핑 (유지)
├── handler.py             # Runpod handler (유지)
└── Dockerfile.prod        # 프로덕션 빌드
```

### generator.py

```python
import google.generativeai as genai

def generate_inpaint(image: Image, mask: np.ndarray, prompt: str, api_key: str) -> Image:
    """
    Gemini API로 마스크 영역 inpaint.

    Args:
        image: 원본 PIL Image
        mask: SAM3 마스크 (H x W, 0-1)
        prompt: "화이트 대리석 질감" 등
        api_key: Gemini API key

    Returns:
        결과 PIL Image (마스크 영역만 AI 생성, 나머지 원본 유지)
    """
```

### pipeline.py 변경

```python
from .generator import generate_inpaint

# concept별 action 분기
for concept_name, rule in concepts.items():
    action = rule.get("action")
    if action == "recolor":
        result_image = apply_rules(image, {concept_name: all_masks[concept_name]},
                                   {concept_name: rule}, protect_mask)
    elif action == "generate":
        concept_mask = combine_masks(all_masks[concept_name])
        if protect_mask is not None:
            concept_mask = concept_mask * (1 - protect_mask)
        result_image = generate_inpaint(image, concept_mask, rule["value"], gemini_key)
```

## R2 폴더구조 (v2)

```
s3-images/
  {userId}/
    {preset}/                          # interior, seller
      {YYYYMMDD_HHmmss}/              # 작업 세션
        originals/
          0.jpg, 1.jpg, ...
        masks/
          0_Wall.png, 0_Floor.png, ...
        results/
          0_result.png, ...
        previews/
          0_thumb.jpg, ...
```

### 키 생성 (Workers jobs.service.ts)

```typescript
const timestamp = new Date().toISOString().replace(/[-:T]/g, '').slice(0, 15); // 20260329_143000
const baseKey = `${userId}/${preset}/${timestamp}`;

// presigned URL 키
`${baseKey}/originals/${idx}.jpg`
`${baseKey}/results/${idx}_result.png`
`${baseKey}/previews/${idx}_thumb.jpg`
`${baseKey}/masks/${idx}_${concept}.png`
```

## Workers 변경

### types.ts — ConceptAction 타입

```typescript
// action에 "generate" 추가
export type GpuQueueMessage = {
  ...
  concepts: Record<string, { action: "recolor" | "generate"; value: string }>;
  ...
};
```

### jobs.validator.ts — 검증

```typescript
concepts: z.record(z.object({
  action: z.enum(["recolor", "generate"]),
  value: z.string().min(1),
}))
```

### 환경변수

- Workers secret: `GEMINI_API_KEY`
- GPU Worker env: `GEMINI_API_KEY` (Runpod template에 추가)

## Flutter 변경

### rules_screen.dart — 프롬프트 입력 UI

concept 선택 후:
- **색상 변경 (recolor)**: 기존 컬러 피커
- **AI 생성 (generate)**: 텍스트 입력 필드 + 추천 프롬프트 칩

```dart
// 추천 프롬프트 (도메인별)
interior: ["화이트 대리석", "원목 헤링본", "콘크리트 질감", "벽돌 패턴"]
seller: ["무광 화이트", "그라데이션 배경", "스튜디오 조명"]
```

### 다중 이미지 배치

기존 `item_count` 로직 유지 — N장 업로드 → 같은 룰 일괄 적용.
갤러리에서 여러 장 선택 → 한 번에 업로드 → 동일 룰 적용.

## 크레딧

- recolor 1장 = 1크레딧
- generate 1장 = 1크레딧 (동일)
- Gemini API 비용은 서비스가 흡수

## 구현 순서

1. `generator.py` — Gemini API inpaint 모듈
2. `pipeline.py` — action 분기 추가
3. R2 키 패턴 변경 (Workers + GPU)
4. Workers types/validator 업데이트
5. Runpod template에 GEMINI_API_KEY 추가
6. Flutter rules UI — 프롬프트 입력 추가
7. Docker 빌드 + E2E 테스트
