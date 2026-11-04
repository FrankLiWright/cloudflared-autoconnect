# Silently start every configured Cloudflare tunnel.

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\config.ps1"

foreach ($tunnel in $Config.Tunnels) {
    Start-Process -FilePath $Config.CloudflaredPath -ArgumentList @(
        'access', 'tcp',
        '--hostname', $tunnel.Hostname,
        '--url', $tunnel.LocalUrl
    ) -WindowStyle Hidden
}
