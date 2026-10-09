$ErrorActionPreference = 'Stop'

Set-Location -LiteralPath $PSScriptRoot

$importFile = Join-Path $PSScriptRoot 'winget/packages.json'
$miseLink = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\mise.exe'
$miseRunning = @(Get-Process mise -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $miseLink }).Count -gt 0

try {
    if ($miseRunning) {
        $packages = Get-Content -LiteralPath $importFile -Raw | ConvertFrom-Json
        foreach ($source in $packages.Sources) {
            $source.Packages = @($source.Packages | Where-Object { $_.PackageIdentifier -ne 'jdx.mise' })
        }
        $temporaryImport = Join-Path ([System.IO.Path]::GetTempPath()) ("winget-$([guid]::NewGuid().ToString('N')).json")
        [System.IO.File]::WriteAllText($temporaryImport, ($packages | ConvertTo-Json -Depth 10), (New-Object System.Text.UTF8Encoding($false)))
        $importFile = $temporaryImport
        Write-Warning 'mise is in use, so its upgrade was skipped. Close programs launched through mise and rerun install.ps1 to upgrade it.'
    }

    winget import -i $importFile --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw 'winget import failed' }
} finally {
    if ($temporaryImport) { Remove-Item -LiteralPath $temporaryImport }
}

# winget adds commands to PATH only in the registry; reload it so this session finds mise and pwsh
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

mise trust
if ($LASTEXITCODE -ne 0) { throw 'mise trust failed' }
mise bootstrap
if ($LASTEXITCODE -ne 0) { throw 'mise bootstrap failed' }
