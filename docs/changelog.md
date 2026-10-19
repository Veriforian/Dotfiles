# Changelog

[← README](../README.md)

Config changes, newest first. One line per change; link to the doc that describes it.

## 2026-10-19

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
