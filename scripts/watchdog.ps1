# Restart any configured Cloudflare tunnel that is not running.
# Intended to be run on a schedule by the CloudflareTunnelWatchdog task.

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\config.ps1"

function Write-Log([string]$Message) {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$timestamp $Message" | Out-File -Append -FilePath $Config.LogPath
}

$processes = Get-CimInstance Win32_Process -Filter "Name='cloudflared.exe'" -ErrorAction SilentlyContinue

foreach ($tunnel in $Config.Tunnels) {
    $running = $processes | Where-Object { $_.CommandLine -match [regex]::Escape($tunnel.Hostname) }
    if ($running) {
        Write-Log "Tunnel $($tunnel.Hostname) OK."
        continue
    }

    Write-Log "Tunnel $($tunnel.Hostname) not running, restarting..."
    Start-Process -FilePath $Config.CloudflaredPath -ArgumentList @(
        'access', 'tcp',
        '--hostname', $tunnel.Hostname,
        '--url', $tunnel.LocalUrl
    ) -WindowStyle Hidden
    Write-Log "Tunnel $($tunnel.Hostname) restarted."
}
