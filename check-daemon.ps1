$procs = Get-Process python* -ErrorAction SilentlyContinue
foreach ($p in $procs) {
    $cmd = ""
    try { $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId = $($p.Id)").CommandLine } catch {}
    if ($cmd -match "daemon_runner") {
        Write-Host "DAEMON PID: $($p.Id) Started: $($p.StartTime)"
        Write-Host "CMD: $cmd"
    }
}
