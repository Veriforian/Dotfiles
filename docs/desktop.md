# Desktop

[← README](../README.md) · Last updated: 2026-10-16

Hyprland (Lua config) and the foot terminal. Defaults live in `/usr/share/omarchy/` (read-only); user overrides in `~/.config/`.

## Tracked files

| File | Status vs Omarchy default |
|---|---|
| `~/.config/hypr/bindings.lua` | Stock (tracked so future changes sync) |
| `~/.config/hypr/looknfeel.lua` | Stock |
| `~/.config/hypr/input.lua` (template) | Stock + VM-only lines (below) |
| `~/.config/foot/foot.ini` | Stock |

Check what's actually customized with `diff /usr/share/omarchy/config/<path> ~/.config/<path>`.

### `hypr/input.lua.tmpl`

On the VM only (`{{ if .vm }}`), it loads:
- `/usr/share/try-omarchy/pinch-input.lua`: the host pinch device carries gestures only.
- `/usr/share/try-omarchy/apple-keyboard-input.lua`: Apple keyboard geometry (`applealu_ansi`) from the kernel cmdline.

## Applying changes

- Hyprland auto-reloads on save. Validate with `hyprctl reload && hyprctl configerrors`.
- foot: new windows pick up changes (`omarchy restart terminal`).

## Omarchy drift

`omarchy update` / `omarchy refresh <x>` can rewrite these files. Afterwards run `chezmoi status`, then
apply, re-add or merge each changed file (see [workflow](workflow.md#after-omarchy-update--omarchy-refresh)).
Since most files here are still stock, accepting Omarchy's new version (`chezmoi re-add`) is usually right.

## Keyboard notes

- Keyboard is used in "Windows" mode: Super = Windows key.
- Terminal copy/paste: `Ctrl+Shift+C` / `Ctrl+Shift+V` (foot default). In tmux, hold `Shift` while drag-selecting.
- The VM keymap has no Insert key, so foot warns `Control+KP_0 … replacing with KP_Insert`. Harmless.
