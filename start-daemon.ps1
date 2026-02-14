$env:PYTHONUTF8 = "1"

$python = "C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe"
$script = "C:\DK\S3\clone\Auto-Claude\apps\backend\runners\daemon_runner.py"

$proc = Start-Process -FilePath $python -ArgumentList @(
    "-u",
    $script,
    "--project-dir", "C:\DK\S3",
    "--status-file", "C:\DK\S3\.auto-claude\daemon_status.json",
    "--use-worktrees",
    "--use-claude-cli",
    "--claude-cli-path", "C:\Users\User\.local\bin\claude.exe"
) -WindowStyle Hidden -PassThru

Write-Host "Daemon started with PID: $($proc.Id)"

Start-Sleep -Seconds 20
$status = Get-Content "C:\DK\S3\.auto-claude\daemon_status.json" -Raw | ConvertFrom-Json
Write-Host "`nDaemon Status after 20s:"
Write-Host "  Running: $($status.running)"
Write-Host "  Running tasks: $($status.stats.running)"
Write-Host "  Queued tasks: $($status.stats.queued)"
Write-Host "  Completed: $($status.stats.completed)"
Write-Host "  Timestamp: $($status.timestamp)"

if ($status.running_tasks.PSObject.Properties.Count -gt 0) {
    Write-Host "`nRunning tasks:"
    foreach ($prop in $status.running_tasks.PSObject.Properties) {
        Write-Host "  - $($prop.Name): $($prop.Value.status)"
    }
}
