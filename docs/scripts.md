# Scripts & packages

[← README](../README.md) · Last updated: 2026-10-16

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
| `run_onchange_before_05-vm-network.sh.tmpl` | `.vm` | Script edited | DNS over TLS (`/etc/systemd/resolved.conf.d/10-dns-over-tls.conf`), NetworkManager ignores DHCP DNS, prefers `ca.us`/`tw2` ARM mirrors. Idempotent; sudo only if something differs. |
| `run_onchange_before_10-install-packages.sh.tmpl` | `omarchy-pkg-add` exists | `packages.yaml` changes | `omarchy-pkg-add <list>`; skips installed packages |
| `run_onchange_after_20-mise-install.sh.tmpl` | `mise` exists | `~/.config/mise/config.toml` changes | `mise install` |
| `run_onchange_after_30-nvim-plugins.sh.tmpl` | `nvim` exists | `lazy-lock.json` changes | `nvim --headless "+Lazy! restore"` (10 min timeout) |

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

Language toolchains (node, go, …) live in mise instead (see [tools](tools.md#mise)).

### Adding or removing a package

1. Edit `.chezmoidata/packages.yaml` and add a comment saying why.
2. On the VM, check that it exists for aarch64: `pacman -Si <pkg>`.
3. `chezmoi apply` installs it.
4. Update the table above and the [changelog](changelog.md).

Removing a package from the list does **not** uninstall it. Do that with `omarchy pkg remove <pkg>`.

## Forcing a re-run

```bash
chezmoi state delete-bucket --bucket=entryState    # all run_onchange_ scripts
chezmoi state delete-bucket --bucket=scriptState   # run_once_ scripts
```
