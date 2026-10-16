# Changelog

[← README](../README.md)

Config changes, newest first. One line per change; link to the doc that describes it.

## 2026-10-16

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
