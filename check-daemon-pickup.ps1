# Touch spec 006 to trigger daemon watchdog
(Get-Item 'C:\DK\S3\.auto-claude\specs\006-gpu-worker-sam3-segmenter\implementation_plan.json').LastWriteTime = Get-Date
Write-Host "Touched spec 006 at $(Get-Date)"

Start-Sleep -Seconds 10

$d = Get-Content 'C:\DK\S3\.auto-claude\daemon_status.json' -Raw | ConvertFrom-Json
Write-Host "Running: $($d.stats.running) | Queued: $($d.stats.queued) | Completed: $($d.stats.completed)"

foreach ($key in $d.running_tasks.PSObject.Properties.Name) {
    Write-Host "  RUNNING: $key"
}
foreach ($q in $d.queued_tasks) {
    Write-Host "  QUEUED: $($q.spec_id)"
}
