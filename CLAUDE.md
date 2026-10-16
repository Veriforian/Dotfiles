# Dotfiles repo (chezmoi source)

- Docs live in `README.md` + `docs/`. **Every config change must update the matching doc in the same change**:
  the area → doc map is the table in `README.md`. Also add a dated line to `docs/changelog.md` and bump
  the doc's `Last updated` date.
- New problem solved? Add symptom → cause → fix to the top of `docs/troubleshooting.md`.
- Never commit secrets. They belong in untracked `~/.bashrc.local`; docs list variable names only.
- Repo-only files (`README.md`, `docs/`, this file) must stay in `.chezmoiignore`.
- Verify with `chezmoi status` / `chezmoi diff` before suggesting `chezmoi apply`; scripts that need sudo are run by the user.
