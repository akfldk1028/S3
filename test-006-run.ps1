$env:PYTHONUTF8 = "1"
$python = "C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe"
$run = "C:\DK\S3\clone\Auto-Claude\apps\backend\run.py"

Write-Host "=== Testing run.py for spec 006 ==="
Write-Host "Python: $python"
Write-Host ""

try {
    & $python -u $run --spec 006-gpu-worker-sam3-segmenter --project-dir "C:\DK\S3" --auto-continue --force 2>&1 | Select-Object -First 70
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "=== Exit Code: $LASTEXITCODE ==="
