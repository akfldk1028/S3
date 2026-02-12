FROM nvidia/cuda:12.6.0-runtime-ubuntu24.04

WORKDIR /app

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.12 python3.12-venv python3-pip \
    libgl1-mesa-glx libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Application code
COPY engine/ engine/
COPY adapters/ adapters/
COPY presets/ presets/
COPY main.py .

# Model weights — 볼륨 마운트 또는 런타임 다운로드
# VOLUME /models
ENV MODEL_CACHE_DIR=/models

CMD ["python3", "main.py"]
