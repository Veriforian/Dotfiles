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

Omarchy stock config (prefix `C-Space`, Omarchy keys and theme) with the Mac `~/.tmux.conf` merged in at the bottom.

**From the Mac:**
- `visual-activity off`
- `C-S-Left` / `C-S-Right`: move the current window left/right (same as Omarchy's `M-S-Left/Right`).
- Dropped: `default-command "reattach-to-user-namespace -l $SHELL"` (macOS-only, unneeded since tmux 2.6).

**Plugins** (TPM, XDG layout → `~/.config/tmux/plugins/`):

| Plugin | Does |
|---|---|
| `tmux-plugins/tpm` | Plugin manager; `prefix U` updates, `prefix alt-u` cleans |
| `tmux-plugins/tmux-sensible` | Sane defaults; only touches options still at tmux defaults |
| `tmux-plugins/tmux-yank` | Copy-mode `y` → system clipboard (`wl-copy` on Omarchy) |
| `jimeh/tmux-themepack` | `powerline/block/cyan` theme. **Overrides the Omarchy theme block**, so it won't follow `omarchy theme` changes |
| `tmux-plugins/tmux-resurrect` | `prefix C-s` save / `prefix C-r` restore sessions; saves in `~/.local/share/tmux/resurrect/` (machine-local, untracked) |
| `tmux-plugins/tmux-continuum` | Auto-saves every 15 min; `@continuum-restore on` restores when the tmux server starts |

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
