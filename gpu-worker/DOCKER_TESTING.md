# Docker End-to-End Verification Guide

This guide explains how to manually verify that the GPU Worker Docker container runs correctly.

## Prerequisites

1. **Docker installed** with GPU support (nvidia-docker runtime)
2. **NVIDIA GPU** with CUDA 12.1+ drivers (optional - will fallback to CPU)
3. **Environment variables** configured in `.env` file

## Quick Start

The easiest way to run verification is using the automated script:

```bash
cd gpu-worker
./docker-verification.sh
```

This script will:
- ✓ Check all prerequisites
- ✓ Build the Docker image
- ✓ Run startup tests
- ✓ Verify worker initialization
- ✓ Check documentation completeness

## Manual Testing Steps

If you prefer to test manually, follow these steps:

### Step 1: Prepare Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with real credentials
nano .env
```

Required variables:
- `HF_TOKEN` - HuggingFace token (get from https://huggingface.co/settings/tokens)
- `R2_ACCOUNT_ID` - Cloudflare R2 account ID
- `R2_ACCESS_KEY_ID` - R2 access key
- `R2_SECRET_ACCESS_KEY` - R2 secret key
- `R2_BUCKET_NAME` - R2 bucket name
- `WORKERS_API_URL` - Workers API endpoint
- `GPU_CALLBACK_SECRET` - Shared secret for callbacks

### Step 2: Build Docker Image

```bash
cd gpu-worker
docker build -t s3-gpu-worker:test .
```

**Expected outcome:**
- ✓ Build completes without errors
- ✓ Image size is approximately 8GB (PyTorch + CUDA runtime)
- ✓ No missing files or dependencies

**Common issues:**
- If build fails with "file not found", ensure you're in the `gpu-worker` directory
- If Python package installation fails, check `requirements.txt` for syntax errors

### Step 3: Test Container Startup (No GPU)

First, test basic container startup without GPU:

```bash
docker run --rm --env-file .env s3-gpu-worker:test
```

**Expected outcome:**
- ✓ Container starts without crashes
- ✓ Imports all Python modules successfully
- ✓ Shows "Starting Runpod serverless handler" or similar message
- ⚠️ May show "CUDA not available, using CPU" (expected without --gpus flag)
- ⚠️ May fail to load SAM3 model if HF_TOKEN is invalid (expected with placeholder)

**What to verify:**
1. **No import errors** - All modules load successfully
2. **No syntax errors** - Python code runs without exceptions
3. **Environment variables loaded** - Check logs for env var warnings
4. **Graceful error handling** - If model fails to load, error message is clear

**Common issues:**
- `ImportError: No module named 'transformers'` → requirements.txt missing dependency
- `ModuleNotFoundError: No module named 'engine'` → COPY command in Dockerfile incorrect
- `ValueError: HF_TOKEN is required` → Expected if using placeholder token

### Step 4: Test Container with GPU

If you have an NVIDIA GPU, test with GPU support:

```bash
docker run --rm --gpus all --env-file .env s3-gpu-worker:test
```

**Expected outcome:**
- ✓ Container detects GPU
- ✓ Shows CUDA version in logs
- ✓ Model loads or attempts to download (if HF_TOKEN valid)
- ✓ No GPU errors or CUDA out-of-memory issues

**What to verify:**
1. **GPU detected** - Look for "CUDA available: True" or similar
2. **CUDA version** - Should be 12.1 or higher
3. **Model caching** - Downloads to `/models` directory
4. **Worker ready** - Shows "Handler ready" or "Waiting for jobs"

**Common issues:**
- `nvidia-smi not found` → NVIDIA drivers not installed
- `CUDA error: out of memory` → GPU has insufficient memory (need 8GB+ for SAM3)
- `RuntimeError: CUDA runtime version mismatch` → Update NVIDIA drivers

### Step 5: Test with Volume Mount (Model Caching)

Test that model weights are cached correctly:

```bash
# Create local models directory
mkdir -p ./models

# Run with volume mount
docker run --rm --gpus all --env-file .env \
  -v $(pwd)/models:/models \
  s3-gpu-worker:test
