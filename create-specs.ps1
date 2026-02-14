$env:CLAUDECODE = $null
Remove-Item Env:\CLAUDECODE -ErrorAction SilentlyContinue
$env:PYTHONUTF8 = "1"

$python = "C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe"
$runner = "C:\DK\S3\clone\Auto-Claude\apps\backend\runners\spec_runner.py"
$proj = "C:\DK\S3"

Write-Host "=== SPEC 1/4: Workers Foundation ==="
& $python $runner --task @"
Workers Foundation: D1 Schema + Auth JWT + Presets API + Rules CRUD.

SSoT: workflow.md (sections 5.3, 6.1-6.4, 9). Reference: team/MEMBER-A-WORKERS-CORE.md, CLAUDE.md.

Scope:
- D1 migrations: 5 tables (users, rules, jobs_log, job_items_log, billing_events) per workflow.md Section 5.3
- JWT utilities: HS256 sign/verify using Workers env JWT_SECRET (hono/jwt)
- Auth middleware: verify Bearer token, extract sub=user_id
- POST /auth/anon: create anonymous user in D1, return JWT
- GET /me: return user state from UserLimiterDO (stub DO call for now)
- GET /presets: hardcoded interior + seller domain presets
- GET /presets/:id: preset detail with concepts, protect, templates
- POST/GET/PUT/DELETE /rules: CRUD with D1, user_id from JWT

Tech: Hono on CF Workers, D1 (SQLite), wrangler.toml bindings.
Directory: workers/src/ (auth/, presets/, rules/, middleware/, services/, utils/)
Critical: NO Supabase. NO plan in JWT. Response envelope {success, data, error, meta}.
MCP: Use context7 for Hono/CF Workers docs. Use cloudflare-observability for debugging.
"@ --project-dir $proj --no-build
Write-Host ""

Write-Host "=== SPEC 2/4: Workers Advanced ==="
& $python $runner --task @"
Workers Advanced: UserLimiterDO + JobCoordinatorDO + Jobs API + R2 Presigned + Queue + Callback.

SSoT: workflow.md (sections 5.1-5.2, 6.5, 7). Reference: team/MEMBER-B-WORKERS-DO.md, CLAUDE.md.
Depends on: Workers Foundation (D1 schema, auth middleware, types.ts).

Scope:
- UserLimiterDO: per-user singleton. Credits reserve/commit/rollback. Concurrency limit (free=1, pro=3). Rule slot limit (free<=2, pro<=20). SQLite storage in DO.
- JobCoordinatorDO: per-job singleton. State machine: created->uploaded->queued->running->done/failed/canceled. Item-level tracking. Idempotency via seen_keys RingBuffer. Progress tracking (done/failed/total).
- POST /jobs: create job, reserve credits via UserLimiterDO, generate R2 presigned URLs (AWS SDK with S3 domain, NOT Workers API)
- POST /jobs/:id/confirm-upload: mark uploaded in JobCoordinatorDO
- POST /jobs/:id/execute: push to CF Queue with concepts/protect/rule, mark queued
- GET /jobs/:id: return status/progress from JobCoordinatorDO
- POST /jobs/:id/callback: GPU Worker callback, validate GPU_CALLBACK_SECRET, update item status, idempotency check
- POST /jobs/:id/cancel: cancel job, rollback credits via UserLimiterDO
- GET /me: return user state (credits, plan, active_jobs, rule_slots) from UserLimiterDO
- D1 flush: batch write to jobs_log/job_items_log on job completion

Tech: Hono, Durable Objects, CF Queues, R2 presigned (AWS SDK), wrangler.toml DO/Queue bindings.
Directory: workers/src/ (do/, jobs/, user/)
Critical: Credits never go negative. Callback idempotency. DO = realtime state, D1 = persistence.
MCP: Use context7 for CF DO/Queue docs. Use cloudflare-observability for DO debugging.
"@ --project-dir $proj --no-build
Write-Host ""

Write-Host "=== SPEC 3/4: GPU Worker ==="
& $python $runner --task @"
GPU Worker: SAM3 Segmenter + Rule Applier + R2 I/O + Runpod Serverless Adapter.

