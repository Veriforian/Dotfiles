# Neovim

[← README](../README.md) · Last updated: 2026-10-16

Source: `dot_config/nvim/` → `~/.config/nvim`. LazyVim base with overrides in `lua/plugins/`.
Deeper notes live in the config's own [`README.md`](../dot_config/nvim/README.md) and `CLAUDE.md`.

> chezmoi is the source of truth. The old `~/.config/nvim/.git` repo is ignored (`.chezmoiignore`),
> and **don't run `install.sh`**: its symlink step would replace the chezmoi-managed directory.

## Options (`lua/config/options.lua`)

- Line numbers: absolute + relative. 2-space indent, `expandtab`, `smartindent`.
- No swap or backup files; persistent undo in `~/.nvim/undodir`.
- `hlsearch` off, `incsearch` on, `scrolloff=8`, `colorcolumn=80`, `wrap` on, `updatetime=50`.
- Treesitter folding. Snacks animations disabled.

## Keymaps (`lua/config/keymaps.lua`), leader = `Space`

| Key | Mode | Action |
|---|---|---|
| `<leader>pv` | n | netrw (`:Ex`) |
| `J` / `K` | v | Move selection down / up |
| `<leader>p` | x | Paste without yanking the replaced text |
| `<leader>y` / `<leader>Y` | n,v / n | Yank to system clipboard |
| `<leader>d` | n,v | Delete to black hole register |
| `<C-c>` | i,x | Escape |
| `<leader>*` | n | Highlight word without jumping |
| `<leader>o` / `<leader>O` | n | Blank line below / above, stay in normal mode |
| `Q`, `<C-m>`, `<C-d>` | n,v | Disabled |
| `<Esc><Esc>` | t | Leave terminal mode |
| `<C-b>` / `<C-f>`, `<C-y>` / `<C-e>`, `zt`/`zz`/`zb`, `F13`–`F16` | n,v,x | Smooth scrolling (neoscroll) |

### Plugin keymaps

| Key | Action | From |
|---|---|---|
| `<leader>gg` / `<leader>gG` | lazygit (root / cwd) | LazyVim (requires `lazygit`) |
| `<leader>ld` | Lazydocker float | `lazydocker.lua` |
| `<leader>ad` / `ar` / `aI` / `ay` | LSP definition / references / implementation / type def (fzf-lua) | `lsp-config.lua` |
| `<leader>d*` | DAP: `b` breakpoint, `B` conditional, `c` continue, `a` run with args, `C` to cursor, `i`/`o`/`O` step, `r` REPL, `t` terminate | `nvim-dap.lua` |
| `<leader><space>`, `<leader>/`, `<leader>f*`, `<leader>s*` | fzf-lua pickers (LazyVim layout) | `fzf-lua.lua` |
| `<leader>gc` / `<leader>gs` | Git commits / status | `fzf-lua.lua` |

## Commands & autocmds (`lua/config/autocmds.lua`)

| Item | Does |
|---|---|
| `:CopyPath` | Copy the absolute file path to the clipboard |
| `:CopyRelativePath` | Copy the path relative to the project root (`package.json` / `index.js` / `init.lua`) |
| Diagnostics off | For `*.env*` and `*.md` buffers |
| Shada cleanup | Deletes stale `main.shada.tmp.*` files older than a day on startup |

## Plugins (`lua/plugins/`)

| Plugin | State | Notes |
|---|---|---|
| auto-save.nvim | on | Saves on InsertLeave / TextChanged / FocusLost |
| blink.cmp | on | Completion |
| tokyonight + themery | on | Theme switcher: tokyonight, nord, onedark |
| fzf-lua | on | Pickers |
| snacks.nvim | on | Includes mermaid rendering (`mermaid-render.lua`) |
| render-markdown | on | LaTeX disabled |
| minuet-ai | on | Gemini ghost text, needs `GEMINI_API_KEY` |
| neoscroll | on | Smooth scrolling |
| nvim-dap, dap-ui, mason-nvim-dap | on | Debugging |
| lazydocker.nvim | on | `<leader>ld` |
| toggleterm | on | `<C-/>` toggles the last terminal, `<leader>t*` |
| sniprun, vim-visual-multi, lua-json5 | on | |
| avante, copilot, windsurf, opencode | **off** | Parked (`enabled = false`) |

LazyVim extras (`lazyvim.json`): yanky, dap (core, nlua), dial, fzf, harpoon2, inc-rename, snacks_picker, prettier,
eslint, edgy, dot, mini-hipatterns, plus language support for docker, git, go, json, markdown, php, python, rust, sql,
svelte, tailwind, toml, typescript, vue, yaml and zig.

## Maintaining

- After `:Lazy update`: `chezmoi re-add ~/.config/nvim/lazy-lock.json`, then commit. Other machines restore on apply.
- After editing a Lua file live: `chezmoi re-add`. New plugin file: `chezmoi add ~/.config/nvim/lua/plugins/<file>.lua`.
- New external dependency (binary)? Add it to [packages](scripts.md#packages-chezmoidatapackagesyaml).
- Update the tables above and the [changelog](changelog.md).
