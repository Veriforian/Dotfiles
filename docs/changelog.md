# Changelog

[← README](../README.md)

Config changes, newest first. One line per change; link to the doc that describes it.

## 2026-10-22

- tmux: `C-b C-b` sends `C-b` to a nested tmux (`bind C-b send-prefix -2`), e.g. tmux on an EC2 box over ssh. [tools](tools.md#tmux-configtmuxtmuxconf)

## 2026-10-21

- VMs: Alt+wheel scrolls sideways (Hyprland binds → `ydotool`), since the Mac app drops horizontal scroll; `run_onchange_after_58` installs ydotool, a uinput `uaccess` udev rule and `ydotool.service`. [desktop](desktop.md#sideways-scrolling-vm)
- Brave: `Local State` modify_ script opts in to Widevine (`brave.widevine_opted_in`), so the Spotify web app and other DRM sites play. [desktop](desktop.md#spotify-and-drm-sites)
- VMs: Mullvad uses IPv4 relays only (`run_onchange_after_57`); new `vpn-up` (Mullvad passing traffic, then `work`), run at login on VMs via `~/.config/autostart/vpn-up.desktop`. [tools](tools.md#mullvad-on-the-vm)

## 2026-10-19

- VMs: `xdph.conf` gets `screencopy:force_shm = true` (modify_ script) so screen shares aren't black on virtio-gpu. [desktop](desktop.md#screen-sharing)
- Vesktop: `webRTCIPHandlingPolicy = default_public_and_private_interfaces` (modify_ script) fixes voice stuck on "DTLS connecting" with VPN/Docker interfaces. [desktop](desktop.md#discord-voice-calls)
- tmux: `fit-windows.sh` fits every window to the current screen on attach / session switch / resize / restore, plus `prefix F`. [tools](tools.md#tmux-configtmuxtmuxconf)
- `pg-local` / `redis-local`: also publish on `[::1]` so `localhost` works (Node tries `::1` first); older containers are re-created, data kept. [troubleshooting](troubleshooting.md)
- Redis: `redis-local` (container `redis`, `redis:7`, `127.0.0.1:6379`, volume `redis-data`), started by `run_onchange_after_70-dev-services`; `valkey` package for `redis-cli`. [tools](tools.md#redis)
- mise: global Node `latest` → `22` (matches the work services; projects still override with `.nvmrc` / `mise.toml`). [tools](tools.md#mise-configmiseconfigtoml)
- Ports 80 and up no longer need root: `run_onchange_after_66-unprivileged-ports` (sysctl `ip_unprivileged_port_start = 80`), for apps like `account` on port 80. [tools](tools.md#ports-below-1024)
- Dev services on every Omarchy machine: `run_onchange_after_70-dev-services` (docker.service at boot, `pg-local` → postgres18, `pgadmin`); pgAdmin app-launcher entry + icon; docker/postgresql-libs in packages. [tools](tools.md#postgresql), [machines](machines.md#bootstrapping-a-new-machine)
- Postgres: 22 Homebrew databases (PG 14) restored into `postgres18`. `pgadmin` launcher (Docker, desktop mode, host network, `pgadmin import`). Docker + Mullvad rules revised: container internet left unmarked, MSS clamping. [tools](tools.md#pgadmin)
- Docker + Mullvad: bridge traffic gets Mullvad's firewall mark (`run_onchange_after_56`); PostgreSQL 18 in Docker; `tools/pg-export.sh` / `pg-import.sh` move Homebrew databases; `.bashrc` `PGHOST=127.0.0.1`. [tools](tools.md#postgresql)
- nvim: `chezmoi apply` restarts running Neovims (`:restart`, session kept) when the nvim config changes; `nvim-restart-all` command. [neovim](neovim.md#reloading-running-neovims-after-a-config-change)
- nvim: Lazy menu `<leader>l` → `<leader>ll`, so `<leader>ld` (Lazydocker) opens at once. [neovim](neovim.md)
- mise reads `.nvmrc` / `.node-version` (instead of nvm). Docker: sudoless opt-in on work machines (`run_onchange_after_65`); Colima not used on Linux. [tools](tools.md#docker)
- SSH: `Host gitlab.com` uses `id_gitlab_ed25519` only; fixes work GitLab clones failing. `tools/import-workspace.sh`: SSH pre-flight, no prompts, live results, parent-first, resumable re-runs. [troubleshooting](troubleshooting.md), [tools](tools.md#ssh-agent-git-lazygit)
- mise: `rust = "stable"` (rustup-managed). The pre-1.0 VM had a hand-installed rustup. [tools](tools.md#mise-configmiseconfigtoml)
- Recovered from the pre-1.0 Try Omarchy VM: `rsync` package and 9p share findings (lost unpushed commit); docs on Try Omarchy resets and recovery; `archarm` mirror notes corrected for the `omarchy` OS id. [machines](machines.md#try-omarchy-updates-and-resets)
- Try Omarchy: `~/Documents/Shared` → `/mnt/mac` via user unit `mac-share-documents-link` + `run_onchange_after_60-mac-share-link`. [machines](machines.md#mac-share-try-omarchy)
- Workspace migration tools restored to local-only `tools/` (new `.gitignore`, `.chezmoiignore`); documented. [machines](machines.md#moving-the-mac-workspace)
- Terminal opacity: Omarchy's VM *Window Opacity → Opaque* toggle (added by an update) overrode the terminal rule; new `run_onchange_after_42-window-transparency` sets it back to *Transparent*. [troubleshooting](troubleshooting.md), [scripts](scripts.md)
- Work VPN + Mullvad together: NM dispatcher adds Mullvad's split-tunnel marks for `work`; work MTU 1280 and no work DNS. [tools](tools.md#work-vpn-alongside-mullvad)
- Work VPN: `wireguard-tools` (pacman, Development tools). Configs are imported into NetworkManager, never into the repo. [tools](tools.md#work-vpn-wireguard)
- Try Omarchy audio: PipeWire quantum 4096 → 2048 (~85 → ~43 ms per cycle) to cut BT headset delay. [desktop](desktop.md#audio-latency-try-omarchy-vm)
- Postman (`postman-bin`, AUR) installed. [tools](tools.md#postman)
- Mullvad VPN (`mullvad-vpn-bin`, AUR) is a default package. [tools](tools.md#mullvad-vpn)
- VMs: `~/.gnupg/dirmngr.conf` `disable-ipv6`; fixes AUR PGP key imports failing over the VM's dead IPv6. [troubleshooting](troubleshooting.md)
- Scripts doc: checklist for adding an app. [scripts](scripts.md#adding-an-app-checklist)
- Desktop: terminal opacity rule matches by class, not by the dynamic `terminal` tag; fixes opacity flipping on title changes. [troubleshooting](troubleshooting.md)

## 2026-10-16

- Machines: `.vm` now detects any VM (`systemd-detect-virt`), e.g. OmacVM and UTM. Try Omarchy input includes are guarded by their own files, and ARM mirrors only apply on `archarm`. [machines](machines.md)
- Terminal: foot background ~30% darker than the theme (user `foot.ini.tpl` + `theme-set` hook keep foot and tmux in sync). [desktop](desktop.md#terminal-background-darker-than-the-theme)
- Monitors: `hyprmon-bin` (AUR) for visual monitor layout; VM limited to one display, documented. [desktop](desktop.md#monitors)
- SSH: systemd user ssh-agent + `AddKeysToAgent`; passphrase asked once per login, not on every git/lazygit operation. [tools](tools.md#ssh-agent-git-lazygit)
- tmux: fixed `prefix q` / `prefix ?`; their bind lines had been merged into a comment. [troubleshooting](troubleshooting.md)
- Discord presence: Vencord CustomIdle (`idleTimeout 0`) via a `modify_` script; Vesktop (`vesktop-bin`, AUR) installed + autostarts minimized; `jq` package; install script gained an `aur:` list. [desktop](desktop.md#discord-presence-vesktop--customidle)
- Desktop: One Dark Pro theme (omarchy.gallery) as a chezmoi external + `run_onchange_after_40-omarchy-theme`; Hyprland gaps set to 0; only terminals translucent (0.90 / 0.85), all other apps opaque. [desktop](desktop.md)
- tmux: Mac config merged into the Omarchy one; TPM + sensible, yank, themepack, resurrect, continuum as chezmoi git externals. [tools](tools.md#tmux-configtmuxtmuxconf)
- chezmoi config: delta diff pager, nvim editor with apply-on-save, `nvim -d` merge. [workflow](workflow.md#chezmoi-config-in-chezmoitomltmpl-enabled)
- Docs suite added: README + `docs/` (replaces `CHEATSHEET.md`).
- VM: `run_onchange_before_05-vm-network`, with DNS over TLS and faster ARM mirrors. [scripts](scripts.md), [troubleshooting](troubleshooting.md)
- Shell: secrets moved from `.bashrc` to untracked `~/.bashrc.local`. [shell](shell.md)

## 2026-10-15

- Initial import: bashrc, foot, git, hypr (bindings, input, looknfeel), lazygit, mise, nvim, starship, tmux.
- Package, mise and nvim-plugin `run_onchange` scripts. [scripts](scripts.md)
- nvim: chezmoi is now the source of truth; the old `.git` is ignored. [neovim](neovim.md)
- hypr: `input.lua` templated; Try Omarchy includes only on the VM. [desktop](desktop.md)
