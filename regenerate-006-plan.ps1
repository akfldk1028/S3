$env:PYTHONUTF8 = "1"
$python = "C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe"
$script = "C:\DK\S3\clone\Auto-Claude\apps\backend\runners\spec_runner.py"

# Continue existing spec (re-generate plan only since other files exist)
& $python -u $script `
    --spec-dir "C:\DK\S3\.auto-claude\specs\006-gpu-worker-sam3-segmenter" `
    --project-dir "C:\DK\S3" `
    --no-build `
    --auto-approve `
    2>&1
