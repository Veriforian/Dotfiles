# Machines

[← README](../README.md) · Last updated: 2026-10-16

## Machine data

`.chezmoi.toml.tmpl` asks once per machine and writes `~/.config/chezmoi/chezmoi.toml`:

| Key | Source | Used by |
|---|---|---|
| `email` | Prompt: "Git email for this machine" | Nothing yet (see [known gaps](#known-gaps)) |
| `work` | Prompt: "Is this a work machine" | Nothing yet |
| `vm` | Auto: `systemd-detect-virt --vm` isn't `none` (Try Omarchy, OmacVM, UTM, any VM), or `/usr/share/try-omarchy` exists | `run_onchange_before_05-vm-network` |

Useful built-ins: `.chezmoi.arch` (`amd64` / `arm64`), `.chezmoi.osRelease.id` (`arch` / `archarm`), `.chezmoi.hostname`.

**Try Omarchy-only bits** don't use `.vm`. They check for their own files instead, e.g. `hypr/input.lua.tmpl` only
`dofile()`s `/usr/share/try-omarchy/*-input.lua` if that file exists. Templates run with `missingkey=error`, so a new
data key breaks rendering until `chezmoi init` is re-run. Prefer `stat` checks for host-specific files.

Inspect them with `chezmoi data`. Re-run the prompts with `chezmoi init`. Answers you already gave are kept, so edit `~/.config/chezmoi/chezmoi.toml` to change one.

## What differs per machine

| Item | Desktop (amd64) | VM (arm64; Try Omarchy unless noted) |
|---|---|---|
| `hypr/input.lua` | Stock comments only | Try Omarchy only: also loads `/usr/share/try-omarchy/pinch-input.lua` and `apple-keyboard-input.lua` |
| DNS | System default | DNS over TLS to Cloudflare/Google; DHCP DNS ignored |
| Pacman mirrors | Arch mirrors | `ca.us` → `tw2` → geo redirect (only when `osRelease.id` is `archarm`) |
| mise | `mise` package | `try-omarchy-mise` package |
| CUDA paths in `.bashrc` | Meaningful | Harmless no-op (not yet templated) |

## Bootstrapping a new machine

1. Install Omarchy (or start Try Omarchy).
2. `chezmoi init --apply git@github.com:Veriforian/Dotfiles.git` and answer the prompts.
   Scripts run in order: VM network (VM only) → packages (asks for sudo) → files → mise → nvim plugins.
3. Create `~/.bashrc.local` with secrets (see [shell](shell.md#secrets-bashrclocal)).
4. Open a new terminal. Check with `chezmoi status` (should be empty) and `chezmoi doctor`.

## Other VMs (OmacVM, UTM)

`.vm` is true there too, so they get the network script. ARM mirrors are only used on Arch Linux ARM. They don't get
the Try Omarchy input includes. Dual-display research: `~/OmWorkspace/notes/dual-display/` (outside the repo).
Run `chezmoi init` once on an existing machine after this change, so `vm` is re-detected (on Try Omarchy it stays `true`).

## Try Omarchy VM notes

- Runs under QEMU user-mode networking (`10.0.2.x`). The NAT drops ~5% of UDP DNS, hence DNS over TLS.
- No passwordless sudo. Scripts prompt in the terminal, so run `chezmoi apply` from a real terminal.
- `omarchy-pkg-refuse-aarch64-unavailable` aborts installs of packages unavailable on ARM. Check new entries in
  `packages.yaml` exist for aarch64 first (`pacman -Si <pkg>`).
- Kernel cmdline sets `tryomarchy.keyboard=ansi`; the keymap (`applealu_ansi`) has no Insert key.

## Known gaps

- `dot_config/git/config` hardcodes the work email; the `email` prompt is unused. Template it with
  `{{ .email }}` if personal and work machines should differ.
- `work` is unused. Intended for work-only settings like `GOPRIVATE`.
- CUDA exports could be wrapped in `{{ if eq .chezmoi.arch "amd64" }}`.
