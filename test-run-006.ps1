$env:PYTHONUTF8 = "1"
$pythonExe = "C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe"
$runPy = "C:\DK\S3\clone\Auto-Claude\apps\backend\run.py"

Write-Host "Running 006 manually..."
& $pythonExe -u $runPy --spec 006-gpu-worker-sam3-segmenter --project-dir "C:\DK\S3" --auto-continue --force 2>&1 | Tee-Object -FilePath "C:\DK\S3\run-006-output.log"
Write-Host "Exit code: $LASTEXITCODE"
