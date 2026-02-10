# S3 AI — SAM3 Model Scripts & Notebooks

> SAM3(Segment Anything Model 3) 관련 실험, 벤치마크, 유틸리티 스크립트.

---

## Overview

- **Model**: SAM3 (Segment Anything Model 3, Meta AI 2025.11)
- **Framework**: PyTorch 2.7+
- **용도**: 모델 가중치 관리, 실험, 벤치마크 (추론 서버는 `backend/` 담당)

---

## SAM3 Model Spec

| Property | Value |
|----------|-------|
| **Parameters** | 848M |
| **Weights Size** | 3.4 GB |
| **Inference** | ~30ms/image (H200) |
| **Input** | Image (RGB) + Text prompt (str) |
| **Output** | Segmentation mask (binary) + Labels (list[str]) |
| **Precision** | FP16 / BF16 |
| **Min VRAM** | 16 GB (RTX 4090) |
| **Recommended** | 24+ GB (A100/H100) |

### 지원 프롬프트 유형

| Type | Example | Description |
|------|---------|-------------|
| 단일 객체 | `"person"` | 하나의 객체 세그멘테이션 |
| 복합 프롬프트 | `"person wearing a red shirt"` | 속성이 포함된 객체 |
| 배경 분리 | `"background"` | 배경/전경 분리 |
| 신체 부위 | `"left hand"` | 세밀한 부위 세그멘테이션 |

---

## File Map

```
ai/
├── scripts/
│   ├── download_weights.py            🔲 HuggingFace 가중치 다운로드 (stub)
│   └── convert_model.py               🔲 모델 변환 FP16/ONNX/TRT (stub)
├── prompts/
│   └── default_prompts.json           ✅ 카테고리별 프롬프트 예시
├── notebooks/.gitkeep                 ✅ (실험 노트북용)
├── weights/.gitkeep                   ✅ (gitignore 대상)
└── README.md                          ← 이 파일
```

**범례:** ✅ = 구현 완료 | 🔲 = stub (TODO)

---

## Agent 작업 가이드

> 이 레이어를 개발할 에이전트를 위한 **단계별 지침**.

### Step 1: 가중치 다운로드 스크립트 (`scripts/download_weights.py`)

**목표:** `huggingface_hub`로 SAM3 가중치 다운로드

- `pip install huggingface_hub` 필요
- `HF_TOKEN` 환경변수로 인증
- 다운로드 경로: `../backend/weights/sam3.pt` (또는 `./weights/`)
- progress bar 표시
- **검증:** `python scripts/download_weights.py --output ../backend/weights/` → 가중치 파일 생성

### Step 2: 모델 변환 스크립트 (`scripts/convert_model.py`)

**목표:** FP32 → FP16, ONNX, TensorRT 변환

- `--format fp16` — PyTorch FP16 변환
- `--format onnx` — ONNX export
- `--format tensorrt` — TensorRT 엔진 빌드
- **검증:** `python scripts/convert_model.py --input weights/sam3.pt --format fp16`

### Step 3: 추론 테스트 노트북 (`notebooks/sam3_test.ipynb`)

**목표:** SAM3 모델 로드 + 단일 이미지 추론 + 마스크 시각화

- 이미지 로드 → 모델 추론 → 마스크 오버레이 표시
- 다양한 프롬프트로 테스트
- `prompts/default_prompts.json` 활용

### Step 4: 벤치마크 노트북 (`notebooks/benchmark.ipynb`)

**목표:** 추론 속도, 메모리 사용량, 배치 크기별 성능 측정

- 단일 이미지 latency
- 배치 크기 1/4/8/16 비교
- GPU VRAM 사용량 모니터링
- FP16 vs FP32 비교

---

## 의존하는 계약

| 대상 | 설명 | 파일 |
|------|------|------|
| Backend ← AI | Backend의 `src/sam3/predictor.py`가 이 스크립트로 다운로드한 가중치 사용 | `backend/src/sam3/` |
| Backend ← AI | `default_prompts.json`을 테스트/데모에 활용 | `ai/prompts/` |

---

## Setup

```bash
# 가상환경 (backend와 공유 가능)
python -m venv .venv && source .venv/bin/activate

# 의존성
pip install huggingface_hub torch torchvision jupyter

# 환경변수
export HF_TOKEN=your_huggingface_token

# 가중치 다운로드
python scripts/download_weights.py --output ../backend/weights/

# 노트북 실행
jupyter notebook notebooks/
```
