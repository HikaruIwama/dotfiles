$ErrorActionPreference = 'Stop'

$MISE_SHIMS = '%LOCALAPPDATA%\mise\shims'

# Read and write the registry directly to keep entries like %USERPROFILE% unexpanded
$userPath = (Get-Item -Path 'HKCU:\Environment').GetValue('Path', '', 'DoNotExpandEnvironmentNames')
$entries = @($userPath -split ';' | Where-Object { $_ })
$expandedShims = [Environment]::ExpandEnvironmentVariables($MISE_SHIMS)
$hasShims = $entries | Where-Object { [Environment]::ExpandEnvironmentVariables($_) -eq $expandedShims }

if (-not $hasShims) {
    Set-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value ((@($MISE_SHIMS) + $entries) -join ';') -Type ExpandString

    # Notify running applications (Explorer, etc.) that environment variables changed
    Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
    $result = [UIntPtr]::Zero
    [void][Win32.NativeMethods]::SendMessageTimeout([IntPtr]0xffff, 0x1a, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result)
}
