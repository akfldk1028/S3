$env:CLAUDECODE = $null
Remove-Item Env:\CLAUDECODE -ErrorAction SilentlyContinue
$env:PYTHONUTF8 = "1"

# Kill existing daemon processes
$procs = Get-Process python* -ErrorAction SilentlyContinue
foreach ($p in $procs) {
    try {
        $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId = $($p.Id)").CommandLine
        if ($cmd -match "daemon_runner") {
            Write-Host "Killing daemon PID: $($p.Id)"
            Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        }
    } catch {}
}

Start-Sleep -Seconds 2

# Restart daemon with correct parameters
$python = "C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe"
$runner = "C:\DK\S3\clone\Auto-Claude\apps\backend\runners\daemon_runner.py"

Write-Host "Starting daemon..."
Start-Process -FilePath $python -ArgumentList @(
    $runner,
    "--project-dir", "C:\DK\S3",
    "--status-file", "C:\DK\S3\.auto-claude\daemon_status.json",
    "--use-worktrees",
    "--max-concurrent", "3",
    "--stuck-timeout", "900"
) -NoNewWindow -PassThru | Select-Object Id

Write-Host "Daemon restarted. Waiting for initialization..."
Start-Sleep -Seconds 5
Get-Content "C:\DK\S3\.auto-claude\daemon_status.json" -Raw
