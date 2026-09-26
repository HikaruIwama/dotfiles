(&mise activate pwsh) | Out-String | Invoke-Expression
Invoke-Expression (&starship init powershell)

function docker {
    & wsl.exe --exec docker @args
}