```

**Expected outcome:**
- ✓ First run downloads 3.4GB SAM3 model to `./models/`
- ✓ Second run reuses cached model (faster startup)
- ✓ Models directory contains `sam3/` subdirectory

**What to verify:**
1. **First run** - Downloads model (check `./models/` grows to ~3.4GB)
2. **Second run** - Skips download (startup is faster)
3. **Persistence** - Models directory persists after container stops

### Step 6: Test Worker Initialization

Run the container and let it initialize fully:

```bash
docker run --rm --gpus all --env-file .env s3-gpu-worker:test 2>&1 | tee worker.log
```

Let it run for 30 seconds, then press Ctrl+C.

**What to verify in logs:**

1. **Imports successful**
   ```
   ✓ Look for: No "ImportError" or "ModuleNotFoundError"
   ```

2. **Environment loaded**
   ```
   ✓ Look for: Environment variables logged (without revealing secrets)
   ```

3. **GPU detection**
   ```
   ✓ Look for: "CUDA available: True" or "Using device: cuda"
   ✗ Avoid: "CUDA not available" (if GPU expected)
   ```

4. **Model loading**
   ```
   ✓ Look for: "Loading SAM3 model" or "Model loaded successfully"
   ⚠️ Or: "Failed to load model: HF_TOKEN invalid" (expected with placeholder)
   ⚠️ Or: "SAM3 model is gated" (expected if access not approved)
   ```

5. **Worker ready**
   ```
   ✓ Look for: "Starting Runpod serverless handler" or "Handler ready"
   ✗ Avoid: Crashes, stack traces, or unhandled exceptions
   ```

6. **No crashes**
   ```
   ✓ Container keeps running (doesn't exit immediately)
   ✗ Avoid: "Traceback", "Exception", "Error" (unless from invalid credentials)
   ```

### Step 7: Verify Error Handling

Test that the worker handles errors gracefully:

#### Test 1: Missing HF_TOKEN
```bash
# Run without HF_TOKEN
docker run --rm -e ADAPTER=runpod -e LOG_LEVEL=INFO s3-gpu-worker:test
```

**Expected:** Clear error message like "HF_TOKEN is required" (not a crash)

#### Test 2: Invalid R2 credentials
```bash
# Run with invalid R2 credentials
docker run --rm --env-file .env \
  -e R2_ACCESS_KEY_ID=invalid \
  s3-gpu-worker:test
```

**Expected:** Worker starts, but R2 operations would fail with clear error (not tested until job submitted)

## Verification Checklist

Use this checklist to confirm all aspects are working:

### Build Phase
- [ ] Docker image builds without errors
- [ ] Image size is approximately 8GB
- [ ] All dependencies install successfully
- [ ] No warnings about missing files

### Startup Phase
- [ ] Container starts without immediate crash
- [ ] All Python modules import successfully
- [ ] Environment variables load correctly
- [ ] Log level configuration works

### GPU Detection (if applicable)
- [ ] CUDA detected and version shown
- [ ] GPU device name shown in logs
- [ ] No GPU initialization errors

### Model Loading (with valid HF_TOKEN)
- [ ] SAM3 model downloads successfully
- [ ] Model cached to `/models` directory
- [ ] Second startup reuses cached model
- [ ] Model loaded to GPU (not CPU)

### Worker Initialization
- [ ] Runpod adapter starts correctly
- [ ] Handler registered and ready
- [ ] No unhandled exceptions
- [ ] Worker waits for jobs (doesn't exit)

### Error Handling
- [ ] Missing HF_TOKEN shows clear error
- [ ] Invalid credentials fail gracefully
- [ ] Errors logged with helpful messages
- [ ] Worker doesn't crash on config errors

## Troubleshooting

### Issue: Docker build fails

**Symptoms:** `ERROR: failed to solve` during build

**Solutions:**
1. Check you're in the `gpu-worker` directory
2. Verify all files exist: `ls engine/ adapters/ presets/ main.py`
3. Check Dockerfile syntax: `docker build --no-cache -t s3-gpu-worker:test .`

### Issue: Container crashes immediately

**Symptoms:** Container exits right after start

**Solutions:**
1. Check logs: `docker logs <container_id>`
2. Verify Python syntax: `python3 -m py_compile main.py`
3. Test imports: `docker run --rm s3-gpu-worker:test python3 -c "import engine"`

### Issue: CUDA not available

**Symptoms:** "CUDA not available, using CPU"

**Solutions:**
1. Install nvidia-docker: `sudo apt-get install nvidia-docker2`
2. Verify GPU: `nvidia-smi`
3. Add `--gpus all` flag to `docker run`

### Issue: Model download fails

**Symptoms:** "Failed to download model" or "401 Unauthorized"

**Solutions:**
1. Check HF_TOKEN is valid: `huggingface-cli whoami`
2. Request SAM3 access: https://huggingface.co/facebook/sam3
3. Wait for approval email from Meta AI (can take 1-2 days)

### Issue: Out of memory

**Symptoms:** `CUDA error: out of memory`

**Solutions:**
1. Check GPU memory: `nvidia-smi` (need 8GB+)
2. Close other GPU applications
3. Consider using smaller batch size in job config

## Success Criteria

The Docker container is verified when:

✅ **Container starts** - No immediate crashes or exits
✅ **Model loads** - SAM3 downloads or attempts to (with valid token)
✅ **Worker ready** - Handler initialized and waiting for jobs
✅ **No GPU errors** - GPU detected and used (if available)
✅ **Graceful errors** - Clear error messages for invalid config
✅ **Logs are clean** - No unexpected exceptions or warnings

## Next Steps

After verification passes:

1. **Deploy to Runpod**
   ```bash
   docker tag s3-gpu-worker:test <your-registry>/s3-gpu-worker:latest
   docker push <your-registry>/s3-gpu-worker:latest
   runpod deploy --image <your-registry>/s3-gpu-worker:latest
   ```

2. **Test with real job**
   - Submit a test job through Runpod console
   - Verify job completes successfully
   - Check R2 for uploaded outputs
   - Verify Workers receives callback

3. **Monitor production**
   - Set up logging aggregation
   - Monitor GPU memory usage
   - Track job success/failure rates
   - Alert on errors

## Additional Resources

- SAM3 Model: https://huggingface.co/facebook/sam3
- Runpod Docs: https://docs.runpod.io/
- NVIDIA Docker: https://github.com/NVIDIA/nvidia-docker
- Cloudflare R2: https://developers.cloudflare.com/r2/
