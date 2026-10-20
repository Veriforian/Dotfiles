# Desktop

[← README](../README.md) · Last updated: 2026-10-19

Hyprland (Lua config), the Omarchy theme and the foot terminal. Defaults live in `/usr/share/omarchy/` (read-only); user overrides in `~/.config/`.

## Tracked files

| File | Status vs Omarchy default |
|---|---|
| `~/.config/hypr/bindings.lua` | Stock (tracked so future changes sync) |
| `~/.config/hypr/looknfeel.lua` | No gaps, terminal-only opacity (below) |
| `~/.config/hypr/input.lua` (template) | Stock + VM-only lines (below) |
| `~/.config/hypr/autostart.lua` | Vesktop in the tray (below) |
| `~/.config/vesktop/settings/settings.json` | `modify_` script: only CustomIdle (below) |
| `~/.config/hypr/xdph.conf` | `modify_` script: VMs only, `screencopy:force_shm` ([screen sharing](#screen-sharing)) |
| `~/.config/vesktop/settings.json` | `modify_` script: only `webRTCIPHandlingPolicy` ([voice calls](#discord-voice-calls)) |
| `~/.config/foot/foot.ini` | Stock |
| `~/.config/omarchy/themed/foot.ini.tpl` | Darker terminal background (below) |
| `~/.config/omarchy/hooks/theme-set.d/10-darker-terminal-bg` | Keeps open terminals and tmux darker after a theme change (below) |

Check what's actually customized with `diff /usr/share/omarchy/config/<path> ~/.config/<path>`.

### `hypr/looknfeel.lua`

`general.gaps_in = 0` and `gaps_out = 0`: windows tile edge to edge, with no gap at the screen edge either (Omarchy default 5 / 10).
`border_size` stays at Omarchy's 2 so the focused window keeps its accent border. Set `border_size = 0` in the same block
for no borders as well. For gaps between windows only, set `gaps_out` back to 10.

**Opacity:** only terminals are translucent, at `0.90` focused / `0.85` unfocused. Every other window is `1 1`.
Omarchy's default is `0.985 / 0.96` on every window, and browsers get `1.0 / 0.985`. Two rules at the end of the file
do this. They load after Omarchy's rules, and the last matching rule wins:
- `o.window(".*", { opacity = "1 1" })`
- `o.window(terminal_classes, ...)`: matched by **class**, using the same list as Omarchy's `default/hypr/apps/terminals.lua`.
  It covers foot, Alacritty, kitty, Ghostty, WezTerm and Omarchy's TUI windows (`org.omarchy.*`, `TUI.*`).
  - Don't match on Omarchy's `terminal` tag. It's set by another rule, and on rule re-evaluation (every title change)
    a tag-matched rule only applies every other time (see [troubleshooting](troubleshooting.md)).
  - If Omarchy adds a terminal to `terminals.lua`, add it to `terminal_classes` too.
- Tune the terminal by changing the two numbers. `Super+Backspace` still toggles a single window opaque.
- Blur stays off (Omarchy default), so the wallpaper shows through sharp. `decoration.blur.enabled = true` would only
  blur the terminal, since nothing else is translucent.
- Check live: `hyprctl getprop active opacity`.
- Needs Omarchy's *Window Opacity* mode on **Transparent** (the default). *Opaque* and *Glassy* are toggle files that load
  after `looknfeel.lua` and override it. Omarchy turns *Opaque* on for VMs, so `run_onchange_after_42-window-transparency`
  switches it back (see [scripts](scripts.md), [troubleshooting](troubleshooting.md)).

### `hypr/input.lua.tmpl`

On Try Omarchy only (each include is guarded by `stat` of its own file, not `.vm`), it loads:
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

## Monitors

**Tool: [hyprmon](https://github.com/erans/hyprmon)** (`hyprmon-bin`, AUR). It's a terminal UI: arrange displays visually,
set mode, scale and position, and save profiles.
- Changes apply live (`hyprctl keyword monitor …`). Saving writes `~/.config/hypr/hyprmon.lua` and adds `require("hyprmon")`
  to `hyprland.lua` the first time. It backs a file up as `<file>.bak.<timestamp>` before changing it.
- `hyprmon.lua` is **not** tracked yet. Layouts are per machine (output names differ), so add it once the desktop layout is
  settled, probably as a template keyed on the machine.
- Omarchy's own **Display** panel (`Super+Ctrl+D`) only has brightness, scale and laptop-display toggles; it can't arrange
  displays. `nwg-displays` (repo, writes hyprlang `monitors.conf`) doesn't fit the Lua config.

**VM: only one display.** The guest has one QEMU virtio-gpu output (`Virtual-1`), and only the Mac host app can add more
(QEMU `max_outputs`). Try Omarchy runs QEMU's Cocoa frontend and sizes `Virtual-1` to its window
(`/usr/local/bin/omarchy-native-display-sync`). Nothing in the guest can create a second monitor.
- **Don't save a hyprmon layout on the VM.** A rule for `Virtual-1` would override that window-following rule
  in `monitors.lua`, so the VM would stop resizing with its window.
- Options: look in Try Omarchy's settings on the Mac for a display count. Or (untested) turn off macOS
  *Displays have separate Spaces* and stretch the VM window across both screens, giving one wide `Virtual-1`.
  Real dual-monitor use is for the Omarchy desktop.

## Audio latency (Try Omarchy VM)

The VM has no Bluetooth. Audio goes guest PipeWire → emulated Intel HDA → QEMU → macOS → Bluetooth headset. Try Omarchy
routes to each Mac device through `omarchy_host_output_*` loopback sinks (e.g. "MOMENTUM 4").

| Stage | Delay | Ours to change? |
|---|---|---|
| Guest PipeWire quantum | Try Omarchy pins **4096 frames ≈ 85 ms** (`/usr/share/pipewire/pipewire.conf.d/90-try-omarchy-quantum.conf`), 1–2 quanta in flight | Yes |
| QEMU → macOS | Small (host: 1 ms timer, 8 buffers) | No (host app) |
| macOS → BT headset (A2DP/AAC) | ~150–250 ms, typical for BT | No |

- **Override:** `~/.config/pipewire/pipewire.conf.d/99-vm-audio-latency.conf` (template) pins it to **2048 ≈ 43 ms**.
  - It only renders where Try Omarchy's `90-…` file exists. OmacVM and the desktop get nothing.
  - Trade-off: Try Omarchy raised the quantum because the emulated HDA reports its position in coarse jumps, and
    smaller quanta can cause dropouts (xruns). If audio crackles, raise the value; 3072 is a middle ground.
- **Try a value live first** (nothing written; resets on restart or with `0`):
  `pw-metadata -n settings 0 clock.force-quantum 2048`, then `… 0` to undo.
- **Apply:** `chezmoi apply`, then `systemctl --user restart pipewire pipewire-pulse wireplumber`.
- **Check:** `pw-metadata -n settings 0 | grep quantum` → `2048`. `pw-top` shows the quantum in use and any errors (ERR column).

## Screen sharing

- **Problem (VMs):** shares from Vesktop or a browser are black. The VM's `virtio_gpu` has no DRM format modifiers
  (Hyprland log: `supportsAddFb2Modifiers: false`), so `xdg-desktop-portal-hyprland` and Chromium never agree on a
  DMA-BUF format. The portal log loops on `[sc] Incompatible formats, renegotiate stream`.
- **Fix:** `screencopy { force_shm = true }` in `~/.config/hypr/xdph.conf`: frames go through shared memory instead of
  GPU buffers (a bit more CPU). Omarchy installs that file, so `dot_config/hypr/modify_xdph.conf.tmpl` only adds the
  line, and only when `.vm` is true. Real GPUs keep DMA-BUF.
- **Takes effect** when the portal restarts: `systemctl --user restart xdg-desktop-portal-hyprland` (or log in again).
- Check: `journalctl --user -u xdg-desktop-portal-hyprland -f` while starting a share shows
  `DMA-BUF disabled (force_shm), using SHM only`.

## Discord voice calls

- **Problem:** calls stick on "DTLS connecting", with Mullvad on or off. Vesktop (Chromium) on Linux with extra
  interfaces (the `work` WireGuard, Mullvad, `docker0`) offers WebRTC candidates on all of them and the handshake
  stalls. Known upstream: [Vesktop#1356](https://github.com/Vencord/Vesktop/issues/1356), fixed in code by
  [#1251](https://github.com/Vencord/Vesktop/pull/1251). The official Discord client isn't affected.
- **Fix:** `webRTCIPHandlingPolicy: "default_public_and_private_interfaces"` in `~/.config/vesktop/settings.json`
  (Settings → Vesktop → WebRTC IP handling), which keeps WebRTC on the default-route interface. Set by
  `dot_config/private_vesktop/modify_settings.json`, a `modify_` script like the CustomIdle one: `jq` sets only that
  key and keeps Vesktop's format (4-space indent, no final newline).
- **Apply with Vesktop closed**, then start it (`hyprctl dispatch 'hl.dsp.exec_cmd("vesktop")'` or the launcher).

## Discord presence (Vesktop + CustomIdle)

Goal: stay "Online" in Discord while away from the keyboard. It replaces [keep-presence](https://github.com/carrot69/keep-presence),
which is unmaintained and doesn't work on Wayland.

- **How:** Vesktop ships Vencord, and its **CustomIdle** plugin with `idleTimeout: 0` turns off Discord's auto-idle
  (the timeout becomes infinite). `remainInIdle: false` means you go back online on your own if you ever do go idle.
- **Why not an input jiggler:** on Wayland that needs `ydotool` with a root `uinput` daemon. The fake input would
  also reset hypridle, so the screen would never lock. CustomIdle only touches Discord's own timer.
- **Managed by:** `dot_config/private_vesktop/settings/modify_settings.json`, a chezmoi `modify_` script. It takes the
  live file, uses `jq` to set only `plugins.CustomIdle`, and leaves the rest (other plugins, theme, …) as Vesktop wrote it.
  Its output uses Vencord's format (4-space indent, no final newline), so Vesktop saves don't show up in `chezmoi diff`.
- **Install:** `vesktop-bin` (AUR) is in `packages.yaml` under `aur:` (see [scripts](scripts.md)).
- **Autostart:** `hypr/autostart.lua` runs `vesktop --start-minimized` at login (tray only). Presence only holds while Vesktop runs.
- **Apply with Vesktop closed**, or restart it after `chezmoi apply`. A running Vesktop can write its in-memory settings
  over the file, and CustomIdle's timeout only takes effect after a restart.
- **Check:** Vesktop → Settings → Vencord → Plugins → CustomIdle (on, timeout 0), or
  `jq .plugins.CustomIdle ~/.config/vesktop/settings/settings.json`.
- **Limits:** this only controls the desktop client. If Vesktop is closed, Discord shows you offline (or whatever your
  phone reports).

## Terminal background: darker than the theme

foot's background is **~30% darker** than the theme's (One Dark Pro: `#282c34` → `#1c1f24`). The rest of the palette is
unchanged, and it works for any theme.

- **`~/.config/omarchy/themed/foot.ini.tpl`:** a copy of Omarchy's `default/themed/foot.ini.tpl`. User templates
  override the built-in one by name. `background`, `regular0` and the cursor text colour use
  `{{ mix_strip background darker_background 75% }}`.
  - **Tune:** 50% ≈ 20% darker, 75% ≈ 30%, 100% = the theme's `darker_background` (≈ 40%). Change all three lines.
  - Needs a `darker_background` key in the theme's `colors.toml`. Stock themes and One Dark Pro have one. Without it
    the token isn't filled in and foot rejects the config.
  - Omarchy's own template won't reach us any more. After big Omarchy updates, diff it with
    `/usr/share/omarchy/default/themed/foot.ini.tpl`.
- **`theme-set.d/10-darker-terminal-bg` hook:** on every `omarchy theme set`, Omarchy pushes the theme's plain
  background into open foot windows and tmux (OSC 11 plus tmux `window-style`). The hook runs after that and pushes
  the darker colour from the generated `foot.ini` instead. Without it, tmux would stay at the lighter background until
  the tmux server restarts.
- **`run_onchange_after_45-omarchy-themed.sh.tmpl`:** re-applies the *current* theme when the template or hook changes,
  so `chezmoi apply` is enough.
- **Why not a second `include=` in `foot.ini`:** foot treats a missing include file as a fatal config error
  (`foot --check-config` exits non-zero), and the generated file doesn't exist until the next theme set.
- **Check:** `grep ^background ~/.local/state/omarchy/current/theme/foot.ini` → `1c1f24`; `tmux show -g window-style`.

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
