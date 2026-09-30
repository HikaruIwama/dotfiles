(&mise activate pwsh) | Out-String | Invoke-Expression

# Lets gitoxide in starship find Git for Windows without spawning git on every prompt
if (-not $env:EXEPATH -and (Test-Path -LiteralPath "$env:ProgramFiles\Git\etc\gitconfig")) {
    $env:EXEPATH = "$env:ProgramFiles\Git"
}

# The init script embeds the starship path, so regenerate it only when that path changes
$starship = (Get-Command starship -CommandType Application -TotalCount 1).Source
$starshipInit = Join-Path $HOME '.cache\starship\init.ps1'
if (-not (Select-String -LiteralPath $starshipInit -SimpleMatch $starship -Quiet -ErrorAction Ignore)) {
    New-Item -ItemType Directory -Force -Path (Split-Path $starshipInit) | Out-Null
    & $starship init powershell --print-full-init | Set-Content -LiteralPath $starshipInit
}
. $starshipInit
Remove-Variable starship, starshipInit

Set-Alias -Name vim -Value nvim

function Invoke-Starship-PreCommand {
    $location = $executionContext.SessionState.Path.CurrentLocation
    if ($location.Provider.Name -eq 'FileSystem') {
        $path = $location.ProviderPath -replace '\\', '/'
        $host.UI.Write("`e]7;file://$env:COMPUTERNAME/$path`e\")
    }
}

function docker {
    & wsl.exe --exec docker @args
}
