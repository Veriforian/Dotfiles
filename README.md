# Dotfiles

Personal [Omarchy](https://omarchy.org) configuration, managed with [chezmoi](https://www.chezmoi.io).
One repo drives every machine; per-machine differences are handled with templates.

| Machine | Arch | Notes |
|---|---|---|
| Personal Omarchy desktop | `amd64` | Primary dev box |
| Try Omarchy VM on the work Mac | `arm64` (`archarm`) | `.vm = true`; extra VM-only fixes |

## Quick start

```bash
# New machine
chezmoi init --apply git@github.com:Veriforian/Dotfiles.git
# Then create ~/.bashrc.local for secrets (see docs/shell.md)

# Day to day
chezmoi edit <file>      # or edit live, then: chezmoi re-add
chezmoi diff && chezmoi apply
chezmoi git -- add -A && chezmoi git -- commit -m "..." && chezmoi git -- push
```

## Documentation

| Doc | Covers |
|---|---|
| [Workflow](docs/workflow.md) | Everyday chezmoi flow, command reference, attributes, secrets |
| [Machines](docs/machines.md) | Machine data (`vm`, `work`, `email`), per-machine differences, bootstrapping |
| [Scripts & packages](docs/scripts.md) | `run_onchange_*` scripts and `.chezmoidata/packages.yaml` |
| [Shell](docs/shell.md) | `.bashrc` customizations, `.bashrc.local` secrets |
| [Neovim](docs/neovim.md) | LazyVim options, keymaps, commands, plugins |
| [Desktop](docs/desktop.md) | Hyprland, Omarchy theme, foot terminal, Omarchy drift |
| [Tools](docs/tools.md) | git, mise, tmux (+ plugins), starship, lazygit |
| [Troubleshooting](docs/troubleshooting.md) | Problems solved so far and their fixes |
| [Changelog](docs/changelog.md) | Dated log of config changes |

## Repo layout

```
.chezmoi.toml.tmpl          per-machine prompts → ~/.config/chezmoi/chezmoi.toml
.chezmoidata/packages.yaml  package list for the install script
.chezmoiignore              targets chezmoi must not touch (incl. these docs)
.chezmoiexternal.toml.tmpl  git repos chezmoi clones into ~ (tmux plugins, Omarchy theme)
run_onchange_*.sh.tmpl      setup scripts (see docs/scripts.md)
dot_bashrc                  → ~/.bashrc
dot_config/                 → ~/.config/
README.md, docs/            repo-only documentation (never deployed)
```

## Keeping docs current

Docs are part of the change. When a config change is committed, the same commit should:

1. Update the doc that describes that area (the table above maps area → doc).
2. Add a line to [docs/changelog.md](docs/changelog.md).
3. Bump the doc's `Last updated` line.

Quick check that nothing was missed:

```bash
chezmoi git -- diff --cached --stat   # config files changed? docs/ should be in the list too
```
