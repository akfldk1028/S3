$env:PYTHONUTF8 = "1"
$python = "C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe"
$script = "C:\DK\S3\clone\Auto-Claude\apps\backend\runners\daemon_runner.py"
$logFile = "C:\DK\S3\.auto-claude\daemon-debug2.log"

Write-Host "Starting daemon with full logging to: $logFile"
& $python -u $script `
    --project-dir "C:\DK\S3" `
    --status-file "C:\DK\S3\.auto-claude\daemon_status.json" `
    --use-worktrees `
    --use-claude-cli `
    --claude-cli-path "C:\Users\User\.local\bin\claude.exe" `
    *>&1 | Tee-Object -FilePath $logFile
