# Desktop

[← README](../README.md) · Last updated: 2026-10-16

Hyprland (Lua config), the Omarchy theme and the foot terminal. Defaults live in `/usr/share/omarchy/` (read-only); user overrides in `~/.config/`.

## Tracked files

| File | Status vs Omarchy default |
|---|---|
| `~/.config/hypr/bindings.lua` | Stock (tracked so future changes sync) |
| `~/.config/hypr/looknfeel.lua` | No gaps, terminal-only opacity (below) |
| `~/.config/hypr/input.lua` (template) | Stock + VM-only lines (below) |
| `~/.config/foot/foot.ini` | Stock |

Check what's actually customized with `diff /usr/share/omarchy/config/<path> ~/.config/<path>`.

### `hypr/looknfeel.lua`

`general.gaps_in = 0` and `gaps_out = 0`: windows tile edge to edge, with no gap at the screen edge either (Omarchy default 5 / 10).
`border_size` stays at Omarchy's 2 so the focused window keeps its accent border. Set `border_size = 0` in the same block
for no borders as well. For gaps between windows only, set `gaps_out` back to 10.

**Opacity:** only terminals are translucent, at `0.90` focused / `0.85` unfocused. Every other window is `1 1`.
Omarchy's default is `0.985 / 0.96` on every window, and browsers get `1.0 / 0.985`. Two rules at the end of the file
do this. They load after Omarchy's rules, and the last matching rule wins:
- `o.window(".*", { opacity = "1 1" })`
- `o.window({ tag = "terminal" }, ...)`. The `terminal` tag is Omarchy's, from `default/hypr/apps/terminals.lua`. It covers
  foot, Alacritty, kitty, Ghostty, WezTerm and Omarchy's TUI windows (`org.omarchy.*`, `TUI.*`).
- Tune the terminal by changing the two numbers. `Super+Backspace` still toggles a single window opaque.
- Blur stays off (Omarchy default), so the wallpaper shows through sharp. `decoration.blur.enabled = true` would only
  blur the terminal, since nothing else is translucent.
- Check live: `hyprctl getprop active opacity`.

### `hypr/input.lua.tmpl`

On the VM only (`{{ if .vm }}`), it loads:
- `/usr/share/try-omarchy/pinch-input.lua`: the host pinch device carries gestures only.
- `/usr/share/try-omarchy/apple-keyboard-input.lua`: Apple keyboard geometry (`applealu_ansi`) from the kernel cmdline.

## Theme: One Dark Pro

[One Dark Pro](https://omarchy.gallery/themes/one-dark-pro) by sc0ttman (`github.com/sc0ttman/omarchy-one-dark-pro-theme`),
from the Omarchy theme gallery. It has a palette, 8 wallpapers (`omarchy theme bg next` cycles them; ~37 MB clone),
a lock screen image and `Yaru-blue-dark` icons.

The repo also has a `neovim.lua` and a `starship.toml`, but neither is used: Omarchy drops `*.lua` from installed themes,
and it never reads a theme's `starship.toml` (its README says to copy it by hand). `~/.config/starship.toml` stays stock.

- **Install:** `.chezmoiexternal.toml.tmpl` clones it into `~/.config/omarchy/themes/one-dark-pro`, the same place
  `omarchy theme install` uses. chezmoi pulls updates at most weekly.
- **Apply:** `run_onchange_after_40-omarchy-theme.sh.tmpl` runs `omarchy theme set one-dark-pro` (see [scripts](scripts.md)).
  It only re-runs when the script changes, so `omarchy theme set <other>` by hand sticks until the script is edited.
- **Switching for good:** change `theme=` in that script (and add or swap its externals entry), then `chezmoi apply`.
- **Not themed by it:** tmux (themepack sets its own status bar, see [tools](tools.md#tmux-configtmuxtmuxconf)) and nvim
  (its own `onedark.nvim`, style `darker`, see [neovim](neovim.md)).
- Don't run `omarchy theme install` for this theme: it deletes the clone and re-clones it, so chezmoi re-pulls it on the next apply.
  It still works, but there's no need.

## Applying changes

- Hyprland auto-reloads on save. Validate with `hyprctl reload && hyprctl configerrors`.
- foot: new windows pick up changes (`omarchy restart terminal`).
- Theme: `omarchy theme set one-dark-pro` re-applies it (regenerates terminal, hypr border, btop, etc. from `colors.toml`).

## Omarchy drift

`omarchy update` / `omarchy refresh <x>` can rewrite these files. Afterwards run `chezmoi status`, then
apply, re-add or merge each changed file (see [workflow](workflow.md#after-omarchy-update--omarchy-refresh)).
Since most files here are still stock, accepting Omarchy's new version (`chezmoi re-add`) is usually right.

## Keyboard notes

- Keyboard is used in "Windows" mode: Super = Windows key.
- Terminal copy/paste: `Ctrl+Shift+C` / `Ctrl+Shift+V` (foot default). In tmux, hold `Shift` while drag-selecting.
- The VM keymap has no Insert key, so foot warns `Control+KP_0 … replacing with KP_Insert`. Harmless.
