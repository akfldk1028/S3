# JH — GPU Worker 확인사항

> 브랜치: `JH` → DK-A에서 변경된 내용 머지 필요

## 반드시 확인

### 1. 새 파일: engine/generator.py
- Gemini API(Imagen 3.0) inpaint 모듈
- `generate_inpaint(image, mask, prompt, api_key) → Image`
- SAM3 마스크를 `MASK_MODE_USER_PROVIDED`로 Gemini에 전달
- **파일**: `gpu-worker/engine/generator.py`

### 2. pipeline.py 변경 — action 분기
- `action == "recolor"` → 기존 `apply_rules()` (변경 없음)
- `action == "generate"` → `generate_inpaint()` (Gemini API 호출)
- `GEMINI_API_KEY` 환경변수 없으면 warning 후 skip
- **파일**: `gpu-worker/engine/pipeline.py:228-262`

### 3. pipeline.py — 프리셋 프롬프트 매핑 추가됨
- `from presets import get_prompt` — concept 이름 → SAM3 자연어 프롬프트
- `"Floor"` → `"floor surface"`, `"Wall"` → `"wall surface"`
- **파일**: `gpu-worker/presets/__init__.py`

### 4. handler.py — lazy singleton
- SAM3 모델을 첫 요청에서 로드, 이후 재사용
- startup에서 로드하면 Runpod crash → lazy singleton으로 변경됨
- **파일**: `gpu-worker/handler.py`

### 5. Dockerfile.prod 변경
- `google-genai>=1.0.0` pip install 추가
- `presets/` 폴더 COPY 추가
- **파일**: `gpu-worker/Dockerfile.prod`

### 6. Docker 이미지 태그
| 태그 | 용도 |
|------|------|
| `v2` | **프로덕션** — SAM3 + Gemini + 현재 handler |
| `test` | 파이프라인만 검증 (SAM3/Gemini 없음) |
| `latest` | ❌ **사용 금지** — 구 handler |

### 7. 환경변수 추가 필요
- `GEMINI_API_KEY` — Runpod Template에 추가해야 함
- Template ID: `z56tvnfupt`

## Docker 빌드 명령
```bash
cd gpu-worker
docker build -f Dockerfile.prod -t jonghwan0309/sam3-worker:v2 .
docker push jonghwan0309/sam3-worker:v2
```

## 참고 문서
- `docs/ops/gpu-worker.md` — GPU on/off 명령어, 비용 주의
- `docs/ops/cost-warning.md` — Runpod endpoint 삭제 필수!
