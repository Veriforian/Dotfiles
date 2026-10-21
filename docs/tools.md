# Tools

[← README](../README.md) · Last updated: 2026-10-21

## git (`~/.config/git/config`)

Omarchy default plus a `[user]` block (name + work email).
Gap: the email is hardcoded and doesn't use the per-machine `email` prompt (see [machines](machines.md#known-gaps)).

## SSH agent (git, lazygit)

Goal: type the key passphrase once per login, not on every commit, pull or push.

| Piece                                           | Source                                               | Does                                                                                                |
| ----------------------------------------------- | ---------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `ssh-agent.socket` (systemd user unit, OpenSSH) | enabled by `run_onchange_after_50-ssh-agent.sh.tmpl` | One agent per login at `$XDG_RUNTIME_DIR/ssh-agent.socket`, started on first use                    |
| `~/.config/environment.d/10-ssh-agent.conf`     | `dot_config/environment.d/`                          | `SSH_AUTH_SOCK` for apps launched from Hyprland (takes effect after the next login)                 |
| `~/.bashrc`                                     | `dot_bashrc`                                         | Same `SSH_AUTH_SOCK` default for shells. The first terminal with an empty agent runs `ssh-add` once |
| `~/.ssh/config`                                 | `private_dot_ssh/private_config`                     | `AddKeysToAgent yes`: if the key isn't loaded, the first git/ssh use asks once and caches it. Per-host keys (below) |

- Keys (`~/.ssh/id_*`) are **not** in chezmoi. Copy or generate them per machine.
- **Two keys:** `id_ed25519` (personal, passphrase, GitHub and everything else) and `id_gitlab_ed25519` (work GitLab,
  no passphrase). `Host gitlab.com` uses only the GitLab key (`IdentitiesOnly yes`), so GitLab works without the
  agent and never asks for the personal key's passphrase. `Host * !gitlab.com` gets the personal key. Check:
  `ssh -G gitlab.com | grep identityfile`, `ssh -T git@gitlab.com` → "Welcome to GitLab".
- `Ctrl+C` at the terminal prompt skips it. The next git operation (lazygit too) asks once instead.
- Keys stay loaded until logout. `ssh-add -l` lists them, `ssh-add -D` forgets them.
- Alternative not used: `gcr-ssh-agent` (GNOME keyring) can store the passphrase so you're never asked, similar to macOS
  `UseKeychain`. It's not used here because this setup is meant to ask once per login.

## Work VPN (WireGuard)

Split tunnel to specific work IPs (the `AllowedIPs` in the work config).

- **Package:** `wireguard-tools` (`wg`, `wg-quick`; official repo, any arch). The kernel module is built in.
- **Way of running it: NetworkManager.** It has WireGuard built in, gives a GUI/`nmcli` toggle, sends the config's DNS to
  systemd-resolved, and adds routes only for `AllowedIPs`. `wg-quick` is the fallback.
- **Secrets:** the `.conf` holds `PrivateKey`. Never commit it or put it under the chezmoi source. After importing,
  NetworkManager keeps it in `/etc/NetworkManager/system-connections/<name>.nmconnection` (root, mode 600), so the
  downloaded file can be deleted.

**Import once per machine:**
```bash
nmcli connection import type wireguard file ~/Downloads/work.conf   # connection + interface named "work"
#   the file name (minus .conf) becomes the interface name: ≤15 chars, letters/digits/-/_
nmcli connection modify work connection.autoconnect no              # only connect when asked
nmcli connection modify work wireguard.mtu 1280                      # nested inside Mullvad (MTU 1380)
nmcli connection modify work ipv4.dns "" ipv4.dns-search "" ipv4.ignore-auto-dns yes   # see "alongside Mullvad"
nmcli connection up work                                             # re-up to apply
rm ~/Downloads/work.conf                                             # NM has its own copy now
```
If nmcli says *not authorized*, prefix it with `sudo`.

