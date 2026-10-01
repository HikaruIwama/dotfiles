$ErrorActionPreference = 'Stop'

Set-Location -LiteralPath $PSScriptRoot

winget import -i winget/packages.json --no-upgrade --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0) { throw 'winget import failed' }

# winget adds commands to PATH only in the registry; reload it so this session finds mise and pwsh
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

mise trust
if ($LASTEXITCODE -ne 0) { throw 'mise trust failed' }
mise bootstrap
if ($LASTEXITCODE -ne 0) { throw 'mise bootstrap failed' }
