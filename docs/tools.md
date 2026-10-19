# Tools

[← README](../README.md) · Last updated: 2026-10-19

## git (`~/.config/git/config`)

Omarchy default plus a `[user]` block (name + work email).
Gap: the email is hardcoded and doesn't use the per-machine `email` prompt (see [machines](machines.md#known-gaps)).

## SSH agent (git, lazygit)

Goal: type the key passphrase once per login, not on every commit, pull or push.

| Piece | Source | Does |
|---|---|---|
| `ssh-agent.socket` (systemd user unit, OpenSSH) | enabled by `run_onchange_after_50-ssh-agent.sh.tmpl` | One agent per login at `$XDG_RUNTIME_DIR/ssh-agent.socket`, started on first use |
| `~/.config/environment.d/10-ssh-agent.conf` | `dot_config/environment.d/` | `SSH_AUTH_SOCK` for apps launched from Hyprland (takes effect after the next login) |
| `~/.bashrc` | `dot_bashrc` | Same `SSH_AUTH_SOCK` default for shells. The first terminal with an empty agent runs `ssh-add` once |
| `~/.ssh/config` | `private_dot_ssh/private_config` | `AddKeysToAgent yes`: if the key isn't loaded, the first git/ssh use asks once and caches it |

- Keys (`~/.ssh/id_*`) are **not** in chezmoi. Copy or generate them per machine.
- `Ctrl+C` at the terminal prompt skips it. The next git operation (lazygit too) asks once instead.
- Keys stay loaded until logout. `ssh-add -l` lists them, `ssh-add -D` forgets them.
- Alternative not used: `gcr-ssh-agent` (GNOME keyring) can store the passphrase so you're never asked, similar to macOS
  `UseKeychain`. It's not used here because this setup is meant to ask once per login.

## Mullvad VPN

- **Package:** `mullvad-vpn-bin` (AUR, aarch64 + x86_64) pulls in `mullvad-vpn-daemon-bin`. The daemon's install script
  runs `systemctl enable --now mullvad-daemon` and `enable mullvad-early-boot-blocking`.
- **Autostart (GUI/tray):** `~/.config/autostart/mullvad-vpn.desktop` → `/usr/share/applications/mullvad-vpn.desktop`,
  tracked as `dot_config/autostart/symlink_mullvad-vpn.desktop`. It's the same symlink the app's own
  *Launch app on start-up* setting creates. If you turn that setting off, chezmoi shows the symlink as missing; then
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
