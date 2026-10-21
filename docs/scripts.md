# Scripts & packages

[← README](../README.md) · Last updated: 2026-10-21

## How `run_onchange_` works

chezmoi stores a hash of each script **as rendered**. On `apply`, it re-runs a script only when that rendered text changes.
`before_` scripts run before files are written and `after_` after; within a phase they run alphabetically, hence the number prefixes.
A script that renders empty (e.g. a failed `lookPath` / `.vm` guard) is skipped.

To make a script react to another file, embed that file's hash in a comment:
```bash
# hash: {{ include "dot_config/mise/config.toml" | sha256sum }}
```

## Scripts

| Script | Guard | Re-runs when | Does |
|---|---|---|---|
| `run_onchange_before_05-vm-network.sh.tmpl` | `.vm` (any VM, see [machines](machines.md)) | Script edited | DNS over TLS (`/etc/systemd/resolved.conf.d/10-dns-over-tls.conf`), NetworkManager ignores DHCP DNS, prefers `ca.us`/`tw2` ARM mirrors (Arch Linux ARM only). Idempotent; sudo only if something differs. |
| `run_onchange_before_10-install-packages.sh.tmpl` | `omarchy-pkg-add` exists | `packages.yaml` changes | `omarchy-pkg-add <pacman list>`, then `omarchy-pkg-aur-add <aur list>` (yay); both skip installed packages |
| `run_onchange_after_20-mise-install.sh.tmpl` | `mise` exists | `~/.config/mise/config.toml` changes | `mise install` |
| `run_onchange_after_30-nvim-plugins.sh.tmpl` | `nvim` exists | `lazy-lock.json` changes | `nvim --headless "+Lazy! restore"` (10 min timeout) |
| `run_onchange_after_42-window-transparency.sh.tmpl` | `omarchy-hyprland-window-transparency` exists | Script edited | If Omarchy's Window Opacity mode is `opaque` (Omarchy forces it on VMs), sets it back to `transparent` so the terminal opacity rule holds. Outside Hyprland it only removes the toggle file. See [desktop](desktop.md#hyprlooknfeellua) |
| `run_onchange_after_35-nvim-restart.sh.tmpl` | `nvim` exists | Anything under `dot_config/nvim/` changes (hash of the folder) | `~/.local/bin/nvim-restart-all`: `:restart` in every running Neovim except ones with unsaved files (see [neovim](neovim.md#reloading-running-neovims-after-a-config-change)) |
| `run_onchange_after_45-omarchy-themed.sh.tmpl` | `omarchy-theme-set` exists | `themed/foot.ini.tpl` or the `theme-set` hook changes (hashes) | `omarchy theme set <current theme>` to re-render generated configs. On a fresh machine this repeats `40`'s theme set (harmless). See [desktop](desktop.md#terminal-background-darker-than-the-theme) |
| `run_onchange_after_56-docker-mullvad.sh.tmpl` | `mullvad`, `nft`, `docker` exist | Script edited | Installs `/etc/mullvad-allow-docker.nft` + `mullvad-allow-docker.service` (sudo, only if different) so Docker bridge traffic passes Mullvad's firewall (see [tools](tools.md#docker-and-mullvad)) |
| `run_onchange_after_57-vm-mullvad-ipv4.sh.tmpl` | `.vm` and `mullvad` exists | Script edited | `mullvad relay set ip-version ipv4` unless already set: the VM network has no working IPv6. No sudo (see [tools](tools.md#mullvad-on-the-vm)) |
| `run_onchange_after_60-mac-share-link.sh.tmpl` | `/usr/bin/omarchy-native-mac-share` exists (Try Omarchy) | The unit or `mac-share-documents-link` changes (hashes) | `systemctl --user enable` + restart `mac-share-documents-link.service`: `~/Documents/Shared` → `/mnt/mac`. No sudo (see [machines](machines.md#mac-share-try-omarchy)) |
| `run_onchange_after_65-sudoless-docker.sh.tmpl` | `.work` and `omarchy-setup-security-sudoless-docker` exists | Script edited | If you're not in the `docker` group, runs Omarchy's sudoless-Docker opt-in (warning + yes/no + sudo; reboot after). See [tools](tools.md#docker) |
| `run_onchange_after_66-unprivileged-ports.sh.tmpl` | always | Script edited | Writes `/etc/sysctl.d/60-unprivileged-ports.conf` (`ip_unprivileged_port_start = 80`) and applies it (sudo, only if different), so dev servers can use port 80 without root (see [tools](tools.md#ports-below-1024)) |
| `run_onchange_after_70-dev-services.sh.tmpl` | `docker` exists | `pg-local`, `pgadmin` or `redis-local` changes (hashes) | Enables `docker.service` at boot (sudo, once), then `pg-local ensure` (postgres18), `pgadmin ensure` and `redis-local ensure`. First run pulls ~650 MB of images (see [tools](tools.md#postgresql)) |
| `run_onchange_after_55-work-vpn-mullvad.sh.tmpl` | `mullvad`, `nmcli`, `nft` exist | Script edited | Installs the NM dispatcher `/etc/NetworkManager/dispatcher.d/50-mullvad-allow-work` (sudo, only if different) and loads it if `work` is up (see [tools](tools.md#work-vpn-alongside-mullvad)) |
| `run_onchange_after_50-ssh-agent.sh.tmpl` | `systemctl` + OpenSSH's `ssh-agent.socket` unit exist | Script edited | `systemctl --user enable --now ssh-agent.socket` if not enabled. User unit, no sudo (see [tools](tools.md#ssh-agent-git-lazygit)) |
| `run_onchange_after_40-omarchy-theme.sh.tmpl` | `omarchy-theme-set` exists | Script edited (e.g. `theme=`) | `omarchy theme set one-dark-pro` unless already current. Outside a Hyprland session it prints a reminder and skips. The theme is cloned by `.chezmoiexternal.toml.tmpl`, and externals are written before `after_` scripts run |

## Packages (`.chezmoidata/packages.yaml`)

| Package | Why |
|---|---|
| `neovim` | Editor |
| `base-devel`, `tree-sitter-cli` | Treesitter parser builds |
| `lazygit` | LazyVim only maps `<leader>gg` / `<leader>gG` if it's on PATH |
| `lazydocker` | `lua/plugins/lazydocker.lua` |
| `ripgrep`, `fd`, `fzf` | fzf-lua / snacks pickers |
| `git-delta` | fzf-lua code-action previewer |
| `stylua` | `stylua.toml` in the nvim config |
| `imagemagick`, `python-pip` | snacks.image rendering |
| `docker`, `docker-compose`, `docker-buildx`, `postgresql-libs`, `valkey` | *Development tools:* local dev services (PostgreSQL and Redis in Docker, pgAdmin), the `psql` / `pg_dump` client and `redis-cli` (from `valkey`). Omarchy ships the Docker and PostgreSQL ones too; listed so the setup doesn't depend on that (see [tools](tools.md#postgresql)) |
| `rsync` | *Development tools:* copying files in from the Mac share (see [machines](machines.md#moving-the-mac-workspace)) |
| `wireguard-tools` | *Development tools:* work VPN (`wg`, `wg-quick`). See [tools](tools.md#work-vpn-wireguard) |
| `jq` | `modify_` script for Vesktop's `settings.json` (see [desktop](desktop.md#discord-presence-vesktop--customidle)) |

**AUR** (`packages.aur`, installed with `omarchy-pkg-aur-add` → yay):

| Package | Why |
|---|---|
| `hyprmon-bin` | Monitor layout TUI with Lua config support (see [desktop](desktop.md#monitors)). Not `hyprmon`, which is a different, x86_64-only tool |
| `postman-bin` | *Development tools:* API client (see [tools](tools.md#postman)) |
| `mullvad-vpn-bin` | Mullvad VPN app + daemon (see [tools](tools.md#mullvad-vpn)) |
| `vesktop-bin` | Discord client (aarch64 build available). CustomIdle keeps presence Online (see [desktop](desktop.md#discord-presence-vesktop--customidle)) |

Language toolchains (node, go, …) live in mise instead (see [tools](tools.md#mise)).

### Adding an app (checklist)

Every app must work on all machines: Try Omarchy VM and OmacVM (aarch64), and the desktop (x86_64).

1. **Find the package and check both architectures.**
   - Repo: `pacman -Si <pkg>`. `Architecture` must be `any` or available on both.
   - AUR: `yay -Si <pkg>`, then `yay -Gp <pkg> | grep -E '^(arch|source)'`. Prefer a `-bin` package that lists both
     `x86_64` and `aarch64` (e.g. `hyprmon-bin`, `vesktop-bin`, `mullvad-vpn-bin`).
   - Watch for same-name traps: AUR `hyprmon` is a different, x86_64-only tool.
   - On Try Omarchy, `omarchy-pkg-*` refuses packages it knows aren't available on aarch64.
2. **Add it to `.chezmoidata/packages.yaml`** under `pacman:` or `aur:`, with a comment saying why.
   Changing the list re-runs the install script on the next `chezmoi apply`, which skips anything already installed.
3. **Services.** Check whether the package enables its own:
   `grep -n systemctl /var/lib/pacman/local/<pkg>-*/install`. Mullvad's does.
   - If it doesn't, enable it in a `run_onchange_after_*` script, like `50-ssh-agent`.
   - System units need sudo, which the user runs. User units (`systemctl --user`) don't.
4. **Autostart.** Either the app's own `.desktop` file in `~/.config/autostart/`, or an `o.launch_on_start(...)` line in
   `dot_config/hypr/autostart.lua` (see Vesktop).
5. **Config.** Track it with `chezmoi add <file>`.
   - If the app rewrites the file itself, use a `modify_` script that sets only your keys (see `modify_settings.json`
     for Vesktop).
   - **Never add secrets** (account numbers, tokens, API keys). Log in by hand, or put them in `~/.bashrc.local`.
6. **Docs, same change:** the package table above, the doc for that area, and the [changelog](changelog.md).
7. **Test:** `chezmoi diff`, then `chezmoi apply`. On a fresh machine `chezmoi init --apply` should give a working app.

Removing a package from the list does **not** uninstall it. Do that with `omarchy pkg remove <pkg>`.

## Forcing a re-run

```bash
chezmoi state delete-bucket --bucket=entryState    # all run_onchange_ scripts
chezmoi state delete-bucket --bucket=scriptState   # run_once_ scripts
```
