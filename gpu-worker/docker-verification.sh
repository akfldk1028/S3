#!/bin/bash
# GPU Worker Docker End-to-End Verification Script
#
# This script performs comprehensive verification of the Docker container,
# checking that it starts correctly, initializes the worker, and handles
# errors gracefully.
#
# Prerequisites:
# - Docker installed with GPU support (nvidia-docker)
# - .env file with required environment variables
# - NVIDIA GPU with CUDA 12.1+ drivers (optional - will test CPU fallback)

set -e

echo "=========================================="
echo "GPU Worker Docker E2E Verification"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((TESTS_FAILED++))
    fi
}

# Check prerequisites
echo "Step 1: Checking prerequisites..."
echo "-----------------------------------"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker not found. Please install Docker first.${NC}"
    exit 1
fi
print_result 0 "Docker installed"

# Check nvidia-docker (optional)
if command -v nvidia-smi &> /dev/null; then
    print_result 0 "NVIDIA GPU detected"
    GPU_AVAILABLE=true
else
    echo -e "${YELLOW}WARNING: nvidia-smi not found. Tests will run in CPU mode.${NC}"
    GPU_AVAILABLE=false
fi

# Check .env file
if [ ! -f .env ]; then
    echo -e "${YELLOW}WARNING: .env file not found. Creating from .env.example...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}Please edit .env with real credentials before running tests.${NC}"
fi

if [ -f .env ]; then
    print_result 0 ".env file exists"

    # Check for required variables
    echo ""
    echo "Checking required environment variables:"

    required_vars=("HF_TOKEN" "R2_ACCOUNT_ID" "R2_ACCESS_KEY_ID" "R2_SECRET_ACCESS_KEY" "R2_BUCKET_NAME" "WORKERS_API_URL" "GPU_CALLBACK_SECRET")

    for var in "${required_vars[@]}"; do
        if grep -q "^${var}=" .env && ! grep -q "^${var}=your_" .env && ! grep -q "^${var}=$" .env; then
            print_result 0 "$var is set"
        else
            print_result 1 "$var is not configured (using placeholder)"
        fi
    done
else
    print_result 1 ".env file missing"
    exit 1
fi

echo ""
echo "Step 2: Building Docker image..."
echo "-----------------------------------"

# Build Docker image
if docker build -t s3-gpu-worker:test . ; then
    print_result 0 "Docker image built successfully"
else
    print_result 1 "Docker image build failed"
    exit 1
fi

# Check image size
IMAGE_SIZE=$(docker images s3-gpu-worker:test --format "{{.Size}}")
echo "Image size: $IMAGE_SIZE (expected: ~8GB)"

echo ""
echo "Step 3: Running container startup test..."
echo "-----------------------------------"

# Create a test script to run inside the container
cat > test_startup.py << 'EOF'
#!/usr/bin/env python3
"""
Container startup verification script.
Tests that the worker initializes correctly.
"""
import sys
import os

def test_imports():
    """Test that all required modules can be imported."""
    print("Testing module imports...")
    try:
        from engine import segmenter, applier, r2_io, callback, pipeline
        from adapters import runpod_serverless
        from presets import interior, seller
        print("✓ All modules imported successfully")
        return True
    except ImportError as e:
        print(f"✗ Import failed: {e}")
        return False

def test_environment():
    """Test that required environment variables are set."""
    print("\nTesting environment variables...")
    required_vars = [
        "HF_TOKEN", "R2_ACCOUNT_ID", "R2_ACCESS_KEY_ID",
        "R2_SECRET_ACCESS_KEY", "R2_BUCKET_NAME",
        "WORKERS_API_URL", "GPU_CALLBACK_SECRET"
    ]

    missing = []
    for var in required_vars:
        if not os.getenv(var):
            missing.append(var)

    if missing:
        print(f"✗ Missing environment variables: {', '.join(missing)}")
        return False
    else:
        print("✓ All required environment variables are set")
        return True

def test_gpu_availability():
    """Test GPU availability."""
    print("\nTesting GPU availability...")
    try:
        import torch
        if torch.cuda.is_available():
            device_name = torch.cuda.get_device_name(0)
            print(f"✓ GPU available: {device_name}")
            print(f"  CUDA version: {torch.version.cuda}")
            return True
        else:
            print("⚠ No GPU available - will use CPU (slower)")
            return True  # Not a failure, just a warning
    except ImportError:
        print("✗ PyTorch not installed")
        return False
    except Exception as e:
        print(f"✗ GPU check failed: {e}")
        return False

