# End-to-End Verification Guide

## Prerequisites

1. Ensure `.dev.vars` file exists with required secrets:
   ```
   JWT_SECRET=dev-jwt-secret-change-in-production
   GPU_CALLBACK_SECRET=dev-gpu-callback-secret-change-in-production
   ```

2. D1 migration must be applied:
   ```bash
   cd workers
   wrangler d1 migrations apply s3-db --local
   ```

## Running E2E Verification

### Step 1: Start the Development Server

In one terminal, start the wrangler dev server:

```bash
cd workers
npm run dev
```

Wait for the server to start. You should see output like:
```
⎔ Starting local server...
[wrangler:inf] Ready on http://localhost:3000
```

### Step 2: Run E2E Tests

In another terminal, run the test script:

```bash
cd workers
./test-e2e.sh
```

### Step 3: Verify All Tests Pass

Expected output:
```
=== E2E Verification: Auth Flow + Rule Creation ===

1. POST /auth/anon → receive JWT
✅ PASSED: JWT received

2. GET /me with JWT → receive user state
✅ PASSED: User state received

3. GET /presets with JWT → receive 2 presets
✅ PASSED: Presets received

4. POST /rules with JWT → create rule
✅ PASSED: Rule created

5. GET /rules with JWT → verify rule appears
✅ PASSED: Rule appears in list

6. PUT /rules/:id with JWT → update rule
✅ PASSED: Rule updated

7. DELETE /rules/:id with JWT → delete rule
✅ PASSED: Rule deleted

8. Verify rule no longer exists
✅ PASSED: Rule successfully deleted

=== ALL E2E TESTS PASSED ===
```

## Manual Testing (Alternative)

If the automated script doesn't work, you can run these curl commands manually:

### 1. Create Anonymous User

```bash
curl -X POST http://localhost:3000/auth/anon
```

Expected response:
```json
{
  "success": true,
  "data": {
    "user_id": "...",
    "token": "eyJ...",
    "plan": "free",
    "is_new": true
  }
}
```

**Save the JWT token for subsequent requests!**

### 2. Get User State

```bash
curl -H "Authorization: Bearer YOUR_JWT_HERE" http://localhost:3000/auth/me
```

Expected response:
```json
{
  "success": true,
  "data": {
    "id": "...",
    "plan": "free",
    "credits": 100,
    "rule_slots": 0,
    "concurrent_jobs": 0
  }
}
```

### 3. List Presets

```bash
curl -H "Authorization: Bearer YOUR_JWT_HERE" http://localhost:3000/presets
```

Expected response:
```json
{
  "success": true,
  "data": [
    {
      "id": "interior",
      "name": "건축/인테리어",
      "description": "건축/인테리어 도메인 팔레트"
    },
    {
      "id": "seller",
      "name": "쇼핑/셀러",
      "description": "쇼핑/셀러 도메인 팔레트"
    }
  ]
}
```

### 4. Create Rule

```bash
curl -X POST http://localhost:3000/rules \
  -H "Authorization: Bearer YOUR_JWT_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "preset_id": "interior",
    "name": "Test Rule",
    "concepts": {
      "wall": {"action": "remove", "value": 1},
      "floor": {"action": "remove", "value": 2}
    },
    "protect": ["person"]
  }'
```

Expected response:
```json
{
  "success": true,
  "data": {
    "id": "...",
    "user_id": "...",
    "preset_id": "interior",
    "name": "Test Rule",
    "concepts": {...},
    "protect": [...],
    "created_at": 1234567890,
    "updated_at": 1234567890
  }
}
```

**Save the rule ID for subsequent requests!**

### 5. List Rules

```bash
curl -H "Authorization: Bearer YOUR_JWT_HERE" http://localhost:3000/rules
```

Expected: Array containing the rule created in step 4.

### 6. Get Single Rule

```bash
curl -H "Authorization: Bearer YOUR_JWT_HERE" http://localhost:3000/rules/RULE_ID_HERE
```

Expected: Full rule object.

### 7. Update Rule

```bash
curl -X PUT http://localhost:3000/rules/RULE_ID_HERE \
  -H "Authorization: Bearer YOUR_JWT_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Test Rule"
  }'
```

Expected: Updated rule object with new name.

### 8. Delete Rule

```bash
curl -X DELETE http://localhost:3000/rules/RULE_ID_HERE \
  -H "Authorization: Bearer YOUR_JWT_HERE"
```

Expected response:
```json
{
  "success": true,
  "data": {
    "id": "...",
    "deleted": true
  }
}
```

### 9. Verify Deletion

```bash
curl -H "Authorization: Bearer YOUR_JWT_HERE" http://localhost:3000/rules
```

Expected: Empty array or array without the deleted rule.

## Verification Checklist

- [ ] TypeScript compilation succeeds (`npx tsc --noEmit`)
- [ ] Wrangler dev server starts without errors
- [ ] POST /auth/anon creates user and returns JWT
- [ ] GET /me with JWT returns user state
- [ ] GET /presets returns 2 presets (interior, seller)
- [ ] POST /rules creates rule in D1
- [ ] GET /rules returns user's rules
- [ ] GET /rules/:id returns single rule
- [ ] PUT /rules/:id updates rule
- [ ] DELETE /rules/:id deletes rule
- [ ] All responses use standardized envelope format
- [ ] Auth middleware blocks requests without JWT (401)
- [ ] All error codes match workflow.md specifications
