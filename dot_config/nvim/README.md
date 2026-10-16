# nvim

Personal Neovim configuration. Built on [LazyVim](https://github.com/LazyVim/LazyVim) with `lazy.nvim` for plugin management. Designed to bootstrap a working editor on a fresh macOS or Linux box in one command.

## What's in here

- **LazyVim base** with custom overrides under `lua/plugins/`.
- **Language support** (via LazyVim extras in `lazyvim.json`): Go, Python, TypeScript, Vue, Svelte, PHP, Zig, Docker, SQL, Tailwind, Markdown, JSON, TOML, YAML, Git.
- **Tooling**: fzf-lua, harpoon2, edgy, mini-hipatterns, inc-rename, prettier, eslint, dial, yanky.
- **Debugging**: nvim-dap (+nlua adapter, mason-nvim-dap).
- **Terminals**: toggleterm + lazydocker.
- **AI / completion**: blink.cmp, minuet (Gemini ghost-text), opencode, plus parked specs for avante / copilot / windsurf.
- **Markdown / snippets**: render-markdown, sniprun.

See `CLAUDE.md` for layout and conventions.

## Requirements

- **Neovim ≥ 0.10** (LazyVim requirement).
- A **Nerd Font** in your terminal — install one from https://www.nerdfonts.com.
- A **true-color terminal** (kitty, wezterm, alacritty, iTerm2, modern Linux terminals). The config sets `termguicolors`.
- **macOS** (Homebrew) or **Linux** (apt / dnf / pacman / apk).

## Install

```sh
git clone https://github.com/<you>/nvim ~/code/nvim
cd ~/code/nvim
./install.sh
```

The script:

1. Detects your package manager (brew / apt / dnf / pacman / apk).
2. Installs Neovim and dependencies the plugins expect: `git`, `curl`, build tools, `ripgrep`, `fd`, `fzf`, `lazygit`, Node + npm, Python 3 + pip, `stylua`, `lazydocker`.
3. Symlinks the repo into `~/.config/nvim` (backing up any existing config).
4. Runs `nvim --headless "+Lazy! sync"` to install plugins, then updates Mason.

It is idempotent — safe to re-run. Already-installed binaries are skipped.

You can also clone directly into `~/.config/nvim` and skip the symlink step:

```sh
git clone https://github.com/<you>/nvim ~/.config/nvim
~/.config/nvim/install.sh
```

## Optional environment

| Variable | Used by | Purpose |
|---|---|---|
| `GEMINI_API_KEY` | `lua/plugins/minuet.lua` | Enables AI ghost-text completions via Gemini. |

## Layout

```
init.lua              -> bootstraps lua/config/lazy.lua
lua/config/           -> lazy.nvim setup, options, keymaps, autocmds
lua/plugins/          -> plugin specs (one file per plugin or group)
lazyvim.json          -> enabled LazyVim "extras"
lazy-lock.json        -> committed plugin version lock
stylua.toml           -> 2-space, 120-col Lua formatting
```

## Updating

```sh
# inside Neovim
:Lazy update         # plugins
:Mason               # LSPs / formatters / DAPs
```

Then commit `lazy-lock.json` if you want the new versions pinned.

## Troubleshooting

- **Treesitter parsers fail to compile**: install a C compiler (`xcode-select --install` on macOS; `build-essential` / `base-devel` on Linux). The install script does this for you.
- **`lazygit` missing on apt/dnf**: those repos often don't ship it. The install script falls back to `go install` if Go is present; otherwise grab a release binary from https://github.com/jesseduffield/lazygit/releases.
- **Icons render as boxes**: your terminal isn't using a Nerd Font.
