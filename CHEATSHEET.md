# chezmoi cheatsheet

Source: `~/.local/share/chezmoi` (git) → rendered per machine → written to `~`.
This file is listed in `.chezmoiignore`, so it lives in the repo only.

## Everyday flow

```bash
# Change a file
chezmoi edit ~/.bashrc              # edits the SOURCE (required for *.tmpl files)
#   or edit the live file, then:
chezmoi re-add                      # pull modified live files back (skips templates!)
chezmoi merge ~/.bashrc             # live + source both changed / templated file

# New file
chezmoi add ~/.config/foo/config
chezmoi add --template ~/.config/foo/config   # needs per-machine logic

# Review → commit → push
chezmoi status
chezmoi diff
chezmoi git -- add -A
chezmoi git -- commit -m "hypr: add bindings"
chezmoi git -- push

# Other machine
chezmoi git -- pull --rebase && chezmoi diff && chezmoi apply
chezmoi update                      # pull + apply in one go
```

### After `omarchy update` / `omarchy refresh`

```bash
chezmoi status && chezmoi diff <file>
chezmoi apply <file>      # keep mine
chezmoi re-add <file>     # accept Omarchy's version
chezmoi merge <file>      # pick and choose
```
If a file drifts all the time, manage only the keys you care about with `modify_`, or ignore the file.

### After `:Lazy update` in nvim

```bash
chezmoi re-add ~/.config/nvim/lazy-lock.json   # commit it; other machines restore on apply
```

### Reading `chezmoi status`

The first column shows what changed live since the last apply. The second shows what `apply` would do.
`A` add · `D` delete · `M` modify · `R` script will run.
`MM` = you edited it locally **and** apply would overwrite it, so re-add or merge first.

## Command reference

| Command | Does |
|---|---|
| `chezmoi init [--apply] <gh-user>` | Clone `github.com/<user>/dotfiles` (and apply) |
| `chezmoi init` | Re-render config from `.chezmoi.toml.tmpl` |
| `chezmoi apply [-nv] [target]` | Write targets (`-n` dry run, `-v` verbose) |
| `chezmoi apply --exclude=scripts` | Files only, no scripts |
| `chezmoi diff` / `status` | What apply would change |
| `chezmoi edit [-a] <target>` | Edit source (`-a` apply after) |
| `chezmoi add [--template\|--encrypt] <target>` | Start tracking |
| `chezmoi re-add [target]` | Copy live changes back to source |
| `chezmoi forget <target>` | Stop tracking, keep file |
| `chezmoi chattr +template\|+private\|+executable <target>` | Change attributes |
| `chezmoi merge <target>` / `merge-all` | 3-way merge |
| `chezmoi cat <target>` | Show rendered target |
| `chezmoi data` | All template variables |
| `chezmoi execute-template '{{ .chezmoi.arch }}'` | Test template snippets |
| `chezmoi managed` / `unmanaged` / `ignored` | What is tracked |
| `chezmoi verify` | Non-zero exit on drift |
| `chezmoi doctor` | Health check |
| `chezmoi cd` / `chezmoi git -- …` | Work in the source repo |

## Source filename attributes

| Attribute | Effect |
|---|---|
| `dot_` | Leading `.` |
| `private_` | 0600 / 0700 |
| `executable_` | +x |
| `readonly_` | Remove write bits |
| `symlink_` | Contents = link target |
| `empty_` | Keep even if empty |
| `exact_` | Dir: **delete** unmanaged entries |
| `create_` | Write only if missing |
| `modify_` | Transform the existing file |
| `remove_` | Delete target |
| `encrypted_` | age/gpg encrypted in repo |
| `.tmpl` | Go template |

## Special source files

| File | Purpose |
|---|---|
| `.chezmoi.toml.tmpl` | Per-machine config + prompts (`email`, `work`, `vm`) |
| `.chezmoidata/*.yaml` | Template data (`packages.yaml`) |
| `.chezmoiignore` | Target paths to skip (templatable) |
| `.chezmoiremove` | Targets to delete |
| `.chezmoiexternal.toml` | Pull git repos / archives / files |
| `.chezmoitemplates/` | Shared snippets: `{{ template "x" . }}` |
| `.chezmoiscripts/` | Scripts without a matching dir in `~` |
| `.chezmoiroot` | Use a subdir of the repo as source |

## Scripts

| Prefix | Runs |
|---|---|
| `run_` | Every apply |
| `run_once_` | Once per unique content |
| `run_onchange_` | When rendered content changes |
| `before_` / `after_` | Before / after files are written |

The scripts run in alphabetical order. A script that renders empty is skipped (the `lookPath` guards rely on this).
To make a script watch a file, embed its hash: `# {{ include "dot_config/x" | sha256sum }}`.

This repo's scripts:
- `run_onchange_before_10-install-packages` runs `omarchy-pkg-add` on `.chezmoidata/packages.yaml`.
- `run_onchange_after_20-mise-install` runs `mise install` when the mise config changes.
- `run_onchange_after_30-nvim-plugins` runs `Lazy! restore` when `lazy-lock.json` changes.

Adding a package = edit `packages.yaml` + `chezmoi apply`. Removing one from the list does **not** uninstall it.

Force a re-run:
```bash
chezmoi state delete-bucket --bucket=entryState    # run_onchange_
chezmoi state delete-bucket --bucket=scriptState   # run_once_
```

## Templates

```bash
{{- if eq .chezmoi.arch "amd64" }} ... {{- end }}   # amd64 desktop vs arm64 VM
{{- if .work }} ... {{- end }}
{{- if .vm }} ... {{- end }}                        # Try Omarchy VM
{{- if lookPath "nvim" }} ... {{- end }}
{{ .chezmoi.hostname }}  {{ .chezmoi.osRelease.id }}  # archarm / arch
{{ output "cmd" "arg" | trim }}
```
Prompts in `.chezmoi.toml.tmpl`: `promptStringOnce`, `promptBoolOnce`, `promptChoiceOnce`.

## Partial management (`modify_`)

`dot_config/omarchy/modify_shell.json`:
```
{{- /* chezmoi:modify-template */ -}}
{{ fromJson .chezmoi.stdin | setValueAtPath "idle.lock" 600 | toPrettyJson }}
```

## Externals (`.chezmoiexternal.toml`)

```toml
[".config/tmux/plugins/tpm"]
  type = "git-repo"
  url = "https://github.com/tmux-plugins/tpm"
  refreshPeriod = "168h"
```
Types: `file`, `archive`, `archive-file`, `git-repo`. Force: `chezmoi apply --refresh-externals`.

## Secrets: never commit them in plain text

- **Current setup:** `~/.bashrc.local` (0600, untracked, in `.chezmoiignore`) is sourced at the end of `~/.bashrc`.
  Create it by hand on each machine.
- **Password manager:** `export X={{ onepasswordRead "op://Vault/Item/field" | quote }}`
  (also `bitwarden`, `pass`, `keepassxc`, `gopass`, `secret`).
- **age:** set `encryption = "age"` + `[age]` identity/recipient in config, then
  `chezmoi add --encrypt ~/.bashrc.local`.

Before committing, check: `chezmoi git -- diff --cached | grep -iE 'key|token|secret'`

## Handy config (in `.chezmoi.toml.tmpl`)

```toml
[diff]
  pager = "delta"
[edit]
  command = "nvim"
  apply = true
[merge]
  command = "nvim"
  args = ["-d"]
```
