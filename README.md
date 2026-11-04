# cloudflared-autoconnect

Auto-start and keep-alive for [`cloudflared`](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) tunnels on Windows.

Run `cloudflared access tcp` at boot with no visible window, and a watchdog that silently restarts the tunnel if it dies. Built for the common case of mapping a Cloudflare Access–protected SSH (or any TCP) host to a local port:

```
ssh.revecloud.top  ->  tcp://localhost:2222
```

so you can simply `ssh -p 2222 user@localhost` and never think about the tunnel again.

## How it works

Two Windows scheduled tasks, both running as `SYSTEM` with the highest privileges and hidden windows:

| Task | Trigger | Action |
| --- | --- | --- |
| `CloudflareTunnels` | At system startup | `scripts/start.ps1` — launches every configured tunnel |
| `CloudflareTunnelWatchdog` | Every 5 minutes | `scripts/watchdog.ps1` — restarts any tunnel whose process is gone |

The watchdog matches running `cloudflared.exe` processes by command line (i.e. by hostname), so it only ever restarts the tunnels it owns and never touches other cloudflared instances on the machine.

## Requirements

- Windows 10/11 or Windows Server
- [`cloudflared`](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) installed
- A Cloudflare Access–protected hostname whose tunnel serves TCP (e.g. SSH)

## Install

1. Clone the repository:

   ```powershell
   git clone https://github.com/FrankLiWright/cloudflared-autoconnect.git
   cd cloudflared-autoconnect
   ```

2. Edit `config.ps1` — set the cloudflared path and your tunnels:

   ```powershell
   $Config = @{
       CloudflaredPath = 'C:\Program Files (x86)\cloudflared\cloudflared.exe'
       LogPath         = "$PSScriptRoot\watchdog.log"
       Tunnels         = @(
           @{ Hostname = 'ssh.example.com'; LocalUrl = 'tcp://localhost:2222' }
       )
   }
   ```

   Add as many entries to `Tunnels` as you need. Each one runs as
   `cloudflared access tcp --hostname <Hostname> --url <LocalUrl>`.

3. From an **elevated** PowerShell (Run as administrator):

   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass -Force
   .\install.ps1
   ```

   This registers both scheduled tasks and starts the tunnels immediately — no reboot needed.

## Verify

```powershell
Get-ScheduledTask -TaskName 'CloudflareTunnels','CloudflareTunnelWatchdog'
Get-Process cloudflared
Get-Content .\watchdog.log -Tail 10
```

Healthy output looks like:

```
2026-11-04 21:25:02 Tunnel ssh.example.com OK.
```

Then connect through the tunnel:

```powershell
ssh -p 2222 user@localhost
```

## Uninstall

From an elevated PowerShell:

```powershell
.\uninstall.ps1
```

Removes both scheduled tasks and stops only the tunnels this tool started. It does **not** uninstall `cloudflared`; do that separately (Settings → Apps, or `winget uninstall cloudflared`) if you want it gone too. Delete the repository folder afterwards if you no longer need it.

## Notes

- The watchdog log (`watchdog.log`) grows by one line every 5 minutes (~100 MB/year). Delete or rotate it occasionally.
- Everything runs hidden: no console windows, no tray icons.
- If a tunnel needs a Cloudflare Access login (`cloudflared access login`), complete that step once first; the token is cached per user and the SYSTEM task will not prompt for it.

## License

[MIT](LICENSE)