**Use:**
```bash
nmcli connection up work      # connect
nmcli connection down work    # disconnect
sudo wg show                  # handshake time + transfer: is the tunnel alive?
ip route get <work-ip>        # should say "dev work"
resolvectl status work        # DNS servers from the config, if it has a DNS = line
```

**DNS:** if the config has `DNS =` and `AllowedIPs` isn't `0.0.0.0/0`, resolved can still send *all* lookups to the work
DNS server. To send only work names there, set a routing domain:
`nmcli connection modify work ipv4.dns-search "~corp.example.com"` (use the company's domain), then reconnect.

### Work VPN alongside Mullvad

Both stay connected. All traffic goes through Mullvad, work IPs go through `work`, and the work tunnel's own encrypted
UDP (to `vpn.trazidev.com:51820`) travels **inside** Mullvad.

| Piece | What it does |
|---|---|
| Routing (already fine) | Mullvad's rule `32764: lookup main suppress_prefixlength 0` lets the specific `dev work` routes in `main` beat Mullvad's default. The work endpoint has no such route, so it falls through to Mullvad's table (`ip route get 67.202.52.255` → `dev wg0-mullvad`). More specific routes (`10.64.0.1` Mullvad DNS, `10.0.2.0/24` VM LAN) still beat work's `10.0.0.0/8` |
| **Firewall** (`run_onchange_after_55-work-vpn-mullvad`) | Mullvad's firewall drops traffic leaving through any other interface (seen as TX errors on `work`). The script installs `/etc/NetworkManager/dispatcher.d/50-mullvad-allow-work` (sudo). On `work` up it loads `table inet mullvad-allow-work`: packets with `oifname "work"` get Mullvad's [documented split-tunnel marks](https://mullvad.net/en/help/split-tunneling-with-linux-advanced) (`ct mark 0x00000f41` to pass the firewall, also for replies; `meta mark 0x6d6f6c65` for the main table, so still `dev work`). On down it deletes the table |
| **MTU 1280** (NM connection) | `work` defaulted to 1420 but runs inside Mullvad's 1380. WireGuard adds 60–80 bytes, so large packets were lost |
| **No work DNS** (NM connection) | The config's `DNS = 1.1.1.1` made `work` a second catch-all DNS route (`~.`). Mullvad blocks DNS to anything but its own resolver, so lookups sent there timed out. 1.1.1.1 is public, so work needs no DNS of its own; Mullvad's resolver answers everything. If a future config has *internal* DNS, give it a routing domain instead: `ipv4.dns-search "~corp.example.com"` |

The MTU and DNS settings live in the NetworkManager connection (it holds the private key, so it isn't in chezmoi).
They're part of the import steps above.

**Check:**
```bash
sudo nft list table inet mullvad-allow-work     # loaded while work is up
ip -s link show work                            # TX errors stop increasing
ip route get <work-ip>                          # dev work
ip route get 67.202.52.255                      # dev wg0-mullvad (work tunnel inside Mullvad)
resolvectl dns work                             # empty
curl -s https://am.i.mullvad.net/connected      # "You are connected to Mullvad"
```

**Interface name:** the dispatcher script expects the interface to be called `work` (the import file name). For another
name, change `iface=` in `run_onchange_after_55-work-vpn-mullvad.sh.tmpl` and `chezmoi apply`.

**Without the Mullvad app:** plain Mullvad WireGuard configs in NetworkManager (what you used before) have no firewall,
so they coexist with no extra rules. You'd lose the app's kill switch, relay picker, quantum-resistant tunnels and DAITA.

**Fallback, `wg-quick`:**
`sudo install -m 600 work.conf /etc/wireguard/work.conf && sudo wg-quick up work` (`down` to stop).
For it at boot: `sudo systemctl enable --now wg-quick@work`. Don't run both NM and wg-quick for the same tunnel.

## Docker and Mullvad

With the Mullvad app connected (local network sharing off), its firewall drops traffic to private ranges, which
includes Docker's bridges. Published ports (`-p 127.0.0.1:5432:5432`) refuse connections, and containers have no
internet.

- **Fix:** `run_onchange_after_56-docker-mullvad` installs `/etc/mullvad-allow-docker.nft`, loaded at boot by
  `mullvad-allow-docker.service` (sudo once):
  - **VM ↔ containers** (published ports, container DNS at `172.17.0.1`, container ↔ container across networks) get
    Mullvad's firewall mark `ct mark 0x00000f41`.
  - **Container → internet is not marked.** Mullvad already lets it out through the tunnel. A mark would route it
    *around* the tunnel: Mullvad's prerouting turns `ct mark 0xf41` into its bypass routing mark, and its nat drops
    marked traffic leaving through the tunnel. The VM side only marks *new* connections, so the "packet too big"
    ICMP for container flows can't mark them by accident.
  - **MSS clamping:** containers use MTU 1500, the tunnels less (Mullvad 1380, work 1280), and Mullvad drops the ICMP
    that would tell containers. SYNs are clamped to the route MTU, and SYN-ACKs to 1340 (Mullvad) / 1240 (work).
- Not used: `mullvad lan set allow`. It opens every private range, not just Docker.
- **Check:** `ip route get 1.1.1.1 from 172.17.0.2 iif docker0` → `dev wg0-mullvad` (container traffic in the tunnel);
  `docker run --rm alpine wget -qO- https://am.i.mullvad.net/connected` → "You are connected to Mullvad";
  `psql -c 'select 1'`. Rules: `sudo nft list table inet mullvad-allow-docker`.

## PostgreSQL

PostgreSQL 18 in Docker, Omarchy's way (`omarchy-install-docker-dbs` → PostgreSQL), managed by
`~/.local/bin/pg-local`: container `postgres18`, `127.0.0.1:5432` and `[::1]:5432`, trust auth (no password), named volume
`postgres18-data` so the data survives re-creating the container. Client tools (`psql`, `pg_dump`) come from
`postgresql-libs`. `.bashrc` sets `PGHOST=127.0.0.1`, since there's no local socket.

- **Every Omarchy machine with Docker gets it on `chezmoi apply`** (`run_onchange_after_70-dev-services`):
  `docker.service` is enabled at boot (Omarchy only socket-activates Docker, so restart-policy containers would stay
  down until something touched Docker), then `pg-local ensure` and `pgadmin ensure`.
- **Both loopbacks:** `localhost` resolves to `::1` first (Node and `psql` try it first), and Docker only listens on
  the addresses it's given. So `pg-local` and `redis-local` publish on `127.0.0.1` and `::1`. `localhost`, `127.0.0.1`,
  `::1` and `0.0.0.0` all work. A container made before this is re-created on the next `ensure`: stopped cleanly, then
  removed, and the data stays in its volume.
- `pg-local ensure` creates or starts the container, waits for a real TCP connection, and adds a superuser role named
  after you. So `psql -d <db>` and `postgres://localhost/<db>` work without a password, as with Homebrew.
- Without sudoless Docker (Omarchy's default on non-work machines), the helpers use `sudo docker` in a terminal and a
  polkit prompt from the app launcher.
- Data from the Mac's Homebrew Postgres: `tools/pg-import.sh` (see [machines](machines.md#moving-the-mac-workspace)).
- Compose projects with their own database (e.g. FSM: `postgres:16-alpine` on 5434) bring theirs up with
  `docker compose up -d`.
- `pg-local stop` stops it. Shell as the postgres superuser: `docker exec -it postgres18 psql -U postgres`.

## pgAdmin

`~/.local/bin/pgadmin` runs pgAdmin 4 in Docker (`dpage/pgadmin4`, which has an arm64 build; the AUR packages are
x86-only) and opens it as an Omarchy web app at `http://127.0.0.1:5050`.

- **App launcher:** "pgAdmin" (`~/.local/share/applications/pgAdmin.desktop`, icon from pgAdmin's own logo). It runs
  `pgadmin`, which starts the container if needed and opens the web app.
- Created on `chezmoi apply` with the other dev services (see [PostgreSQL](#postgresql)).
- **Desktop mode:** no pgAdmin login and no master password. The data lives in the volume `pgadmin-data`.
- **Host networking** (`--network host`, listening on 127.0.0.1 only): it reaches `postgres18` and the work VPN's
  databases like any VM program. With Mullvad on, only the VM's own traffic may use the `work` tunnel, so a normal
  container network couldn't reach staging.
- The first start adds **Local (postgres18)** (`127.0.0.1:5432`, your role, no password).
- **Connections from another pgAdmin:** *Tools → Import/Export Servers → Export*, then `pgadmin import <file>.json`.
  Passwords aren't exported. pgAdmin asks on first connect; tick *Save password*.
- `pgadmin ensure` (start without opening), `pgadmin stop`.

## Redis

Redis 7 in Docker, set up like PostgreSQL: `~/.local/bin/redis-local` (`run_onchange_after_70-dev-services` runs
`redis-local ensure` on every machine with Docker). Container `redis` (Omarchy's name and image), `127.0.0.1:6379` and `[::1]:6379`, no
password, volume `redis-data` (`/data`, so data survives re-creating the container). Services connect with the default
`redis://localhost:6379`.

- `redis-cli` comes from the `valkey` package (Arch replaced `redis` with its fork Valkey). Valkey's own server
  (`valkey.service`) stays disabled; the Docker container is the server.
- `redis-local ensure` (create/start, wait for `PONG`), `redis-local stop`. Overrides: `REDIS_CONTAINER`, `REDIS_IMAGE`,
  `REDIS_VOLUME`, `REDIS_PORT`.
- Check: `redis-cli ping` (or `docker exec redis redis-cli ping`).

## Postman

- Package `postman-bin` (AUR, aarch64 + x86_64).
- **Not in chezmoi:** `~/.config/Postman/` (app settings, including API keys).

## Mullvad VPN

- **Package:** `mullvad-vpn-bin` (AUR, aarch64 + x86_64) pulls in `mullvad-vpn-daemon-bin`. The daemon's install script
  runs `systemctl enable --now mullvad-daemon` and `enable mullvad-early-boot-blocking`.
- **Autostart (GUI/tray):** `~/.config/autostart/mullvad-vpn.desktop` → `/usr/share/applications/mullvad-vpn.desktop`,
  tracked as `dot_config/autostart/symlink_mullvad-vpn.desktop`. It's the same symlink the app's own
  _Launch app on start-up_ setting creates. If you turn that setting off, chezmoi shows the symlink as missing; then
  `chezmoi forget` it or switch the setting back on.
- **Not in chezmoi:** account login and app settings (`/etc/mullvad-vpn/settings.json`, root-owned; holds account state).
  On a new machine, log in once (`mullvad account login` or the GUI) and set auto-connect there (`mullvad auto-connect set on`).
- **DNS:** when connected, systemd-resolved sends lookups over the tunnel to Mullvad's `10.64.0.1` (link `wg0-mullvad`,
  `~.`). The VM's DNS-over-TLS servers (global) are only used when the VPN is off. Check with `resolvectl query example.com`
  (should say `link: wg0-mullvad`).
- **Install note:** the package's install step calls `updatedb`, which isn't installed (no `locate`). That message is harmless.

### Mullvad on the VM

- **IPv4 relays only** (`run_onchange_after_57-vm-mullvad-ipv4`, `.vm`): the Mac's VM network gives the guest an IPv6
  address (`fec0::/64`) and route but carries no IPv6 (`ping -6` fails). Mullvad still sees IPv6 as online, and with
  _IP protocol: any_ some reconnects, typically after the Mac sleeps, picked a relay's IPv6 address. Packets went out
  and nothing came back (`Timeout while negotiating ephemeral peer`, `rx_bytes: 0` in `journalctl -u mullvad-daemon`),
  so the tunnel sat dead until a retry happened to pick IPv4. The script runs `mullvad relay set ip-version ipv4`
  (no sudo). Check: `mullvad relay get` → `IP protocol: IPv4`.
- **`vpn-up`** (`~/.local/bin`, every machine): Mullvad first, connected *and* passing traffic (checks
  `am.i.mullvad.net/connected`; reconnects up to 3 times, restarts the daemon if it doesn't answer), then
  `nmcli connection up work` if that connection exists (re-upped if already up, so it handshakes over the current
  tunnel). `vpn-up --no-work` stops after Mullvad. It replaces killing/restarting the app and bringing `work` up by
  hand. The Mullvad GUI doesn't need restarting: it only displays the daemon's state.
- **At login** on VMs: `~/.config/autostart/vpn-up.desktop` runs it (ignored on other machines in `.chezmoiignore`),
  with a desktop notification for the result. After the Mac wakes from sleep, run `vpn-up` by hand if anything is stuck.
  `work` keeps `autoconnect no`, so it never comes up before Mullvad.

## gpg / dirmngr (`~/.gnupg/dirmngr.conf`, VMs only)

`private_dot_gnupg/dirmngr.conf.tmpl` sets `disable-ipv6` when `.vm`. It renders empty on the desktop, so no file is
created there. Why: see [troubleshooting](troubleshooting.md). After it changes, restart dirmngr with `gpgconf --kill dirmngr`.

## mise (`~/.config/mise/config.toml`)

Global toolchains: `claude`, `codex`, `gh`, `go` (all `latest`), `node` (`22`, the work services' version) and `rust` (`stable`).
- Rust: mise installs it with rustup (`~/.rustup`, `~/.cargo`), so `rustup component add rust-analyzer` / `rustup update`
  work as usual. No `. ~/.cargo/env` in `.bash_profile`: mise puts `cargo`/`rustc` on PATH.
Editing this file re-runs `mise install` on the next `chezmoi apply` (see [scripts](scripts.md)).
On the VM, mise comes from the `try-omarchy-mise` package.

**Node versions per project (replaces nvm):** `[settings] idiomatic_version_file_enable_tools = ["node"]` makes mise
read `.nvmrc` / `.node-version`. `cd` into a project and its Node version is active (the switch happens at the next
prompt). nvm isn't installed: alongside mise it would fight over PATH, and mise's prompt hook would undo `nvm use`.

| nvm | mise |
|---|---|
| `nvm install` (reads `.nvmrc`) | `mise install` in the project |
| `nvm use 20` (this shell) | `mise shell node@20` |
| `nvm alias default 20` | `mise use -g node@20` (global is `22` here; set it in the chezmoi source, or apply puts it back) |
| `nvm ls` | `mise ls node` |

Installed for the work repos (2026-10-19): Node 8 (checkpeople) and 16 (cp-wl, crm, information). Check with
`mise ls --current node` in the project.

## Docker

Omarchy installs Docker (`docker`, `docker-compose`, `docker-buildx`; daemon started on demand by `docker.socket`).
**Colima isn't used:** on Linux, containers run natively, and Colima would only add a VM, which runs in slow software
emulation here (Try Omarchy has no nested virtualization, so no `/dev/kvm`).

- **Sudoless on work machines:** `run_onchange_after_65-sudoless-docker` (`.work` = true) runs Omarchy's
  `omarchy-setup-security-sudoless-docker`. It warns, asks yes/no, then adds you to the `docker` group (sudo). It
  takes effect **after a reboot**. Omarchy's default is `sudo docker` because the group is **root-equivalent**: any
  process running as you can `docker run -v /:/host` without a password. Undo: `omarchy-remove-security-sudoless-docker`.
- Considered: rootless Docker (`docker-rootless-extras`, AUR). It's safer, but some setups behave differently (ports
  below 1024, host networking).
- Check: `docker run --rm hello-world`; `id -nG | grep docker`.

## Ports below 1024

Linux lets only root listen on ports below 1024; macOS doesn't (since 10.14). Apps whose `.env` says port 80, such as
`Professional/account` (`TRAVELLING_PORT=80`), fail with `EACCES` / "permission denied" here.
`run_onchange_after_66-unprivileged-ports` (every machine) writes `/etc/sysctl.d/60-unprivileged-ports.conf` with
`net.ipv4.ip_unprivileged_port_start = 80` (sudo, once): any user can listen on 80 and up (IPv4 and IPv6), and 1-79 stay
root-only. UFW is separate: it filters connections from other hosts, not `localhost`.

- Check: `sysctl net.ipv4.ip_unprivileged_port_start` (80); `ss -ltnp | grep ':80 '`.
- Undo: delete the file, then `sudo sysctl -w net.ipv4.ip_unprivileged_port_start=1024`.
- Not used: `setcap cap_net_bind_service` on `node`. mise installs a new binary per version, so it would need redoing.

## tmux (`~/.config/tmux/tmux.conf`)

Omarchy stock config (prefix `C-Space`, Omarchy keys and theme) with the Mac `~/.tmux.conf` merged in at the bottom.

**From the Mac:**

- `visual-activity off`
- `C-S-Left` / `C-S-Right`: move the current window left/right (same as Omarchy's `M-S-Left/Right`).
- Dropped: `default-command "reattach-to-user-namespace -l $SHELL"` (macOS-only, unneeded since tmux 2.6).

**Plugins** (TPM, XDG layout → `~/.config/tmux/plugins/`):

| Plugin                        | Does                                                                                                                    |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `tmux-plugins/tpm`            | Plugin manager; `prefix U` updates, `prefix alt-u` cleans                                                               |
| `tmux-plugins/tmux-sensible`  | Sane defaults; only touches options still at tmux defaults                                                              |
| `tmux-plugins/tmux-yank`      | Copy-mode `y` → system clipboard (`wl-copy` on Omarchy)                                                                 |
| `jimeh/tmux-themepack`        | `powerline/block/cyan` theme. **Overrides the Omarchy theme block**, so it won't follow `omarchy theme` changes         |
| `tmux-plugins/tmux-resurrect` | `prefix C-s` save / `prefix C-r` restore sessions; saves in `~/.local/share/tmux/resurrect/` (machine-local, untracked) |
| `tmux-plugins/tmux-continuum` | Auto-saves every 15 min; `@continuum-restore on` restores when the tmux server starts                                   |

Plugins aren't vendored. `.chezmoiexternal.toml.tmpl` clones each one as a shallow `git-repo` external, so a fresh
`chezmoi apply` installs them (no `prefix I` needed). chezmoi pulls them at most weekly (`refreshPeriod = 168h`);
force sooner with `chezmoi apply --refresh-externals`.

**Adding a plugin:** add `set -g @plugin 'owner/repo'` to `tmux.conf` **and** an `owner/repo` entry to the `$plugins`
dict in `.chezmoiexternal.toml.tmpl`, then `chezmoi apply` and `prefix q` to reload.
**Going back to the Omarchy theme:** remove the themepack `@plugin` + `@themepack` lines and its externals entry.

**Window sizes across monitors (`~/.config/tmux/fit-windows.sh`):** with `aggressive-resize`, tmux only resizes a
window when a screen shows it. Windows restored by continuum, or last used on another monitor, keep the old size and
pane proportions until visited. `fit-windows.sh` sizes every window of the client's session to the current screen
(panes scale proportionally), then unsets each window's `window-size`, so tmux's normal sizing (`latest`) takes over
again. It runs from hooks on `client-attached`, `client-session-changed` and `client-resized` (index `[90]`), from
`@resurrect-hook-post-restore-all`, and on `prefix F` ("Fit all windows to this screen").

## starship (`~/.config/starship.toml`)

Stock Omarchy. Tracked for future changes.

## lazygit (`~/.config/lazygit/config.yml`)

Empty file (the `empty_` attribute keeps it), so lazygit uses its defaults. Opened from nvim with `<leader>gg`.
