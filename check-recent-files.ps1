$cutoff = Get-Date '2026-02-14 14:00'
$files = Get-ChildItem 'C:\DK\S3\workers' -Recurse -File | Where-Object { $_.LastWriteTime -gt $cutoff }
if ($files) {
    $files | Sort-Object LastWriteTime -Descending | Select-Object LastWriteTime,FullName | Format-Table -AutoSize
} else {
    Write-Host "No files modified after $cutoff in workers/"
}

Write-Host "`n--- Build progress files ---"
$specs = Get-ChildItem 'C:\DK\S3\.auto-claude\specs' -Directory
foreach ($s in $specs) {
    $bp = Join-Path $s.FullName "build-progress.txt"
    if (Test-Path $bp) {
        $lines = (Get-Content $bp).Count
        $lastMod = (Get-Item $bp).LastWriteTime
        Write-Host "$($s.Name): $lines lines, last modified $lastMod"
    }
}
