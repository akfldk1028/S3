# SAM3 GPU Worker for Runpod Serverless
FROM nvidia/cuda:12.6.0-devel-ubuntu24.04

WORKDIR /app

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
# Allow pip to install system-wide (PEP 668)
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# System dependencies (Ubuntu 24.04 has Python 3.12 by default)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    python3-dev \
    python3-pip \
    git \
    wget \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    && rm -rf /var/lib/apt/lists/*

# Symlink python -> python3
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Install PyTorch with CUDA 12.6 support
RUN pip install --no-cache-dir \
    torch==2.7.0 \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu126

# Clone and install SAM3
RUN git clone https://github.com/facebookresearch/sam3.git /app/sam3 \
    && cd /app/sam3 \
    && pip install --no-cache-dir -e .

# Install additional SAM3 dependencies (not in pyproject.toml)
RUN pip install --no-cache-dir \
    einops \
    decord \
    opencv-python \
    pycocotools \
    psutil \
    scikit-learn \
    scikit-image \
    matplotlib \
    'numpy<2'

# Install application dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY engine/ engine/
COPY adapters/ adapters/
COPY presets/ presets/
COPY main.py .
COPY handler.py .

# Copy model weights (included in image)
COPY models/sam3.pt /models/sam3.pt

# Environment variables
ENV PYTHONPATH=/app/sam3:$PYTHONPATH
ENV MODEL_CACHE_DIR=/models
ENV MODEL_CHECKPOINT=/models/sam3.pt
ENV SAM3_ROOT=/app/sam3
ENV BPE_PATH=/app/sam3/sam3/assets/bpe_simple_vocab_16e6.txt.gz

# Runpod serverless handler
CMD ["python", "-u", "handler.py"]
