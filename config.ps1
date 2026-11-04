# Configuration for cloudflared-autoconnect.
# Edit this file before running install.ps1.

$Config = @{
    # Path to the cloudflared executable.
    CloudflaredPath = 'C:\Program Files (x86)\cloudflared\cloudflared.exe'

    # Watchdog log file. Cleared never; trimmed manually if it grows.
    LogPath         = "$PSScriptRoot\watchdog.log"

    # Tunnels to keep alive. Each entry maps a Cloudflare-protected
    # hostname to a local TCP endpoint, exactly like:
    #   cloudflared access tcp --hostname <Hostname> --url <LocalUrl>
    Tunnels         = @(
        @{
            Hostname = 'ssh.example.com'
            LocalUrl = 'tcp://localhost:2222'
        }
    )
}
