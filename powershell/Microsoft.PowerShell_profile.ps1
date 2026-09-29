(&mise activate pwsh) | Out-String | Invoke-Expression
Invoke-Expression (&starship init powershell)

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
