# S3 GPU Worker — SAM3 Segmenter + Rule Applier

> ML processing engine for concept-based instance segmentation and rule application using SAM3 (848M parameters)

---

## Overview

The GPU Worker is a serverless ML service that performs two-stage image processing for S3's domain palette engine:

1. **Stage 1 - Segmentation**: Generate per-concept instance masks using SAM3 (Segment Anything Model 3)
2. **Stage 2 - Rule Application**: Apply recolor/tone/texture/remove rules to masked regions

This worker runs on Runpod Serverless infrastructure, integrates with Cloudflare R2 for storage, and sends per-item status callbacks to the Workers API.

---

## Architecture

### Two-Stage Pipeline

The worker implements a strict two-stage pipeline to enable mask reusability and optimize performance:

```
Job Input
    ↓
┌─────────────────────────────────────────────────┐
│ Stage 1: Segmentation (runs ONCE per job)      │
│  • Download input images from R2                │
│  • Segment ALL concepts using SAM3              │
│  • Generate per-concept instance masks          │
│  • Cache masks for reuse                        │
└─────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────┐
│ Stage 2: Rule Application (runs PER-RULE)      │
│  • Apply rules using cached masks               │
│  • Generate output images                       │
│  • Upload outputs + masks + previews to R2      │
│  • Callback to Workers API per item             │
└─────────────────────────────────────────────────┘
    ↓
Job Complete (all items processed)
```

### Key Components

| Component | File | Purpose |
|-----------|------|---------|
| **Segmenter** | `engine/segmenter.py` | SAM3 model wrapper for concept-based segmentation |
| **Applier** | `engine/applier.py` | Rule application engine (recolor/tone/texture/remove) |
| **R2 I/O** | `engine/r2_io.py` | Boto3-based R2 storage layer (S3-compatible) |
| **Callback** | `engine/callback.py` | Workers API notification with idempotency |
| **Pipeline** | `engine/pipeline.py` | Two-stage orchestrator |
| **Runpod Adapter** | `adapters/runpod_serverless.py` | Runpod serverless handler |
| **Presets** | `presets/` | Domain concept mappings (interior, seller) |

---

## Setup

### Prerequisites

1. **NVIDIA GPU** with CUDA 12.1+ drivers (for local development/testing)
2. **HuggingFace Account** with SAM3 access approval
   - Visit https://huggingface.co/facebook/sam3
   - Request access (approval required from Meta AI)
   - Generate token at https://huggingface.co/settings/tokens
3. **Cloudflare R2** credentials (account ID, access key, secret key)
4. **Workers API** endpoint and shared callback secret

### Installation

```bash
# 1. Navigate to gpu-worker directory
cd gpu-worker

# 2. Install Python dependencies
pip install -r requirements.txt

# 3. Create environment file from template
cp .env.example .env

# 4. Edit .env with your credentials
# - HF_TOKEN: Your HuggingFace token (REQUIRED)
# - R2_ACCOUNT_ID: Your Cloudflare R2 account ID
# - R2_ACCESS_KEY_ID: R2 access key ID
# - R2_SECRET_ACCESS_KEY: R2 secret access key
# - R2_BUCKET_NAME: R2 bucket name (e.g., s3-storage)
# - WORKERS_API_URL: Workers API base URL
# - GPU_CALLBACK_SECRET: Shared secret for callback auth
nano .env
```

### Local Testing (Requires GPU)

```bash
# Run directly with Python
python main.py

# Or use Docker with GPU access
docker build -t s3-gpu-worker:latest .
docker run --gpus all --env-file .env s3-gpu-worker:latest
```

### Model Caching

The SAM3 model weights (3.4 GB) are downloaded on first run and cached at `/models` by default. To persist the cache across container restarts:

```bash
# Create local model cache directory
mkdir -p ./models

# Run with volume mount
docker run --gpus all \
  --env-file .env \
  -v $(pwd)/models:/models \
  s3-gpu-worker:latest
```

---

## Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `HF_TOKEN` | HuggingFace token for SAM3 access (GATED model) | `hf_aBcDeFg...` |
| `R2_ACCOUNT_ID` | Cloudflare R2 account ID (used to construct endpoint URL) | `abc123...` |
| `R2_ACCESS_KEY_ID` | R2 access key ID | `AKIA...` |
| `R2_SECRET_ACCESS_KEY` | R2 secret access key | `wJalr...` |
| `R2_BUCKET_NAME` | R2 bucket name | `s3-storage` |
| `WORKERS_API_URL` | Workers API base URL for callbacks | `https://api.s3app.workers.dev` |
| `GPU_CALLBACK_SECRET` | Shared secret for Workers callback authentication | `supersecret123` |

### Optional Variables (with defaults)

| Variable | Description | Default |
|----------|-------------|---------|
| `MODEL_CACHE_DIR` | Model weights cache directory | `/models` |
| `BATCH_CONCURRENCY` | Max concurrent image processing | `4` |
| `CALLBACK_TIMEOUT_SEC` | HTTP timeout for callback requests | `30` |
| `ADAPTER` | Adapter type (`runpod` or `queue_pull`) | `runpod` |
| `LOG_LEVEL` | Logging level (`DEBUG`, `INFO`, `WARNING`, `ERROR`) | `INFO` |

**⚠️ CRITICAL:** SAM3 is a **GATED model**. You must:
1. Request access at https://huggingface.co/facebook/sam3
2. Wait for approval from Meta AI (usually 1-2 business days)
3. Use a valid HuggingFace token with read access

Without access approval, the model download will fail with a 403 error.

---

## Docker Deployment

### Build Image

```bash
cd gpu-worker
docker build -t s3-gpu-worker:latest .
```

**Expected image size:** ~8 GB (includes PyTorch + CUDA 12.6 runtime)

### Run Container

```bash
# Basic run with GPU access
docker run --gpus all --env-file .env s3-gpu-worker:latest

# With model cache persistence
docker run --gpus all \
  --env-file .env \
  -v $(pwd)/models:/models \
  s3-gpu-worker:latest

# With custom log level
docker run --gpus all \
  --env-file .env \
  -e LOG_LEVEL=DEBUG \
  s3-gpu-worker:latest
```

**Important flags:**
- `--gpus all`: Required for GPU access (uses nvidia-docker runtime)
- `--env-file .env`: Loads environment variables from .env file
- `-v $(pwd)/models:/models`: Mounts local model cache directory

### Verify GPU Access

```bash
# Run inside container to verify GPU is accessible
docker run --gpus all --rm nvidia/cuda:12.6.0-runtime-ubuntu24.04 nvidia-smi
```

Expected output: GPU device info, CUDA version 12.1+

---

## Runpod Deployment

### Prerequisites

1. Runpod account with GPU credits
2. Docker image pushed to container registry (Docker Hub, GCR, ECR)

### Deploy to Runpod Serverless

```bash
# 1. Build and tag image
docker build -t your-registry/s3-gpu-worker:v1.0 .
docker push your-registry/s3-gpu-worker:v1.0

# 2. Deploy via Runpod CLI (if installed)
runpod deploy \
  --image your-registry/s3-gpu-worker:v1.0 \
  --gpu "NVIDIA RTX A4000" \
  --env HF_TOKEN=$HF_TOKEN \
  --env R2_ACCOUNT_ID=$R2_ACCOUNT_ID \
  # ... (add all required env vars)

# 3. Or deploy via Runpod Web UI
# - Go to https://runpod.io/console/serverless
# - Create new endpoint
# - Configure image, GPU type, environment variables
# - Set container disk size to 20GB+ (for model cache)
```

### Recommended GPU Types

| GPU | VRAM | Performance | Cost |
|-----|------|-------------|------|
| RTX A4000 | 16 GB | Good for dev/testing | Low |
| RTX A5000 | 24 GB | Production (1-2 concurrent jobs) | Medium |
| A100 | 40 GB | High performance (3-4 concurrent jobs) | High |

**Minimum VRAM:** 16 GB (SAM3 requires ~12 GB for inference)

---

## R2 Storage Patterns

The worker follows strict key patterns for R2 storage:

### Input Downloads

```
inputs/{userId}/{jobId}/{idx}.jpg
```

Example: `inputs/user123/job456/0.jpg`

### Output Uploads

```
outputs/{userId}/{jobId}/{ruleId}/{idx}.jpg     ← Processed result
masks/{userId}/{jobId}/{concept}/{idx}_{instance}.png  ← Instance masks
previews/{userId}/{jobId}/{idx}_preview.jpg    ← Low-res thumbnail
```

