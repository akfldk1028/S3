# GPU Worker 작업 기록 (종환)

## 2026-02-23: SAM3 GPU 테스트 완료

### 목표
- Runpod GPU Pod에서 SAM3 모델 테스트
- Docker Serverless 배포 전 환경 검증

---

## 1. Runpod MCP 설정

### API Key
```
(비공개 - 환경변수 RUNPOD_API_KEY 사용)
```

### ~/.claude.json 설정
```json
"runpod": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@runpod/mcp-server"],
  "env": {
    "RUNPOD_API_KEY": "<YOUR_RUNPOD_API_KEY>"
  }
}
```

---

## 2. SSH 설정

### SSH 키 생성
```bash
ssh-keygen -t ed25519 -C "clickaround8@gmail.com"
```

### Public Key
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGLxgiiduzVCrjm74mNwZLrhGOafwzjtUj6JyMVLOugX clickaround8@gmail.com
```

### SSH Config (WSL: ~/.ssh/config)
```
Host runpod-sam3
    HostName <POD_IP>
    Port <SSH_PORT>
    User root
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
```

### SSH Config (Windows: C:\Users\User\.ssh\config)
```
Host runpod-sam3
    HostName <POD_IP>
    Port <SSH_PORT>
    User root
    IdentityFile C:\Users\User\.ssh\id_ed25519
    StrictHostKeyChecking no
```

> **주의**: Pod 재생성하면 IP/Port 바뀜. Config 업데이트 필요.

---

## 3. Pod 정보

| 항목 | 값 |
|------|-----|
| Pod ID | `cjjpo3vq4k7b48` |
| GPU | RTX 4090 (24GB) |
| 비용 | $0.59/hr |
| 상태 | EXITED (Stop) |
| Volume | 50GB (/workspace) |

---

## 4. 환경 설정 (Pod 내부)

### Miniconda 설치
```bash
cd /workspace
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p /workspace/miniconda3
source /workspace/miniconda3/bin/activate
```

### Conda 환경 생성
```bash
conda create -n sam3 python=3.12 -y
conda activate sam3
```

### PyTorch 설치 (CUDA 12.6)
```bash
pip install torch==2.7.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
```

### SAM3 설치
```bash
cd /workspace
git clone https://github.com/facebookresearch/sam3.git
cd sam3
pip install -e .
```

### 추가 종속성 (SAM3 pyproject.toml에 누락됨)
```bash
pip install einops decord opencv-python pycocotools psutil scikit-learn scikit-image matplotlib
pip install 'numpy<2'  # SAM3는 numpy<2 필요
```

---

## 5. 모델 체크포인트

### HuggingFace Token
```
(비공개 - 로컬 보관)
```

### 로컬 → Pod 복사
```bash
# 모델 파일
scp -r -P <SSH_PORT> ~/.cache/huggingface/hub/models--facebook--sam3 root@<POD_IP>:/workspace/models/

# BPE vocab (로컬 sam3/sam3/assets에서)
scp -P <SSH_PORT> /home/cgxr/Project/archisplat/sam3/sam3/assets/bpe_simple_vocab_16e6.txt.gz root@<POD_IP>:/workspace/sam3/sam3/assets/
```

### 모델 경로 (Pod 내부)
```
/workspace/models/snapshots/3c879f39826c281e95690f02c7821c4de09afae7/sam3.pt
```

---

## 6. SAM3 테스트 코드

```python
import torch
from PIL import Image
from sam3 import build_sam3_image_model
from sam3.model.sam3_image_processor import Sam3Processor

# GPU 설정
torch.backends.cuda.matmul.allow_tf32 = True
torch.backends.cudnn.allow_tf32 = True

# 경로
bpe_path = '/workspace/sam3/sam3/assets/bpe_simple_vocab_16e6.txt.gz'
ckpt_path = '/workspace/models/snapshots/3c879f39826c281e95690f02c7821c4de09afae7/sam3.pt'

# 모델 로드
model = build_sam3_image_model(bpe_path=bpe_path, checkpoint_path=ckpt_path)

