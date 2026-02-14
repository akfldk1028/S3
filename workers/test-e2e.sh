#!/bin/bash

# End-to-End Verification Script
# Tests: auth flow + rule creation

set -e  # Exit on error

API_URL="http://localhost:3000"

echo "=== E2E Verification: Auth Flow + Rule Creation ==="
echo ""

# 1. POST /auth/anon → receive JWT
echo "1. POST /auth/anon → receive JWT"
RESPONSE=$(curl -s -X POST "$API_URL/auth/anon")
echo "Response: $RESPONSE"

# Extract JWT from response
JWT=$(echo "$RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
if [ -z "$JWT" ]; then
  echo "❌ FAILED: No JWT token received"
  exit 1
fi
echo "✅ PASSED: JWT received"
echo "JWT: ${JWT:0:50}..."
echo ""

# 2. GET /me with JWT → receive user state
echo "2. GET /me with JWT → receive user state"
RESPONSE=$(curl -s -H "Authorization: Bearer $JWT" "$API_URL/auth/me")
echo "Response: $RESPONSE"
if echo "$RESPONSE" | grep -q '"success":true'; then
  echo "✅ PASSED: User state received"
else
  echo "❌ FAILED: Invalid response from /me"
  exit 1
fi
echo ""

# 3. GET /presets with JWT → receive 2 presets
echo "3. GET /presets with JWT → receive 2 presets"
RESPONSE=$(curl -s -H "Authorization: Bearer $JWT" "$API_URL/presets")
echo "Response: $RESPONSE"
if echo "$RESPONSE" | grep -q '"success":true'; then
  echo "✅ PASSED: Presets received"
else
  echo "❌ FAILED: Invalid response from /presets"
  exit 1
fi
echo ""

# 4. POST /rules with JWT → create rule
echo "4. POST /rules with JWT → create rule"
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

# Extract rule ID
RULE_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -z "$RULE_ID" ]; then
  echo "❌ FAILED: No rule ID received"
  exit 1
fi
echo "✅ PASSED: Rule created with ID: $RULE_ID"
echo ""

# 5. GET /rules with JWT → verify rule appears
echo "5. GET /rules with JWT → verify rule appears"
RESPONSE=$(curl -s -H "Authorization: Bearer $JWT" "$API_URL/rules")
echo "Response: $RESPONSE"
if echo "$RESPONSE" | grep -q "$RULE_ID"; then
  echo "✅ PASSED: Rule appears in list"
else
  echo "❌ FAILED: Rule not found in list"
  exit 1
fi
echo ""

# 6. PUT /rules/:id with JWT → update rule
echo "6. PUT /rules/:id with JWT → update rule"
RESPONSE=$(curl -s -X PUT "$API_URL/rules/$RULE_ID" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated E2E Test Rule"
  }')
echo "Response: $RESPONSE"
if echo "$RESPONSE" | grep -q '"success":true'; then
  echo "✅ PASSED: Rule updated"
else
  echo "❌ FAILED: Failed to update rule"
  exit 1
fi
echo ""

# 7. DELETE /rules/:id with JWT → delete rule
echo "7. DELETE /rules/:id with JWT → delete rule"
RESPONSE=$(curl -s -X DELETE "$API_URL/rules/$RULE_ID" \
  -H "Authorization: Bearer $JWT")
echo "Response: $RESPONSE"
if echo "$RESPONSE" | grep -q '"success":true'; then
  echo "✅ PASSED: Rule deleted"
else
  echo "❌ FAILED: Failed to delete rule"
  exit 1
fi
echo ""

# 8. Verify rule no longer exists
echo "8. Verify rule no longer exists"
RESPONSE=$(curl -s -H "Authorization: Bearer $JWT" "$API_URL/rules")
echo "Response: $RESPONSE"
if echo "$RESPONSE" | grep -q "$RULE_ID"; then
  echo "❌ FAILED: Rule still exists after deletion"
  exit 1
else
  echo "✅ PASSED: Rule successfully deleted"
fi
echo ""

echo "=== ALL E2E TESTS PASSED ==="
