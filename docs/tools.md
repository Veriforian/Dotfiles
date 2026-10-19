# Tools

[← README](../README.md) · Last updated: 2026-10-19

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
| `~/.ssh/config`                                 | `private_dot_ssh/private_config`                     | `AddKeysToAgent yes`: if the key isn't loaded, the first git/ssh use asks once and caches it        |

- Keys (`~/.ssh/id_*`) are **not** in chezmoi. Copy or generate them per machine.
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

## gpg / dirmngr (`~/.gnupg/dirmngr.conf`, VMs only)

`private_dot_gnupg/dirmngr.conf.tmpl` sets `disable-ipv6` when `.vm`. It renders empty on the desktop, so no file is
created there. Why: see [troubleshooting](troubleshooting.md). After it changes, restart dirmngr with `gpgconf --kill dirmngr`.

## mise (`~/.config/mise/config.toml`)

Global toolchains, all `latest`: `claude`, `codex`, `gh`, `go`, `node`.
Editing this file re-runs `mise install` on the next `chezmoi apply` (see [scripts](scripts.md)).
On the VM, mise comes from the `try-omarchy-mise` package.

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

## starship (`~/.config/starship.toml`)

Stock Omarchy. Tracked for future changes.

## lazygit (`~/.config/lazygit/config.yml`)

Empty file (the `empty_` attribute keeps it), so lazygit uses its defaults. Opened from nvim with `<leader>gg`.