SSoT: workflow.md (sections 7, 8). Reference: team/MEMBER-C-GPU.md, CLAUDE.md.
No dependencies - can start immediately.

Scope:
- engine/segmenter.py: SAM3 wrapper. Load facebook/sam3-base model. Input: image + concept texts -> output: per-concept instance masks + instances.json metadata.
- engine/applier.py: Rule applier. Input: image + masks + rules (recolor/tone/texture/remove) -> output: result images. Apply rules per-concept using masks.
- engine/r2_io.py: boto3 S3-compatible. Download inputs/{userId}/{jobId}/{idx}.jpg from R2. Upload outputs, masks, previews to R2 with correct key patterns.
- engine/callback.py: POST to Workers /jobs/{id}/callback per item. Include idx, status, output_key, preview_key, error, idempotency_key. Auth: GPU_CALLBACK_SECRET header.
- engine/pipeline.py: Orchestrator. Stage 1: segment all concepts -> Stage 2: apply rules -> upload results -> callback per item.
- adapters/runpod_serverless.py: Runpod handler. Receive job from queue, run pipeline, return results.
- presets/: Domain concept mappings (interior concepts, seller concepts).
- main.py: Entry point for Runpod serverless.
- Dockerfile: CUDA 12.1+ runtime, PyTorch 2.7+, SAM3 dependencies, model cache at /models.

Tech: Python 3.12, PyTorch 2.7+, SAM3 (848M params, 3.4GB weights), boto3, Docker, Runpod Serverless.
Directory: gpu-worker/ (engine/, adapters/, presets/)
Critical: 2-stage pipeline (segment then apply). Model weights NOT committed. HuggingFace Hub download.
MCP: Use context7 for PyTorch/SAM3 docs.
"@ --project-dir $proj --no-build
Write-Host ""

Write-Host "=== SPEC 4/4: Frontend Flutter ==="
& $python $runner --task @"
Frontend Flutter: Freezed Models + Mock API + Auth + Palette + Upload + Rules + Jobs + Results.

SSoT: workflow.md (section 6 API contracts). Reference: team/MEMBER-D-FRONTEND.md, CLAUDE.md.
Can start immediately with Mock API. Switch to real API after Workers specs complete.

Scope:
- core/models/: Freezed 3 models - User, Preset, Rule, Job, JobProgress, JobItem. All with fromJson/toJson.
- core/api/api_client.dart: Abstract ApiClient interface for all 14 endpoints.
- core/api/mock_api_client.dart: Mock implementation returning hardcoded data. Phase 1 development.
- core/api/s3_api_client.dart: Real Dio-based implementation. JWT Bearer token in interceptor. Phase 2.
- core/auth/: Riverpod 3 auth provider. POST /auth/anon on first launch. JWT stored in flutter_secure_storage.
- core/router/app_router.dart: GoRouter with auth guard.
- features/auth/: Auto anonymous login screen.
- features/domain_select/: GET /presets -> domain cards (interior/seller).
- features/palette/: Concept chips, instance cards, protect toggles. Local state only.
- features/upload/: Image picker -> POST /jobs -> presigned URLs -> R2 direct PUT upload -> confirm-upload.
- features/rules/: Rule editor (concept actions: recolor/tone/texture/remove). POST/GET/PUT/DELETE /rules.
- features/jobs/: Job progress screen. Polling GET /jobs/:id every 3 seconds. Progress bar done/total.
- features/results/: Before/After comparison. Gallery grid. Download button.
- shared/theme/: ShadcnUI theme. app_theme.dart.

Tech: Flutter 3.38.9, Riverpod 3 (@riverpod annotation), Freezed 3, GoRouter, Dio, ShadcnUI.
Directory: frontend/lib/ (core/, features/, shared/)
Critical: NO Supabase SDK. All communication via Workers REST API. Dio + JWT only.
MCP: Use dart MCP for code analysis. Use context7 for Riverpod/Freezed/Flutter docs.
"@ --project-dir $proj --no-build
Write-Host ""

Write-Host "=== ALL 4 SPECS CREATED ==="
Write-Host "Daemon will auto-pickup and execute in parallel (max 3 concurrent)."
