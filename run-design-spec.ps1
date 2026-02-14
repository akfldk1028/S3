$env:CLAUDECODE = $null
Remove-Item Env:\CLAUDECODE -ErrorAction SilentlyContinue
$env:PYTHONUTF8 = "1"

$python = "C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe"
$runner = "C:\DK\S3\clone\Auto-Claude\apps\backend\runners\spec_runner.py"

$task = @"
S3 MVP Full Implementation - Design Spec. workflow.md is the SSoT. Architecture: Workers(Hono+D1+DO+R2+Queues) + GPU Worker(Docker+SAM3+Runpod) + Frontend(Flutter+Riverpod3+Freezed3). Implement all 14 API endpoints, 2 Durable Objects, GPU pipeline, and Flutter app. Split into parallel child specs: (A) Workers foundation - D1 schema, Auth JWT, Presets API, Rules CRUD. (B) Workers advanced - UserLimiterDO, JobCoordinatorDO, Jobs routes, R2 presigned, Queue, Callback. (C) GPU Worker - SAM3 engine, rule applier, R2 IO, Runpod adapter. (D) Frontend - Freezed models, Mock API, Auth UI, Palette, Upload, Rules, Jobs progress, Results. Each child must use MCP tools. Read workflow.md, CLAUDE.md, and team/ guides for full context.
"@

& $python $runner --task $task --project-dir "C:\DK\S3" --no-build --task-type design
