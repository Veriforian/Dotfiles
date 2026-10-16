# Tools

[← README](../README.md) · Last updated: 2026-10-16

## git (`~/.config/git/config`)

Omarchy default plus a `[user]` block (name + work email).
Gap: the email is hardcoded and doesn't use the per-machine `email` prompt (see [machines](machines.md#known-gaps)).

## mise (`~/.config/mise/config.toml`)

Global toolchains, all `latest`: `claude`, `codex`, `gh`, `go`, `node`.
Editing this file re-runs `mise install` on the next `chezmoi apply` (see [scripts](scripts.md)).
On the VM, mise comes from the `try-omarchy-mise` package.

## tmux (`~/.config/tmux/tmux.conf`)

Stock Omarchy. Tracked for future changes.

## starship (`~/.config/starship.toml`)

Stock Omarchy. Tracked for future changes.

## lazygit (`~/.config/lazygit/config.yml`)

Empty file (the `empty_` attribute keeps it), so lazygit uses its defaults. Opened from nvim with `<leader>gg`.