Example:
- `outputs/user123/job456/rule789/0.jpg` (recolored wall)
- `masks/user123/job456/wall/0_1.png` (wall instance #1)
- `masks/user123/job456/wall/0_2.png` (wall instance #2)
- `previews/user123/job456/0_preview.jpg` (256x256 preview)

---

## Workers API Callbacks

The worker sends per-item callbacks to the Workers API after each image is processed.

### Callback Endpoint

```
POST {WORKERS_API_URL}/jobs/{jobId}/callback
```

### Request Headers

```
X-GPU-Callback-Secret: {GPU_CALLBACK_SECRET}
X-Idempotency-Key: {SHA256(jobId:idx:attempt:timestamp//60)}
Content-Type: application/json
```

### Request Body

```json
{
  "idx": 0,
  "status": "completed",  // or "failed"
  "output_key": "outputs/user123/job456/rule789/0.jpg",
  "preview_key": "previews/user123/job456/0_preview.jpg",
  "error": null  // populated on failure
}
```

### Idempotency

The worker generates deterministic idempotency keys to enable callback deduplication:

```python
idempotency_key = SHA256(f"{jobId}:{idx}:{attempt}:{timestamp // 60}")[:16]
```

This ensures retries within a 1-minute window use the same idempotency key, allowing the Workers API to deduplicate duplicate callbacks.

---

## Testing

### Unit Tests

```bash
# Run all tests
cd gpu-worker
python -m pytest tests/ -v

# Run specific test modules
python -m pytest tests/test_segmenter.py -v
python -m pytest tests/test_applier.py -v
python -m pytest tests/test_r2_io.py -v
python -m pytest tests/test_callback.py -v
python -m pytest tests/test_pipeline.py -v

# Run with coverage
python -m pytest tests/ --cov=engine --cov-report=html
```

**Note:** Tests use mocked SAM3 model to avoid 3.4 GB download in CI. No GPU required for tests.

### Integration Tests

```bash
# Full pipeline test with all mocks
python -m pytest tests/test_pipeline.py::test_full_pipeline_with_mocks -v
```

### Manual Testing with Sample Image

```bash
# 1. Place test image in R2
# inputs/test-user/test-job/0.jpg

# 2. Trigger job via Runpod (or local adapter)
# Job spec example:
{
  "userId": "test-user",
  "jobId": "test-job",
  "concepts": ["wall", "floor", "furniture"],
  "rules": [
    {
      "ruleId": "rule1",
      "concept": "wall",
      "type": "recolor",
      "params": {"color": "#FF5733"}
    }
  ],
  "imageCount": 1
}

# 3. Monitor logs for progress
docker logs -f <container_id>

# 4. Verify outputs in R2
# outputs/test-user/test-job/rule1/0.jpg
# masks/test-user/test-job/wall/0_*.png
# previews/test-user/test-job/0_preview.jpg
```

---

## Troubleshooting

### Common Issues

#### 1. `403 Forbidden` when downloading SAM3 model

**Cause:** HF_TOKEN is invalid or SAM3 access not approved

**Solution:**
- Verify token at https://huggingface.co/settings/tokens
- Request access at https://huggingface.co/facebook/sam3
- Wait for approval email from Meta AI

#### 2. `CUDA out of memory` error

**Cause:** GPU VRAM insufficient for SAM3 + batch processing

**Solution:**
- Reduce `BATCH_CONCURRENCY` env var (default: 4)
- Use GPU with 16+ GB VRAM
- Process images sequentially (set `BATCH_CONCURRENCY=1`)

#### 3. `Connection timeout` on R2 upload

**Cause:** Network issues or R2 endpoint misconfigured

**Solution:**
- Verify `R2_ACCOUNT_ID` is correct
- Check R2 credentials (access key, secret key)
- Ensure bucket exists and is accessible
- Test connection: `aws s3 ls --endpoint-url https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com s3://{BUCKET_NAME}/`

#### 4. `Callback failed` in logs (Workers API unreachable)

**Cause:** Workers API down or URL misconfigured

**Solution:**
- Verify `WORKERS_API_URL` is correct
- Check `GPU_CALLBACK_SECRET` matches Workers API config
- Pipeline continues processing (callback failure doesn't block job)

#### 5. Model cache not persisting across container restarts

**Cause:** Docker volume not mounted

**Solution:**
- Mount volume: `-v $(pwd)/models:/models`
- Verify cache directory: `docker run ... ls -lh /models`

---

## Performance

### SAM3 Model Specifications

| Metric | Value |
|--------|-------|
| Parameters | 848M |
| Weights Size | 3.4 GB |
| Inference Time | ~300ms/image (RTX A4000), ~100ms/image (A100) |
| VRAM Usage | ~12 GB (FP32), ~8 GB (FP16) |
| Precision | FP32 (default), FP16 (future optimization) |

### Pipeline Performance

- **Stage 1 (Segmentation):** ~300ms per concept per image
- **Stage 2 (Rule Application):** ~50ms per rule per image
- **R2 Upload:** ~200ms per output (depends on network)
- **Callback:** ~100ms per item (depends on Workers API latency)

**Total job time estimate:**
```
T = (num_images × num_concepts × 300ms) + (num_images × num_rules × 50ms) + overhead
```

Example: 10 images, 3 concepts, 2 rules
```
T = (10 × 3 × 300ms) + (10 × 2 × 50ms) + 2s ≈ 11s
```

---

## Development

### Project Structure

```
gpu-worker/
├── engine/
│   ├── segmenter.py          # SAM3 model wrapper
│   ├── applier.py            # Rule application engine
│   ├── r2_io.py              # R2 storage layer (boto3)
│   ├── callback.py           # Workers callback client
│   └── pipeline.py           # Two-stage orchestrator
├── adapters/
│   ├── runpod_serverless.py  # Runpod handler
│   └── queue_pull.py         # Alternative adapter (future)
├── presets/
│   ├── interior.py           # Interior domain concepts
│   └── seller.py             # Seller domain concepts
├── tests/
│   ├── test_segmenter.py     # Unit tests for segmenter
│   ├── test_applier.py       # Unit tests for applier
│   ├── test_r2_io.py         # Unit tests for R2 I/O
│   ├── test_callback.py      # Unit tests for callback
│   └── test_pipeline.py      # Integration tests
├── main.py                   # Entry point
├── Dockerfile                # Docker image definition
├── requirements.txt          # Python dependencies
├── .env.example              # Environment variable template
├── .dockerignore             # Docker build exclusions
└── README.md                 # This file
```

### Adding New Domain Presets

1. Create new preset file: `presets/your_domain.py`
2. Define concepts list:
   ```python
   YOUR_DOMAIN_CONCEPTS = [
       "concept1",
       "concept2",
       # ...
   ]
   ```
3. Update job spec to reference new domain

### Extending Rule Types

Currently supported: `recolor` (MVP)

Future rule types (v2):
- `tone`: Adjust brightness/contrast/saturation
- `texture`: Apply texture overlay
- `remove`: Remove concept (transparent or inpaint)

To add new rule type:
1. Update `engine/applier.py` with new rule logic
2. Add tests in `tests/test_applier.py`
3. Update this README with usage examples

---

## Security

### Credential Management

- ✅ All credentials stored in environment variables (not hardcoded)
- ✅ `.env` file excluded from git (see `.gitignore`)
- ✅ `.env.example` provided as template (no real values)
- ✅ Shared secret authentication for callbacks (`GPU_CALLBACK_SECRET`)

### Best Practices

1. **Never commit** `.env` file or model weights to git
2. **Rotate secrets** regularly (R2 keys, callback secret, HF token)
3. **Use read-only** R2 credentials for input bucket (if possible)
4. **Validate** job specs to prevent malicious inputs
5. **Monitor** GPU usage to detect abuse/misuse

---

## License

This GPU Worker is part of the S3 domain palette engine.

---

## Support

For issues or questions:
- Check logs: `docker logs <container_id>`
- Review troubleshooting section above
- Verify environment variables are set correctly
- Test GPU access: `nvidia-smi` inside container

**SAM3 Model:** https://huggingface.co/facebook/sam3
**Runpod Docs:** https://docs.runpod.io/serverless/overview
**R2 Docs:** https://developers.cloudflare.com/r2/
