# Shell

[← README](../README.md) · Last updated: 2026-10-16

Source: `dot_bashrc` → `~/.bashrc`. Omarchy's defaults come from `$OMARCHY_PATH/default/bash/rc`; everything below overrides or extends them.

## Customizations

| Setting | Purpose |
|---|---|
| `PATH += $(go env GOPATH)/bin` | Go-installed binaries |
| `GOPRIVATE` | Private Go modules (see [known issues](#known-issues)) |
| `CUDA_HOME`, CUDA `PATH` / `LD_LIBRARY_PATH` | CUDA toolkit at `/opt/cuda` (desktop) |
| `alias ws` | `cd ~/Documents/Workspace/Professional` |
| `alias fixVesk` | Restart xdg-desktop-portal(-hyprland), pipewire, wireplumber (Vesktop screen share / audio fix) |
| `source ~/.bashrc.local` | Machine-local secrets (last line) |

## Secrets: `~/.bashrc.local`

- Untracked (listed in `.chezmoiignore`), mode `0600`, sourced at the end of `~/.bashrc` if present.
- Create it by hand on each machine. Never `chezmoi add` it.
- Variables expected there (names only):

| Variable | Used by |
|---|---|
| `OPENAI_API_KEY` | CLI tools / scripts |
| `CODESTRAL_API_KEY` | Codestral completions |
| `GEMINI_API_KEY` | nvim `minuet.lua` (AI ghost text), `avante.lua` |

Upgrade path: move these into a password manager and render them with `onepasswordRead` (or similar), or encrypt the file with age. See [workflow](workflow.md#secrets-never-commit-them-in-plain-text).

## Known issues

- The two `export GOPRIVATE=` lines overwrite each other, so only `github.com/TetonDigitalLLC/*` takes effect.
  Fix: `export GOPRIVATE="gitlab.com/trazi-ventures/*,github.com/TetonDigitalLLC/*"`.
- `$(go env GOPATH)` prints an error in shells where go isn't installed yet (e.g. before `mise install`).
- `.bashrc` is not a template, so use `chezmoi re-add` after editing it live. If it becomes `.tmpl`, switch to `chezmoi edit`.