# 추론
image = Image.open('/workspace/sam3/assets/images/test_image.jpg')
processor = Sam3Processor(model, confidence_threshold=0.5)
state = processor.set_image(image)
state = processor.set_text_prompt(state=state, prompt='shoe')
```

### 테스트 결과
- CUDA: True
- GPU: NVIDIA GeForce RTX 4090
- Model Loaded: ✅
- Inference: ✅

---

## 7. Pod 관리 명령어

### Start
```bash
# Claude에서 MCP로
mcp__runpod__start-pod (podId: cjjpo3vq4k7b48)
```

### Stop
```bash
mcp__runpod__stop-pod (podId: cjjpo3vq4k7b48)
```

### SSH 접속
```bash
ssh runpod-sam3
# 또는
ssh -i ~/.ssh/id_ed25519 root@<POD_IP> -p <SSH_PORT>
```

### conda 환경 활성화 (Pod 내부)
```bash
source /workspace/miniconda3/bin/activate
conda activate sam3
```

---

## 8. 다음 단계

1. [x] Dockerfile 작성 (gpu-worker/)
2. [x] Docker 이미지 빌드 & push
3. [x] Runpod Serverless Endpoint 생성
4. [ ] Workers API와 연동 테스트 (지나/승현 담당)

---

## 2026-02-26: Docker & Runpod Serverless 배포 완료

### 목표
- Docker 이미지 빌드 및 Docker Hub 푸시
- Runpod Serverless Endpoint 생성 및 테스트

### Docker Hub 정보

| 항목 | 값 |
|------|-----|
| Docker Hub ID | `jonghwan0309` |
| Image | `jonghwan0309/sam3-worker:latest` |
| Size | 17.5GB (모델 포함) |

### Docker Hub PAT
```
(비공개 - 로컬 보관)
```

### Runpod Serverless 정보

| 항목 | 값 |
|------|-----|
| Endpoint ID | `ool22vjm24rkma` |
| Endpoint Name | `sam3-segmentation` |
| Template ID | `uy88hn8j8u` |
| GPU | RTX 4090 / A6000 / A5000 |
| Workers | 0~3 (auto-scale) |
| Idle Timeout | 10초 |

### API 테스트 결과
- Delay: ~1초 (cold start)
- Execution: ~0.5초
- Status: COMPLETED ✅

### 주요 트러블슈팅

#### Ubuntu 24.04 패키지 변경
- `libgl1-mesa-glx` → `libgl1`
- `libxrender-dev` → `libxrender1`

#### PEP 668 pip 제한
```dockerfile
ENV PIP_BREAK_SYSTEM_PACKAGES=1
```

#### SAM3 import 에러
- `pip install -e .`가 editable mode로 설치되지만 PYTHONPATH 필요
```dockerfile
ENV PYTHONPATH=/app/sam3:$PYTHONPATH
```

#### Mask shape 처리
- SAM3 출력: `[batch, num_masks, H, W]` (4D tensor)
- segmenter.py에서 4D 처리 로직 추가

### 완료된 작업
- [x] Dockerfile 작성 (모델 포함)
- [x] Docker 이미지 빌드 (17.5GB)
- [x] Docker Hub 푸시
- [x] NVIDIA Container Toolkit 설치 (로컬 테스트용)
- [x] 로컬 GPU 테스트 (RTX 4090)
- [x] Runpod Template 생성
- [x] Runpod Serverless Endpoint 생성
- [x] API 테스트 성공

### 다음 단계 (다른 팀원)
- [ ] Workers API에서 Runpod Endpoint 호출
- [ ] 결과 마스크 R2 저장
- [ ] Supabase 업데이트

---

## 트러블슈팅

### SSH 비밀번호 계속 물어봄
- SSH config에 `IdentityFile` 명시
- Windows/WSL 둘 다 설정 필요

### SAM3 import 에러 (ModuleNotFoundError)
- 추가 종속성 수동 설치 필요 (einops, psutil 등)
- `pip install -e '.[notebooks]'`로 설치하면 대부분 해결

### numpy 버전 충돌
- SAM3: numpy<2 필요
- opencv-python: numpy>=2 필요
- → `pip install 'numpy<2'` 로 SAM3 우선

### HuggingFace 401 에러
- SAM3는 gated model
- `checkpoint_path` 직접 지정하면 HF 다운로드 스킵 가능
