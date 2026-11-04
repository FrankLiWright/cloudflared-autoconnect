# Register the scheduled tasks that auto-start and keep alive the
# configured Cloudflare tunnels. Run from an elevated PowerShell.

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$startScript = Join-Path $root 'scripts\start.ps1'
$watchdogScript = Join-Path $root 'scripts\watchdog.ps1'

if (-not (Test-Path $startScript) -or -not (Test-Path $watchdogScript)) {
    throw "Scripts not found under $root\scripts. Run this from the repository root."
}

$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest

# 1. Start tunnels once at boot, hidden.
$startAction = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$startScript`""
$startTrigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName 'CloudflareTunnels' -Action $startAction `
    -Trigger $startTrigger -Principal $principal -Force | Out-Null

# 2. Watchdog: every 5 minutes, restart tunnels that died.
$watchdogAction = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$watchdogScript`""
$watchdogTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date `
    -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
Register-ScheduledTask -TaskName 'CloudflareTunnelWatchdog' -Action $watchdogAction `
    -Trigger $watchdogTrigger -Principal $principal -Force | Out-Null

# Launch right now so the tunnels come up without a reboot.
& $startScript

Write-Host 'Installed:'
Write-Host '  CloudflareTunnels        - starts tunnels at boot'
Write-Host '  CloudflareTunnelWatchdog - restarts dead tunnels every 5 minutes'
