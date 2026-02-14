$env:CLAUDECODE = $null
Remove-Item Env:\CLAUDECODE -ErrorAction SilentlyContinue
Set-Location "C:\DK\S3\clone\Auto-Claude"
npm run dev:mcp
