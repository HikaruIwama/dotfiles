param([switch]$Verify)

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$configPath = Join-Path $root 'mise.toml'
$homePrefix = [IO.Path]::GetFullPath($env:USERPROFILE).TrimEnd([char[]]@('\', '/')) + '\'
$rootPrefix = [IO.Path]::GetFullPath($root).TrimEnd([char[]]@('\', '/')) + '\'

$statusJson = & mise dotfiles status --json
if ($LASTEXITCODE -ne 0) { throw 'mise dotfiles status failed' }
$status = $statusJson | Out-String | ConvertFrom-Json
$entries = @($status.files | Where-Object {
    $_.mode -eq 'symlink' -and
    [IO.Path]::GetFullPath($_.origin.config).Equals($configPath, [StringComparison]::OrdinalIgnoreCase)
})
if ($entries.Count -eq 0) { throw 'No symlink dotfiles found in this repository' }

if (-not $Verify) {
    $probe = Join-Path $env:TEMP ('.dotfiles-link-probe-' + [guid]::NewGuid().ToString('N'))
    try {
        $link = New-Item -ItemType SymbolicLink -Path $probe -Target $configPath -ErrorAction Stop
        if ($link.LinkType -ne 'SymbolicLink') { throw 'Windows did not create a symbolic link' }
    } finally {
        if (Test-Path -LiteralPath $probe) { Remove-Item -LiteralPath $probe -Force }
    }
}

foreach ($entry in $entries) {
    $target = if ($entry.target.StartsWith('~/')) {
        Join-Path $env:USERPROFILE $entry.target.Substring(2)
    } else {
        $entry.target
    }
    $target = [IO.Path]::GetFullPath($target)
    $source = [IO.Path]::GetFullPath($entry.source)
    if (-not $target.StartsWith($homePrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Dotfile target is outside the user profile: $target"
    }
    if (-not $source.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Dotfile source is outside this repository: $source"
    }

    if (-not (Test-Path -LiteralPath $target -ErrorAction Stop)) {
        if ($Verify) { throw "Dotfile target is missing: $target" }
        continue
    }
    $item = Get-Item -LiteralPath $target -Force -ErrorAction Stop
    if ($item.LinkType -in @('SymbolicLink', 'Junction')) {
        if ($entry.state -ne 'applied') { throw "Dotfile link differs from its source: $target" }
        continue
    }
    if ($Verify) { throw "Dotfile is a copy, not a link: $target" }
    if ($item.PSIsContainer) { throw "Existing dotfile directory is not a link: $target" }
    if ((Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath $source).Hash) {
        throw "Existing dotfile differs from its source; inspect and move it aside: $target"
    }

    $backup = "$target.before-symlink-$([guid]::NewGuid().ToString('N')).bak"
    Move-Item -LiteralPath $target -Destination $backup -ErrorAction Stop
    try {
        $link = New-Item -ItemType SymbolicLink -Path $target -Target $source -ErrorAction Stop
        if ($link.LinkType -ne 'SymbolicLink' -or
            (Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath $source).Hash) {
            throw "Failed to verify dotfile link: $target"
        }
        Remove-Item -LiteralPath $backup -Force -ErrorAction Stop
        Write-Output "Linked $target"
    } catch {
        if (Test-Path -LiteralPath $target) {
            $created = Get-Item -LiteralPath $target -Force
            if ($created.LinkType -ne 'SymbolicLink') {
                throw "Unexpected target after failed link; original preserved at $backup"
            }
            Remove-Item -LiteralPath $target -Force
        }
        Move-Item -LiteralPath $backup -Destination $target -ErrorAction Stop
        throw
    }
}

if ($Verify) { Write-Output "Verified $($entries.Count) dotfile links" }
