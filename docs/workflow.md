# Workflow

[← README](../README.md) · Last updated: 2026-10-16

How to work with chezmoi day to day. Source: `~/.local/share/chezmoi` (git) → rendered per machine → written to `~`.

## Everyday flow

```bash
# Change a file
chezmoi edit ~/.bashrc              # edits the SOURCE in nvim; applies on save (edit.apply = true)
#   or edit the live file, then:
chezmoi re-add                      # pull modified live files back (skips templates!)
chezmoi merge ~/.bashrc             # live + source both changed, or a templated file

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

Don't forget to update the matching doc and the [changelog](changelog.md) in the same commit.

### After `omarchy update` / `omarchy refresh`

```bash
chezmoi status && chezmoi diff <file>
chezmoi apply <file>      # keep mine
chezmoi re-add <file>     # accept Omarchy's version
chezmoi merge <file>      # pick and choose
```
If a file drifts all the time, manage only the keys you care about with `modify_`, or ignore it.
Example: `dot_config/private_vesktop/settings/modify_settings.json` (see [desktop](desktop.md#discord-presence-vesktop--customidle)).

### After `:Lazy update` in nvim

```bash
chezmoi re-add ~/.config/nvim/lazy-lock.json   # commit it; other machines restore on apply
```

### Reading `chezmoi status`

The first column shows what changed live since the last apply. The second shows what `apply` would do.
`A` add · `D` delete · `M` modify · `R` script will run.
`MM` = edited locally **and** apply would overwrite it, so re-add or merge first.

## Command reference

| Command | Does |
|---|---|
| `chezmoi init [--apply] <repo>` | Clone (and apply) |
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
| `empty_` | Keep even if empty (used by `lazygit/empty_config.yml`) |
| `exact_` | Dir: **delete** unmanaged entries |
| `create_` | Write only if missing |
| `modify_` | Transform the existing file |
| `remove_` | Delete target |
| `encrypted_` | age/gpg encrypted in repo |
| `.tmpl` | Go template |

## Special source files

| File | Purpose |
|---|---|
| `.chezmoi.toml.tmpl` | Per-machine config + prompts (see [machines](machines.md)) |
| `.chezmoidata/*.yaml` | Template data (`packages.yaml`) |
| `.chezmoiignore` | Target paths to skip (templatable) |
| `.chezmoiremove` | Targets to delete |
| `.chezmoiexternal.toml` | Pull git repos / archives / files |
| `.chezmoitemplates/` | Shared snippets: `{{ template "x" . }}` |
| `.chezmoiscripts/` | Scripts without a matching dir in `~` |
| `.chezmoiroot` | Use a subdir of the repo as source |

## Templates

```bash
{{- if eq .chezmoi.arch "amd64" }} ... {{- end }}   # desktop vs arm64 VM
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
In use: `.chezmoiexternal.toml.tmpl` (templated so the tmux plugin list is one dict, see [tools](tools.md#tmux-configtmuxtmuxconf); also the Omarchy theme, see [desktop](desktop.md#theme-one-dark-pro)).

## Secrets: never commit them in plain text

- **Current setup:** `~/.bashrc.local` (untracked), see [shell](shell.md).
- **Password manager:** `export X={{ onepasswordRead "op://Vault/Item/field" | quote }}`
  (also `bitwarden`, `pass`, `keepassxc`, `gopass`, `secret`).
- **age:** `encryption = "age"` + `[age]` identity/recipient in config, then `chezmoi add --encrypt <file>`.

Before committing: `chezmoi git -- diff --cached | grep -iE 'key|token|secret'`

## chezmoi config (in `.chezmoi.toml.tmpl`, enabled)

Diffs page through `delta`, `chezmoi edit` uses nvim and applies on exit, and `chezmoi merge` opens `nvim -d`.
After changing this file, run `chezmoi init` to regenerate `~/.config/chezmoi/chezmoi.toml`.

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
