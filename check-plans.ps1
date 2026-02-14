$specsDir = "C:\DK\S3\.auto-claude\specs"
foreach ($dir in Get-ChildItem $specsDir -Directory) {
    $planFile = Join-Path $dir.FullName "implementation_plan.json"
    if (Test-Path $planFile) {
        $size = (Get-Item $planFile).Length
        Write-Host ("{0}: {1} bytes" -f $dir.Name, $size)

        # Try reading as UTF-8 to detect encoding issues
        try {
            $content = [System.IO.File]::ReadAllText($planFile, [System.Text.Encoding]::UTF8)
            $json = $content | ConvertFrom-Json
            Write-Host ("  status: {0}, planStatus: {1}" -f $json.status, $json.planStatus)
        } catch {
            Write-Host ("  ERROR: {0}" -f $_.Exception.Message)
            # Show first 100 bytes as hex
            $bytes = [System.IO.File]::ReadAllBytes($planFile)
            $hex = ($bytes[0..([Math]::Min(99, $bytes.Length-1))] | ForEach-Object { $_.ToString("X2") }) -join " "
            Write-Host ("  First bytes: {0}" -f $hex)
        }
    }
}
