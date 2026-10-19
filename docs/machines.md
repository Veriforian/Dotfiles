# Machines

[← README](../README.md) · Last updated: 2026-10-19

## Machine data

`.chezmoi.toml.tmpl` asks once per machine and writes `~/.config/chezmoi/chezmoi.toml`:

| Key | Source | Used by |
|---|---|---|
| `email` | Prompt: "Git email for this machine" | Nothing yet (see [known gaps](#known-gaps)) |
| `work` | Prompt: "Is this a work machine" | Nothing yet |
| `vm` | Auto: `systemd-detect-virt --vm` isn't `none` (Try Omarchy, OmacVM, UTM, any VM), or `/usr/share/try-omarchy` exists | `run_onchange_before_05-vm-network` |

Useful built-ins: `.chezmoi.arch` (`amd64` / `arm64`), `.chezmoi.osRelease.id` (`arch` on the desktop, `omarchy` on Try Omarchy 1.0+, `archarm` on older ARM installs), `.chezmoi.hostname`.

**Try Omarchy-only bits** don't use `.vm`. They check for their own files instead, e.g. `hypr/input.lua.tmpl` only
`dofile()`s `/usr/share/try-omarchy/*-input.lua` if that file exists. Templates run with `missingkey=error`, so a new
data key breaks rendering until `chezmoi init` is re-run. Prefer `stat` checks for host-specific files.

Inspect them with `chezmoi data`. Re-run the prompts with `chezmoi init`. Answers you already gave are kept, so edit `~/.config/chezmoi/chezmoi.toml` to change one.

## What differs per machine

| Item | Desktop (amd64) | VM (arm64; Try Omarchy unless noted) |
|---|---|---|
| `hypr/input.lua` | Stock comments only | Try Omarchy only: also loads `/usr/share/try-omarchy/pinch-input.lua` and `apple-keyboard-input.lua` |
| DNS | System default | DNS over TLS to Cloudflare/Google; DHCP DNS ignored |
| Pacman mirrors | Arch mirrors | Try Omarchy 1.0+: Omarchy's `arm-mirror.omarchy.org` (left alone). `ca.us` → `tw2` → geo redirect only when `osRelease.id` is `archarm` (older VMs, OmacVM) |
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
the Try Omarchy input includes. Dual-display research: `notes/dual-display/` on the Mac share (`~/OmWorkspace` or `~/Documents/Shared`; outside the repo).
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
- A symlink, not a bind mount: the pre-1.0 VM bind-mounted it with a sudo-installed system unit
  (`try-omarchy-shared-bind.service`). The symlink needs no root, and nothing here needs a real path.
- **Use the share for moving files, not for repos** (tested 2026-10-19 on the 9p mount): unix sockets fail
  (`EOPNOTSUPP`), writable shared `mmap` fails (`EINVAL`: SQLite WAL, LMDB), it's **case-insensitive** (APFS underneath),
  Mac-side edits don't trigger inotify, and it's slow for git and `node_modules`. Exec bits, relative symlinks, hard
  links, flock/fcntl, fsync and atomic rename do work.

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
PostgreSQL moves the same way: `pg-export.sh` (Mac) → `pg-import.sh` (VM). See [tools](tools.md#postgresql). Import checks SSH access first (both GitHub and
GitLab keys must work: see [tools](tools.md#ssh-agent-git-lazygit)), and re-runs resume unfinished repos.
Full usage, what's skipped and test results: `tools/README.md`.

The current export (2026-10-19, 63 repos, 11.5 GB of extras) is at `~/OmWorkspace/ws-migrate/export`. Rebuild the VM
workspace from it (blobless clones keep big histories like QEMU from timing out) with:

```bash
CLONE_ARGS="--filter=blob:none" bash ~/.local/share/chezmoi/tools/import-workspace.sh ~/OmWorkspace/ws-migrate/export ~/Documents/Workspace
```

Keep the workspace on the VM disk, not the share: 9p has no writable shared mmap, and it's slow for many small files.

## Try Omarchy updates and resets

- **Normal app updates keep the VM.** Replacing the Mac app never touches the VM disk; the guest updates itself with
  `omarchy update` (Snapper snapshot of `/` first, listed in the Limine boot menu).
- **Some releases need a new VM.** v1.0 (2026-10-17) switched from direct-boot ext4 VMs to UEFI/btrfs VMs under
  `~/Library/Application Support/Try Omarchy/VM/v1`, and started a fresh VM. Earlier releases did the same for new
  factory images. Read the [release notes](https://github.com/omacom/try-omarchy/releases) for "new or reset VM" before
  updating. If you see it, push everything, or duplicate `VM/v1` in Finder first (an instant APFS clone).
- **After a fresh VM:** the old disk is attached read-only (`/dev/vdb`, serial `omarchy-previous`) while the Mac's
  `disks/` folder exists. *Import previous VM* (`try-omarchy-import-previous`) copies visible home folders and
  `.ssh`, `.gnupg`, git and gh config only. It skips `~/.config`, `~/.local` (including this repo!) and `~/.bashrc.local`.
  Then:
  1. `chezmoi init --apply git@github.com:Veriforian/Dotfiles.git`. Unpushed commits are **not** on GitHub.
  2. `try-omarchy-import-previous --open` mounts the old disk at `/run/try-omarchy/previous-vm`. Copy back
     `~/.bashrc.local`, `tools/`, unpushed commits (`git fetch /run/try-omarchy/previous-vm/home/veri/.local/share/chezmoi`)
     and app settings, then `--close`.
  3. `try-omarchy-import-previous --packages` reinstalls hand-installed repo packages.
  4. Delete `disks/` on the Mac only once nothing else is needed.

## Known gaps

- `dot_config/git/config` hardcodes the work email; the `email` prompt is unused. Template it with
  `{{ .email }}` if personal and work machines should differ.
- `work` is unused. Intended for work-only settings like `GOPRIVATE`.
- CUDA exports could be wrapped in `{{ if eq .chezmoi.arch "amd64" }}`.
