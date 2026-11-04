# Remove the scheduled tasks and stop the tunnels created by install.ps1.
# Run from an elevated PowerShell. Does not uninstall cloudflared itself.

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\config.ps1"

foreach ($name in 'CloudflareTunnels', 'CloudflareTunnelWatchdog') {
    $task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName $name -Confirm:$false
        Write-Host "Removed scheduled task $name"
    }
}

Get-Process -Name 'cloudflared' -ErrorAction SilentlyContinue | ForEach-Object {
    $proc = $_
    $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.Id)").CommandLine
    $ours = $Config.Tunnels | Where-Object { $cmdLine -match [regex]::Escape($_.Hostname) }
    if ($ours) {
        Stop-Process -Id $proc.Id -Force
        Write-Host "Stopped cloudflared (PID $($proc.Id))"
    }
}

Write-Host 'Done. Remove the repository folder manually if no longer needed.'
