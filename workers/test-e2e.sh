#!/bin/bash

# End-to-End Verification Script for Jobs API
# Tests the full job lifecycle as specified in subtask-7-2

set -e

API_URL="http://localhost:8787"
AUTH_TOKEN="test-user-123"
GPU_SECRET="test-gpu-callback-secret-for-local-dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================"
echo "E2E Verification: Full Job Lifecycle"
echo "======================================"
echo ""

# Helper function to print test results
check_result() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"

    if echo "$actual" | grep -q "$expected"; then
        echo -e "${GREEN}✓${NC} $test_name"
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected to contain: $expected"
        echo "  Actual response: $actual"
        return 1
    fi
}

# Wait for server to be ready
echo -e "${YELLOW}⏳ Checking if wrangler dev is running...${NC}"
for i in {1..10}; do
    if curl -s "$API_URL/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Server is ready"
        break
    fi
    if [ $i -eq 10 ]; then
        echo -e "${RED}✗${NC} Server is not responding. Please run 'npm run dev' first."
        exit 1
    fi
    sleep 1
done

echo ""
echo "======================================"
echo "Test 1: POST /jobs (Create Job)"
echo "======================================"

RESPONSE=$(curl -s -X POST "$API_URL/api/jobs" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "preset": "remove-background",
    "itemCount": 3
  }')

echo "Response: $RESPONSE"
JOB_ID=$(echo "$RESPONSE" | grep -o '"jobId":"[^"]*"' | cut -d'"' -f4)

if [ -z "$JOB_ID" ]; then
    echo -e "${RED}✗${NC} Failed to extract jobId from response"
    exit 1
fi

echo -e "${GREEN}✓${NC} Job created: $JOB_ID"
check_result "Response contains jobId" "jobId" "$RESPONSE"
check_result "Response contains urls" "urls" "$RESPONSE"

echo ""
echo "======================================"
echo "Test 2: POST /jobs/:id/confirm-upload"
echo "======================================"

RESPONSE=$(curl -s -X POST "$API_URL/api/jobs/$JOB_ID/confirm-upload" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "totalItems": 3
  }')

echo "Response: $RESPONSE"
check_result "State transitioned to uploaded" "uploaded" "$RESPONSE"

echo ""
echo "======================================"
echo "Test 3: POST /jobs/:id/execute"
echo "======================================"

RESPONSE=$(curl -s -X POST "$API_URL/api/jobs/$JOB_ID/execute" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "concepts": {
      "background": { "action": "remove", "value": "" }
    },
    "protect": ["person", "face"]
  }')

echo "Response: $RESPONSE"
check_result "State transitioned to queued" "queued" "$RESPONSE"

echo ""
echo "======================================"
echo "Test 4: POST /jobs/:id/callback (3 items)"
echo "======================================"

# Callback for item 0
echo "Callback for item 0..."
RESPONSE=$(curl -s -X POST "$API_URL/api/jobs/$JOB_ID/callback" \
  -H "x-gpu-callback-secret: $GPU_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "idx": 0,
    "status": "done",
    "output_key": "outputs/test-user-123/'$JOB_ID'/0_result.png",
    "preview_key": "previews/test-user-123/'$JOB_ID'/0_thumb.jpg",
    "idempotency_key": "'$JOB_ID'-item-0"
  }')

echo "Response: $RESPONSE"
check_result "Callback 1 processed" "success" "$RESPONSE"

# Callback for item 1
echo "Callback for item 1..."
RESPONSE=$(curl -s -X POST "$API_URL/api/jobs/$JOB_ID/callback" \
  -H "x-gpu-callback-secret: $GPU_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "idx": 1,
    "status": "done",
    "output_key": "outputs/test-user-123/'$JOB_ID'/1_result.png",
    "preview_key": "previews/test-user-123/'$JOB_ID'/1_thumb.jpg",
    "idempotency_key": "'$JOB_ID'-item-1"
  }')

echo "Response: $RESPONSE"
check_result "Callback 2 processed" "success" "$RESPONSE"

