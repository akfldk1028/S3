$env:PYTHONUTF8 = "1"

$pythonExe = "C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe"
$daemonScript = "C:\DK\S3\clone\Auto-Claude\apps\backend\runners\daemon_runner.py"

$args = @(
    "-u",
    $daemonScript,
    "--project-dir", "C:\DK\S3",
    "--status-file", "C:\DK\S3\.auto-claude\daemon_status.json",
    "--use-worktrees",
    "--use-claude-cli",
    "--claude-cli-path", "C:\Users\User\.local\bin\claude.exe"
)

Write-Host "Starting daemon..."
Write-Host "Python: $pythonExe"
Write-Host "Script: $daemonScript"

& $pythonExe @args
