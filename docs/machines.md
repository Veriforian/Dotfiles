# Machines

[← README](../README.md) · Last updated: 2026-10-19

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
| Mac share link | None | Try Omarchy only: `~/Documents/Shared` → `/mnt/mac` (see [below](#mac-share-try-omarchy)) |

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

## Mac share (Try Omarchy)

Try Omarchy mounts the shared Mac folder at `/mnt/mac` (9p, system service `omarchy-native-mac-share`). At login its
user service `omarchy-native-mac-share-link` links `~/<Mac folder name>` to it, here `~/OmWorkspace`.

We add a second link, `~/Documents/Shared` → `/mnt/mac`:
- `~/.local/bin/mac-share-documents-link`, run at login by the user unit `mac-share-documents-link.service`
  (ordered after Omarchy's link service). `run_onchange_after_60-mac-share-link` enables it.
- With the share mounted, it replaces an **empty** `~/Documents/Shared` folder with the link. A folder with content, a
  file or another link is left alone (logged).
- Without a share, it removes its own link and puts back an empty folder, so nothing points at the empty mount point.
- Deployed only where `/usr/bin/omarchy-native-mac-share` exists (`.chezmoiignore` template).
- Omarchy's service only cleans up links directly in `~`, so it never touches `~/Documents/Shared`.
- Check: `readlink ~/Documents/Shared`; `journalctl --user -u mac-share-documents-link`.

## Moving the Mac workspace

The work repos on the Mac (`~/Documents/Workspace`) move to the VM with three scripts in the repo's `tools/` folder.
It's **local-only**: ignored by git (`.gitignore`) and chezmoi (`.chezmoiignore`), so it never reaches GitHub or `~`.
A copy lives on the share at `~/OmWorkspace/ws-migrate/`. That copy survives a VM reset, so restore from it with
`cp ~/OmWorkspace/ws-migrate/*.sh ~/OmWorkspace/ws-migrate/README.md ~/.local/share/chezmoi/tools/`.

| Script | Runs on | Does |
|---|---|---|
| `backup-workspace.sh <workspace> <archive>` | Mac | Exact backup (every `.git`, stashes, reflogs) to one `.tar.zst` |
| `export-workspace.sh <workspace> <empty-dir>` | Mac | Small export: `repos.tsv`, bundles of unpushed commits, patches of uncommitted changes, `extras.tar.zst` (ignored/untracked files) |
| `import-workspace.sh <export-dir> <workspace>` | VM | Clones from remotes in parallel, restores unpushed commits/branches, unpacks extras, re-applies patches. Safe to re-run |

Full usage, what's skipped and test results: `tools/README.md`.

The current export (2026-10-19, 63 repos, 11.5 GB of extras) is at `~/OmWorkspace/ws-migrate/export`. Rebuild the VM
workspace from it with:

```bash
bash ~/.local/share/chezmoi/tools/import-workspace.sh ~/OmWorkspace/ws-migrate/export ~/Documents/Workspace
```

Keep the workspace on the VM disk, not the share: 9p has no writable shared mmap, and it's slow for many small files.

## Known gaps

- `dot_config/git/config` hardcodes the work email; the `email` prompt is unused. Template it with
  `{{ .email }}` if personal and work machines should differ.
- `work` is unused. Intended for work-only settings like `GOPRIVATE`.
- CUDA exports could be wrapped in `{{ if eq .chezmoi.arch "amd64" }}`.
