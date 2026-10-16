# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal Neovim configuration built on top of [LazyVim](https://github.com/LazyVim/LazyVim), managed by `lazy.nvim`. There is no build/test/lint command — changes take effect when Neovim is restarted (or via `:Lazy reload <plugin>`).

## Layout

- `init.lua` — only bootstraps `lua/config/lazy.lua`.
- `lua/config/lazy.lua` — `lazy.nvim` setup. Imports `LazyVim/LazyVim` first, then everything under `lua/plugins/`. Custom plugins are NOT lazy-loaded by default (`defaults.lazy = false`); LazyVim's own plugins are.
- `lua/config/{options,keymaps,autocmds}.lua` — loaded by LazyVim at the appropriate lifecycle event. Add overrides here, not in plugin specs.
- `lua/plugins/*.lua` — each file returns a `lazy.nvim` plugin spec (or list of specs). Adding a file is the way to add or override a plugin; LazyVim merges by plugin name.
- `lazyvim.json` — declares the LazyVim "extras" enabled (langs, dap, formatters). Edit via `:LazyExtras`, not by hand if avoidable.
- `lazy-lock.json` — committed lockfile. Update via `:Lazy update` then commit.
- `.neoconf.json` — neoconf/neodev settings (lua_ls library setup for Neovim API).
- `stylua.toml` — formatting for Lua files: 2-space indent, 120 col.

## Conventions

- Indent: 2 spaces, expandtab (set both in `options.lua` and `stylua.toml`).
- Leader is `<Space>`. Don't introduce keymaps that conflict with LazyVim defaults without checking https://www.lazyvim.org/keymaps.
- To override a LazyVim plugin, create a file in `lua/plugins/` returning `{ "<plugin/name>", opts = function(_, opts) ... end }` — `lazy.nvim` deep-merges by name.
- To disable a LazyVim plugin: `{ "<plugin/name>", enabled = false }`.
- Custom keymaps that depend on a plugin's API should live in that plugin's spec `keys = {...}` (so they lazy-load), not in `keymaps.lua`. The DAP-breakpoints block in `keymaps.lua` is a deliberate exception because it requires `dap-breakpoints.api` at startup.

## Notes on installed extras

Active LazyVim extras (see `lazyvim.json`) include: dap (+nlua), fzf, harpoon2, inc-rename, prettier, eslint, edgy, mini-hipatterns, and lang extras for go/python/ts/vue/svelte/php/zig/docker/sql/tailwind/markdown/json/toml/yaml/git. Assume these are present before adding redundant plugins.