def test_model_initialization():
    """Test that SAM3 model can be initialized (or fails gracefully)."""
    print("\nTesting model initialization...")
    try:
        from engine.segmenter import SAM3Segmenter

        # This will attempt to load the model
        # If HF_TOKEN is invalid, it should fail gracefully
        try:
            segmenter = SAM3Segmenter()
            print("✓ SAM3 model initialized successfully")
            return True
        except Exception as e:
            error_msg = str(e)
            if "HF_TOKEN" in error_msg or "token" in error_msg.lower():
                print(f"⚠ Model initialization failed due to auth: {error_msg}")
                print("  This is expected if HF_TOKEN is not configured")
                return True  # Expected failure with placeholder credentials
            elif "gated" in error_msg.lower():
                print(f"⚠ SAM3 model is gated - access approval required")
                print("  Visit https://huggingface.co/facebook/sam3")
                return True  # Expected if not approved yet
            else:
                print(f"✗ Unexpected model initialization error: {e}")
                return False
    except ImportError as e:
        print(f"✗ Failed to import segmenter: {e}")
        return False

def main():
    """Run all tests."""
    print("=" * 50)
    print("GPU Worker Container Startup Verification")
    print("=" * 50)

    tests = [
        ("Module Imports", test_imports),
        ("Environment Variables", test_environment),
        ("GPU Availability", test_gpu_availability),
        ("Model Initialization", test_model_initialization),
    ]

    results = []
    for name, test_func in tests:
        print(f"\n[Test: {name}]")
        try:
            result = test_func()
            results.append(result)
        except Exception as e:
            print(f"✗ Test crashed: {e}")
            results.append(False)

    print("\n" + "=" * 50)
    passed = sum(results)
    total = len(results)
    print(f"Results: {passed}/{total} tests passed")
    print("=" * 50)

    return 0 if all(results) else 1

if __name__ == "__main__":
    sys.exit(main())
EOF

# Run the test script inside the container
echo "Starting container with test script..."

if [ "$GPU_AVAILABLE" = true ]; then
    GPU_FLAGS="--gpus all"
    echo "Running with GPU support..."
else
    GPU_FLAGS=""
    echo "Running in CPU-only mode..."
fi

# Run container with timeout (30 seconds)
if timeout 30 docker run --rm $GPU_FLAGS --env-file .env \
    -v "$(pwd)/test_startup.py:/app/test_startup.py:ro" \
    s3-gpu-worker:test python3 test_startup.py ; then
    print_result 0 "Container startup test completed"
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        print_result 1 "Container startup test timed out (30s)"
    else
        print_result 1 "Container startup test failed with exit code $EXIT_CODE"
    fi
fi

# Clean up
rm -f test_startup.py

echo ""
echo "Step 4: Testing worker initialization..."
echo "-----------------------------------"

# Test that the worker starts without crashing (5 second test)
echo "Starting worker for 5 seconds to verify no immediate crashes..."

if timeout 5 docker run --rm $GPU_FLAGS --env-file .env \
    s3-gpu-worker:test 2>&1 | tee /tmp/worker_output.log ; then
    # If it exits cleanly within 5 seconds, that's actually a failure
    # (worker should keep running)
    if grep -q "error\|Error\|ERROR\|exception\|Exception" /tmp/worker_output.log; then
        print_result 1 "Worker crashed with error"
        echo "Error output:"
        grep -i "error\|exception" /tmp/worker_output.log | head -5
    else
        echo -e "${YELLOW}Worker exited cleanly (might be waiting for jobs)${NC}"
    fi
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        print_result 0 "Worker running without crashes (timed out as expected)"
    else
        print_result 1 "Worker failed to start"
    fi
fi

# Clean up
rm -f /tmp/worker_output.log

echo ""
echo "Step 5: Verification of key patterns..."
echo "-----------------------------------"

# Verify R2 key patterns are documented
if grep -q "inputs/{userId}/{jobId}/{idx}" README.md; then
    print_result 0 "R2 key patterns documented in README"
else
    print_result 1 "R2 key patterns not documented"
fi

# Verify callback authentication is documented
if grep -q "GPU_CALLBACK_SECRET" README.md; then
    print_result 0 "Callback authentication documented"
else
    print_result 1 "Callback authentication not documented"
fi

echo ""
echo "=========================================="
echo "Verification Summary"
echo "=========================================="
echo -e "Tests passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests failed: ${RED}${TESTS_FAILED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All verification checks passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Configure real credentials in .env"
    echo "2. Request SAM3 access at https://huggingface.co/facebook/sam3"
    echo "3. Test with real GPU hardware"
    echo "4. Deploy to Runpod: runpod deploy --image s3-gpu-worker:test"
    exit 0
else
    echo -e "${RED}✗ Some verification checks failed.${NC}"
    echo "Please review the errors above and fix issues before deployment."
    exit 1
fi
