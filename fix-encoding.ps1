$files = Get-ChildItem -Path "src/pages/Admin", "src/components/Admin" -Recurse -Filter "*.jsx"
foreach ($file in $files) {
    $badContent = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    try {
        $bytes = [System.Text.Encoding]::GetEncoding(1256).GetBytes($badContent)
        $goodContent = [System.Text.Encoding]::UTF8.GetString($bytes)
        [System.IO.File]::WriteAllText($file.FullName, $goodContent, (New-Object System.Text.UTF8Encoding($false)))
    } catch {
        Write-Host "Failed to decode $($file.FullName)"
    }
}
Write-Host "Done"
