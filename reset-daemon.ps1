$ErrorActionPreference = "SilentlyContinue"

# 1. Remove ALL old worktrees
$worktrees = @(
    "C:\DK\S3\.auto-claude\worktrees\tasks\001-mvp-full-implementation-design",
    "C:\DK\S3\.auto-claude\worktrees\tasks\002-workers-foundation-schema-auth",
    "C:\DK\S3\.auto-claude\worktrees\tasks\003-workers-advanced-userlimiterdo-jobcoordinatordo",
    "C:\DK\S3\.auto-claude\worktrees\tasks\006-gpu-worker-sam3-segmenter",
    "C:\DK\S3\.auto-claude\worktrees\tasks\007-frontend-flutter-freezed-models"
)
foreach ($wt in $worktrees) {
    if (Test-Path $wt) {
        git -C "C:\DK\S3" worktree remove $wt --force 2>$null
        if (Test-Path $wt) { Remove-Item -Recurse -Force $wt }
        Write-Host "Removed worktree: $wt"
    }
}

# 2. Prune worktree references
git -C "C:\DK\S3" worktree prune
Write-Host "Worktree references pruned"

# 3. Clear daemon state - mark all as completed, reset errors
$state = "C:\DK\S3\.auto-claude\specs\.daemon_state.json"
$s = Get-Content $state -Raw | ConvertFrom-Json
$s.error_counts = @{}
$s.last_errors = @{}
$s.recovery_counts = @{}
$s.completed_tasks = @(
    "001-mvp-full-implementation-design",
    "002-workers-foundation-schema-auth",
    "003-workers-advanced-userlimiterdo-jobcoordinatordo",
    "006-gpu-worker-sam3-segmenter",
    "007-frontend-flutter-freezed-models"
)
$s | ConvertTo-Json -Depth 5 | Set-Content $state -Encoding UTF8
Write-Host "Daemon state cleared (all old tasks marked completed)"

# 4. Clear Python bytecode cache
Get-ChildItem -Path "C:\DK\S3\clone\Auto-Claude\apps\backend" -Recurse -Filter '__pycache__' -Directory | Remove-Item -Recurse -Force
Write-Host "Python __pycache__ cleared"

Write-Host ""
Write-Host "Done! Ready to start daemon with new specs."