# Callback for item 2
echo "Callback for item 2..."
RESPONSE=$(curl -s -X POST "$API_URL/api/jobs/$JOB_ID/callback" \
  -H "x-gpu-callback-secret: $GPU_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "idx": 2,
    "status": "done",
    "output_key": "outputs/test-user-123/'$JOB_ID'/2_result.png",
    "preview_key": "previews/test-user-123/'$JOB_ID'/2_thumb.jpg",
    "idempotency_key": "'$JOB_ID'-item-2"
  }')

echo "Response: $RESPONSE"
check_result "Callback 3 processed" "success" "$RESPONSE"

echo ""
echo "======================================"
echo "Test 5: GET /jobs/:id (Final State)"
echo "======================================"

RESPONSE=$(curl -s -X GET "$API_URL/api/jobs/$JOB_ID" \
  -H "Authorization: Bearer $AUTH_TOKEN")

echo "Response: $RESPONSE"
check_result "State is 'done'" "done" "$RESPONSE"
check_result "Progress done=3" '"done":3' "$RESPONSE"
check_result "Progress failed=0" '"failed":0' "$RESPONSE"
check_result "Progress total=3" '"total":3' "$RESPONSE"

echo ""
echo "======================================"
echo "Test 6: GET /me (Credits Committed)"
echo "======================================"

RESPONSE=$(curl -s -X GET "$API_URL/api/user/me" \
  -H "Authorization: Bearer $AUTH_TOKEN")

echo "Response: $RESPONSE"
check_result "User state returned" "userId" "$RESPONSE"
check_result "Credits field exists" "credits" "$RESPONSE"
check_result "Active jobs field exists" "activeJobs" "$RESPONSE"

echo ""
echo "======================================"
echo "Test 7: POST /jobs (New Job for Cancel)"
echo "======================================"

RESPONSE=$(curl -s -X POST "$API_URL/api/jobs" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "preset": "remove-background",
    "itemCount": 2
  }')

echo "Response: $RESPONSE"
CANCEL_JOB_ID=$(echo "$RESPONSE" | grep -o '"jobId":"[^"]*"' | cut -d'"' -f4)

if [ -z "$CANCEL_JOB_ID" ]; then
    echo -e "${RED}✗${NC} Failed to create job for cancel test"
    exit 1
fi

echo -e "${GREEN}✓${NC} Job created for cancel test: $CANCEL_JOB_ID"

echo ""
echo "======================================"
echo "Test 8: POST /jobs/:id/cancel"
echo "======================================"

RESPONSE=$(curl -s -X POST "$API_URL/api/jobs/$CANCEL_JOB_ID/cancel" \
  -H "Authorization: Bearer $AUTH_TOKEN")

echo "Response: $RESPONSE"
check_result "Job cancelled" "canceled" "$RESPONSE"

echo ""
echo "======================================"
echo "Test 9: Idempotency Check"
echo "======================================"

# Try to send the same callback again (should be idempotent)
RESPONSE=$(curl -s -X POST "$API_URL/api/jobs/$JOB_ID/callback" \
  -H "x-gpu-callback-secret: $GPU_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "idx": 0,
    "status": "done",
    "output_key": "outputs/test-user-123/'$JOB_ID'/0_result.png",
    "preview_key": "previews/test-user-123/'$JOB_ID'/0_thumb.jpg",
    "idempotency_key": "'$JOB_ID'-item-0"
  }')

echo "Response: $RESPONSE"
check_result "Duplicate callback handled" "success" "$RESPONSE"

# Verify progress is still 3 (not 4)
RESPONSE=$(curl -s -X GET "$API_URL/api/jobs/$JOB_ID" \
  -H "Authorization: Bearer $AUTH_TOKEN")

echo "Final state after duplicate: $RESPONSE"
check_result "Progress still done=3 (not 4)" '"done":3' "$RESPONSE"

echo ""
echo "======================================"
echo -e "${GREEN}✓ All E2E tests passed!${NC}"
echo "======================================"
