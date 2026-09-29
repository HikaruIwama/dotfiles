$ErrorActionPreference = 'Stop'

$version = '3.1.0'
$archiveHash = 'f1a65b539ed8979f211ceaa6c7ad1123b7e0cc2eb00ab0df02fb2dcb0d6e7157'
$fontHashes = [ordered]@{
    Regular = 'ad26ee89f62d03a70d2e90230f635f2d306bad685331b1cfd5f3b73d09c398ca'
    Medium = '64f237e655523272893dcd86619d2855f188fc522e421a510e2d02d8339bbf2f'
    MediumItalic = '2eef50d3363b7b65bc94a244b4d517f356549ec74ceb177fb96682edba545bc8'
    Bold = 'a4711992ce95342b1ffd24b47ea698fcdda42a876a8a46bb8fca3e2417b9a9a4'
    Italic = 'b7f4aa6dacbe86241f4778eafe90a07e21c0b30852dbeb859203f96153342c79'
    BoldItalic = '01f2e4a4684e2cd73745b56ed96724c0779c220f513e1b23a5f0fc8b833b44a3'
}

if (-not $env:LOCALAPPDATA) { throw 'LOCALAPPDATA is not set' }
$fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$registryPath = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
$registry = Get-Item -Path $registryPath -ErrorAction SilentlyContinue
$missing = @()

foreach ($style in $fontHashes.Keys) {
    $fileName = "PlemolJPConsole-$style.ttf"
    $destination = Join-Path $fontDir $fileName
    $registrationName = "PlemolJP Console $style (TrueType)"
    $registeredPath = if ($registry) { $registry.GetValue($registrationName) } else { $null }
    if ($registeredPath -and [IO.Path]::GetFullPath($registeredPath) -ne $destination) {
        throw "Font is registered at a different path: $registrationName"
    }

    if (Test-Path -LiteralPath $destination) {
        $actualHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne $fontHashes[$style]) {
            throw "Existing font differs from PlemolJP v$version; inspect it before updating: $destination"
        }
    } else {
        $missing += $style
    }
}

if ($missing.Count -gt 0) {
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
    $tempDir = Join-Path $tempRoot ('plemoljp-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempDir -ErrorAction Stop | Out-Null
    try {
        $archivePath = Join-Path $tempDir "PlemolJP_v$version.zip"
        $uri = "https://github.com/yuru7/PlemolJP/releases/download/v$version/PlemolJP_v$version.zip"
        Invoke-WebRequest -Uri $uri -OutFile $archivePath -ErrorAction Stop
        $actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne $archiveHash) { throw 'PlemolJP archive checksum does not match' }

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
        try {
            foreach ($style in $missing) {
                $fileName = "PlemolJPConsole-$style.ttf"
                $entry = $archive.GetEntry("PlemolJP_v$version/PlemolJPConsole/$fileName")
                if (-not $entry) { throw "Font is missing from archive: $fileName" }
                $stagedPath = Join-Path $tempDir $fileName
                [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $stagedPath)
                $actualHash = (Get-FileHash -LiteralPath $stagedPath -Algorithm SHA256).Hash.ToLowerInvariant()
                if ($actualHash -ne $fontHashes[$style]) { throw "Font checksum does not match: $fileName" }
            }
        } finally {
            $archive.Dispose()
        }

        New-Item -ItemType Directory -Path $fontDir -Force -ErrorAction Stop | Out-Null
        foreach ($style in $missing) {
            $fileName = "PlemolJPConsole-$style.ttf"
            [IO.File]::Copy((Join-Path $tempDir $fileName), (Join-Path $fontDir $fileName), $false)
        }
    } finally {
        $resolvedTempDir = [IO.Path]::GetFullPath($tempDir)
        if (-not $resolvedTempDir.StartsWith($tempRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Unexpected temporary directory: $resolvedTempDir"
        }
        Remove-Item -LiteralPath $resolvedTempDir -Recurse -Force -ErrorAction Stop
    }
}

New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null
$registry = Get-Item -Path $registryPath -ErrorAction Stop
foreach ($style in $fontHashes.Keys) {
    $registrationName = "PlemolJP Console $style (TrueType)"
    if (-not $registry.GetValue($registrationName)) {
        $destination = Join-Path $fontDir "PlemolJPConsole-$style.ttf"
        New-ItemProperty -Path $registryPath -Name $registrationName -Value $destination -PropertyType String -ErrorAction Stop | Out-Null
    }
}

Write-Output "PlemolJP Console v$version is installed"
