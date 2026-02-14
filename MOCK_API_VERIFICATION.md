# MockApiClient Verification

## Summary
All 13 frontend endpoints have been implemented in `MockApiClient` with realistic hardcoded data matching the API response structure from workflow.md §6.

## Endpoints Verified

### 1. ✅ POST /auth/anon - createAnonUser()
**Returns:** `{user_id, token}`
- Returns dynamic user_id and token with timestamps
- Simulates 300ms delay
- **Data structure:** ✅ Matches API contract

### 2. ✅ GET /me - getMe()
**Returns:** `User` model
- userId: 'mock-user-123'
- plan: 'free'
- credits: 1000
- activeJobs: 1
- **ruleSlots:** ✅ Includes RuleSlots(used: 2, max: 2)
- **Data structure:** ✅ Matches API contract

### 3. ✅ GET /presets - getPresets()
**Returns:** `List<Preset>`
- Returns 2 presets: '건축/인테리어' and '쇼핑/셀러'
- Each has id, name, conceptCount
- **Data structure:** ✅ Matches API contract

### 4. ✅ GET /presets/{id} - getPresetById()
**Returns:** `Preset` with detail fields
- Interior preset: 12 concepts, 2 protectDefaults, 2 outputTemplates
- Seller preset: 6 concepts, 1 protectDefault, 2 outputTemplates
- **concepts:** ✅ List<String> with realistic concept names
- **protectDefaults:** ✅ List<String>
- **outputTemplates:** ✅ List<OutputTemplate> with id, name, description
- **Data structure:** ✅ Matches API contract

### 5. ✅ POST /rules - createRule()
**Returns:** `String` (rule ID)
- Generates sequential rule IDs: 'rule-3', 'rule-4', etc.
- Stores rule in in-memory list
- **Data structure:** ✅ Matches API contract

### 6. ✅ GET /rules - getRules()
**Returns:** `List<Rule>`
- Returns 2 initial mock rules:
  - 'rule-1': '따뜻한 톤 변경' (interior preset)
  - 'rule-2': '배경 제거' (seller preset)
- Each rule has id, name, presetId, createdAt
- **concepts:** ✅ Map<String, ConceptAction> with action and value
- **protect:** ✅ List<String>
- **Data structure:** ✅ Matches API contract

### 7. ✅ PUT /rules/{id} - updateRule()
**Returns:** `void`
- Updates rule name, concepts, protect in in-memory storage
- Uses Freezed copyWith() for immutability
- **Data structure:** ✅ Matches API contract

### 8. ✅ DELETE /rules/{id} - deleteRule()
**Returns:** `void`
- Removes rule from in-memory list
- **Data structure:** ✅ Matches API contract

### 9. ✅ POST /jobs - createJob()
**Returns:** `{job_id, upload, confirm_url}`
- Generates sequential job IDs: 'mock-job-1', 'mock-job-2', etc.
- **upload:** ✅ List of {idx, url, key} for each item
- **confirm_url:** ✅ Mock confirmation URL
- Initializes job with status 'created'
- **Mock presigned URLs:** Uses https://mock-r2.example.com/...
- **Data structure:** ✅ Matches API contract

### 10. ✅ POST /jobs/{jobId}/confirm-upload - confirmUpload()
**Returns:** `void`
- Updates job status from 'created' → 'uploaded'
- **Data structure:** ✅ Matches API contract

### 11. ✅ POST /jobs/{jobId}/execute - executeJob()
**Returns:** `void`
- Updates job status to 'queued', then simulates progression
- Accepts concepts, protect, ruleId, outputTemplate parameters
- Triggers _simulateJobProgress() for realistic polling behavior
- **Data structure:** ✅ Matches API contract

### 12. ✅ GET /jobs/{jobId} - getJob()
**Returns:** `Job` model
- jobId: String
- status: 'created' | 'uploaded' | 'queued' | 'running' | 'done' | 'failed' | 'canceled'
- preset: String
- **progress:** ✅ JobProgress with done, failed, total
- **outputsReady:** ✅ List<JobItem> with idx, resultUrl, previewUrl
- **Realistic progression:** Mock job increments progress every 3 seconds
- **Data structure:** ✅ Matches API contract

### 13. ✅ POST /jobs/{jobId}/cancel - cancelJob()
**Returns:** `void`
- Updates job status to 'canceled'
- **Data structure:** ✅ Matches API contract

## Key Data Structures Verified

### ✅ User Model
- **Has ruleSlots:** RuleSlots(used, max)
- **Field mapping:** user_id → userId, active_jobs → activeJobs, rule_slots → ruleSlots

### ✅ Preset Model
- **List view:** id, name, conceptCount
- **Detail view:** + concepts, protectDefaults, outputTemplates

### ✅ Rule Model
- **concepts:** Map<String, ConceptAction> (not simple Map<String, String>)
- **ConceptAction:** action + optional value
- **protect:** List<String>

### ✅ Job Model
- **jobId:** String (not just 'id')
- **progress:** JobProgress object (not just done/total)
- **progress.failed:** ✅ Includes failed count (not just done/total!)
- **outputsReady:** List<JobItem> with idx, resultUrl, previewUrl

### ✅ JobItem Model
- **idx:** int
- **resultUrl:** String
- **previewUrl:** String

## Mock Data Characteristics

### Network Simulation
- All methods use `await Future.delayed(Duration(milliseconds: 300))`
- Simulates realistic API latency

### Korean Text
- Preset names: '건축/인테리어', '쇼핑/셀러'
- Rule names: '따뜻한 톤 변경', '배경 제거'
- Output templates: 'HDR 보정', '자연광', '흰색 배경', '스튜디오 조명'

### Presigned URLs
- Mock R2 URLs: `https://mock-r2.example.com/...`
- Upload URLs: `https://mock-r2.example.com/upload/{jobId}/item-{idx}`
- Result URLs: `https://mock-r2.example.com/results/{jobId}/item-{idx}-result.jpg`
- Preview URLs: `https://mock-r2.example.com/results/{jobId}/item-{idx}-preview.jpg`

### Job Progression Simulation
- `_simulateJobProgress()` method simulates realistic job execution
- Status transitions: 'queued' → 'running' → 'done'
- Progress increments every 3 seconds
- outputsReady array populated incrementally

## Verification Status

✅ **All 13 endpoints implemented**
✅ **All return types match API contracts**
✅ **Realistic mock data with Korean text**
✅ **Network delay simulation (300ms)**
✅ **User has ruleSlots structure**
✅ **Job has progress with done/failed/total**
✅ **JobItem has idx, resultUrl, previewUrl**
✅ **Presigned URLs properly mocked**
✅ **Flutter analyze passes with zero errors**

## Static Analysis Result

```bash
$ flutter analyze lib/core/api/mock_api_client.dart
Analyzing mock_api_client.dart...
No issues found! (ran in 5.1s)
```

## Compliance with spec.md Pattern 5

✅ Implements ApiClient interface
✅ Returns hardcoded Freezed model instances
✅ Simulates network delay with Future.delayed(300ms)
✅ Uses realistic Korean text for preset names
✅ Mock presigned URLs follow pattern

## Next Steps

This MockApiClient enables immediate Phase 1 UI development without waiting for backend Workers API. To switch to real API in Phase 2:

1. Update `apiClientProvider` to return `S3ApiClient` instead of `MockApiClient`
2. Configure Workers API base URL
3. No changes needed to feature modules (they consume the abstract ApiClient interface)
