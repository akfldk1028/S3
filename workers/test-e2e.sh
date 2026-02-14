#!/bin/bash

# End-to-End Verification Script
# Tests: auth flow + rules CRUD + full job lifecycle

set -e

API_URL="${API_URL:-http://localhost:8787}"
GPU_SECRET="${GPU_SECRET:-test-gpu-callback-secret-for-local-dev}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

echo "======================================"
echo "S3 Workers — E2E Verification"
echo "======================================"
echo ""

# Wait for server
echo -e "${YELLOW}⏳ Checking if server is ready...${NC}"
for i in {1..10}; do
    if curl -s "$API_URL/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Server is ready"
        break
    fi
    if [ $i -eq 10 ]; then
        echo -e "${RED}✗${NC} Server is not responding. Please run 'npx wrangler dev' first."
        exit 1
    fi
    sleep 1
done

echo ""
echo "======================================"
echo "Part 1: Auth Flow"
echo "======================================"

# 1. POST /auth/anon → receive JWT
echo ""
echo "Test 1: POST /auth/anon"
RESPONSE=$(curl -s -X POST "$API_URL/auth/anon")
echo "Response: $RESPONSE"
JWT=$(echo "$RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
if [ -z "$JWT" ]; then
    echo -e "${RED}✗${NC} No JWT token received"
    exit 1
fi
echo -e "${GREEN}✓${NC} JWT received: ${JWT:0:50}..."

# 2. GET /me with JWT
echo ""
echo "Test 2: GET /me"
RESPONSE=$(curl -s -H "Authorization: Bearer $JWT" "$API_URL/me")
echo "Response: $RESPONSE"
check_result "User state returned" '"success":true' "$RESPONSE"

echo ""
echo "======================================"
echo "Part 2: Presets + Rules CRUD"
echo "======================================"

# 3. GET /presets
echo ""
echo "Test 3: GET /presets"
RESPONSE=$(curl -s -H "Authorization: Bearer $JWT" "$API_URL/presets")
echo "Response: $RESPONSE"
check_result "Presets received" '"success":true' "$RESPONSE"

# 4. POST /rules → create rule
echo ""
echo "Test 4: POST /rules"
RESPONSE=$(curl -s -X POST "$API_URL/rules" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "preset_id": "interior",
    "name": "E2E Test Rule",
    "concepts": {
      "wall": {"action": "remove", "value": "1"},
      "floor": {"action": "remove", "value": "2"}
    },
    "protect": ["person"]
  }')
echo "Response: $RESPONSE"
RULE_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -z "$RULE_ID" ]; then
    echo -e "${RED}✗${NC} No rule ID received"
    exit 1
fi
echo -e "${GREEN}✓${NC} Rule created: $RULE_ID"

# 5. GET /rules → verify rule
echo ""
echo "Test 5: GET /rules"
RESPONSE=$(curl -s -H "Authorization: Bearer $JWT" "$API_URL/rules")
echo "Response: $RESPONSE"
check_result "Rule appears in list" "$RULE_ID" "$RESPONSE"

# 6. PUT /rules/:id → update
echo ""
echo "Test 6: PUT /rules/:id"
RESPONSE=$(curl -s -X PUT "$API_URL/rules/$RULE_ID" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated E2E Test Rule"}')
echo "Response: $RESPONSE"
check_result "Rule updated" '"success":true' "$RESPONSE"

# 7. DELETE /rules/:id → delete
echo ""
echo "Test 7: DELETE /rules/:id"
RESPONSE=$(curl -s -X DELETE "$API_URL/rules/$RULE_ID" \
  -H "Authorization: Bearer $JWT")
echo "Response: $RESPONSE"
check_result "Rule deleted" '"success":true' "$RESPONSE"

echo ""
echo "======================================"
echo "Part 3: Jobs Lifecycle"
echo "======================================"

# 8. POST /jobs → create job
echo ""
echo "Test 8: POST /jobs"
RESPONSE=$(curl -s -X POST "$API_URL/jobs" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "preset": "interior",
    "itemCount": 3
  }')
echo "Response: $RESPONSE"
JOB_ID=$(echo "$RESPONSE" | grep -o '"jobId":"[^"]*"' | cut -d'"' -f4)
if [ -z "$JOB_ID" ]; then
    echo -e "${RED}✗${NC} No jobId received"
    exit 1
fi
echo -e "${GREEN}✓${NC} Job created: $JOB_ID"

# 9. POST /jobs/:id/confirm-upload
echo ""
echo "Test 9: POST /jobs/:id/confirm-upload"
RESPONSE=$(curl -s -X POST "$API_URL/jobs/$JOB_ID/confirm-upload" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"totalItems": 3}')
echo "Response: $RESPONSE"
check_result "State → uploaded" "uploaded" "$RESPONSE"

# 10. POST /jobs/:id/execute
echo ""
echo "Test 10: POST /jobs/:id/execute"
RESPONSE=$(curl -s -X POST "$API_URL/jobs/$JOB_ID/execute" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "concepts": {"background": {"action": "remove", "value": ""}},
    "protect": ["person"]
  }')
echo "Response: $RESPONSE"
check_result "State → queued" "queued" "$RESPONSE"

# 11. POST /jobs/:id/callback (3 items)
echo ""
echo "Test 11: POST /jobs/:id/callback (3 items)"
for i in 0 1 2; do
    echo "  Callback for item $i..."
    RESPONSE=$(curl -s -X POST "$API_URL/jobs/$JOB_ID/callback" \
      -H "x-gpu-callback-secret: $GPU_SECRET" \
      -H "Content-Type: application/json" \
      -d '{
        "idx": '$i',
        "status": "done",
        "output_key": "outputs/user/'$JOB_ID'/'$i'_result.png",
        "preview_key": "previews/user/'$JOB_ID'/'$i'_thumb.jpg",
        "idempotency_key": "'$JOB_ID'-item-'$i'"
      }')
    check_result "  Callback $i processed" "success" "$RESPONSE"
done

# 12. GET /jobs/:id → final state
echo ""
echo "Test 12: GET /jobs/:id (final state)"
RESPONSE=$(curl -s -H "Authorization: Bearer $JWT" "$API_URL/jobs/$JOB_ID")
echo "Response: $RESPONSE"
check_result "State is done" "done" "$RESPONSE"

# 13. POST /jobs/:id/cancel (new job)
echo ""
echo "Test 13: Job cancel flow"
RESPONSE=$(curl -s -X POST "$API_URL/jobs" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"preset": "interior", "itemCount": 1}')
CANCEL_JOB_ID=$(echo "$RESPONSE" | grep -o '"jobId":"[^"]*"' | cut -d'"' -f4)
RESPONSE=$(curl -s -X POST "$API_URL/jobs/$CANCEL_JOB_ID/cancel" \
  -H "Authorization: Bearer $JWT")
echo "Response: $RESPONSE"
check_result "Job cancelled" "canceled" "$RESPONSE"

echo ""
echo "======================================"
echo -e "${GREEN}✓ All E2E tests passed!${NC}"
echo "======================================"
