# Troubleshooting

[← README](../README.md) · Last updated: 2026-10-19

Problems hit so far, newest first. Add new ones at the top with symptom → cause → fix.

## AUR install: `PGP keys need importing … keyserver receive failed: No route to host`

- **Seen:** installing `mullvad-vpn-bin` with yay on the Try Omarchy VM (2026-10-19). The workaround that day was
  `--keyserver hkp://keys.openpgp.org`.
- **Cause:** IPv6 doesn't work in the VM. QEMU's user-mode network gives the guest an IPv6 route (`via fe80::2`, address
  `fec0::…`), but IPv6 traffic never leaves the host: `curl -6 https://keyserver.ubuntu.com` fails with exit 7, while
  `curl -4` works. Keyservers publish IPv6 addresses, and `dirmngr` (which imports PGP keys for makepkg/yay) doesn't
  fall back to IPv4 the way browsers and curl do. When it picks an IPv6 address, the import fails.
  - Not caused by our DNS-over-TLS change: that only changes which DNS server answers, and the answers include IPv6
    addresses either way.
  - Confirmed by forcing dirmngr to IPv6 only (`disable-ipv4`) → "No keyserver available".
  - It's intermittent: 6/6 fetches worked while Mullvad was connected.
- **Fix:** `disable-ipv6` in `~/.gnupg/dirmngr.conf` on VMs (`private_dot_gnupg/dirmngr.conf.tmpl`). Then
  `gpgconf --kill dirmngr`.
- **If it still fails:** `gpg --keyserver hkps://keys.openpgp.org --recv-keys <fingerprint>`, then re-run yay.

## Terminal opacity flips between transparent and opaque

- **Symptom:** a terminal is sometimes 0.90 and sometimes fully opaque, changing on tmux pane switches or after a command.
- **Cause:** Hyprland re-evaluates window rules when a window's title changes. tmux `set-titles` and the shell prompt
  change it constantly. The terminal opacity rule matched Omarchy's `terminal` tag, which another rule sets (a dynamic
  tag). On re-evaluation the tag-matched rule only applied **every other time**, while the catch-all
  `".*" → opacity 1 1` always applied. Reproduced: consecutive title changes gave 0.9 → 1 → 0.9.
- **Fix:** match terminals by class (`terminal_classes` in `hypr/looknfeel.lua`). The class never changes for a window.
  It stayed at 0.9 / 0.85 over 6 title changes.
- **Check:** `hyprctl getprop active opacity`; change the title with `printf '\033]2;x\007'` a few times and re-check.
- **General rule:** don't key rules that must hold all the time (opacity etc.) on tags set by other rules.

## git / lazygit asks for the SSH passphrase on every commit, pull or push

- **Cause:** no SSH agent was running (`SSH_AUTH_SOCK` empty), so every ssh use decrypted the key from scratch.
  Omarchy runs gnome-keyring without its SSH part, and OpenSSH's `ssh-agent.socket` was disabled.
- **Fix:** enable the systemd user `ssh-agent.socket`, set `SSH_AUTH_SOCK`, and add `AddKeysToAgent yes` (see [tools](tools.md#ssh-agent-git-lazygit)).
- **Check:** `echo $SSH_AUTH_SOCK` → `/run/user/1000/ssh-agent.socket`; `ssh-add -l` lists the key; `systemctl --user status ssh-agent.socket`.
- **Still asked in an app opened from the launcher:** log out and back in once, so `environment.d` reaches the session.

## tmux: `prefix q` (reload) and `prefix ?` (keybindings) do nothing

- **Symptom:** neither key does anything after the Mac config was merged in (commit `5451dbb`).
- **Cause:** while the file was being edited, the `# Config and help` comment and the two `bind` lines below it were joined
  onto one line. The whole line became a comment, so tmux never created either binding.
- **Fix:** restored the three lines from the stock Omarchy version (`git show d48feab:dot_config/tmux/tmux.conf`).
- **Check:** `tmux list-keys -T prefix q` and `tmux list-keys -T prefix '?'` both print a binding.
  `git diff d48feab -- dot_config/tmux/tmux.conf` should only show lines added at the bottom.

## Discord goes Idle while AFK; keep-presence doesn't work

- **Symptom:** after ~10 min without input, Discord (Vesktop) shows Idle. [keep-presence](https://github.com/carrot69/keep-presence) does nothing on Wayland.
- **Cause:** keep-presence fakes input via X11 libraries, which can't inject input on Wayland. Discord's client idles itself after 10 min.
- **Fix:** Vencord's CustomIdle plugin with `idleTimeout: 0`, set by the `modify_settings.json` script. The screen still locks
  normally. See [desktop](desktop.md#discord-presence-vesktop--customidle).
- **Check:** `jq .plugins.CustomIdle ~/.config/vesktop/settings/settings.json` → `enabled: true, idleTimeout: 0`; restart Vesktop after changing it.

## VM: slow downloads, apps slow to start (Discord, fast.com)

- **Symptom:** fast.com takes ~10 s to start, then reaches ~200 Mb/s. Discord/Vesktop is sluggish. pacman crawls.
- **Cause 1:** ~5% of UDP DNS packets lost (QEMU NAT plus the host network; the Mac itself lost ~2.5%). Each loss costs a 3–5 s retry.
- **Cause 2:** the geo redirect `mirror.archlinuxarm.org` sent the VM to `nj.us` (~40 KB/s from Hong Kong).
- **Fix:** `run_onchange_before_05-vm-network` → DNS over TLS + `ca.us`/`tw2` mirrors. Afterwards: 0/180 slow lookups, mirror ~1.25 MB/s.
- **Check:** `resolvectl status` (Global shows `+DNSOverTLS`, link shows `Default Route: no`); `grep ^Server /etc/pacman.d/mirrorlist`.
- **Undo:** remove `/etc/systemd/resolved.conf.d/10-dns-over-tls.conf`, run
  `nmcli con mod "<con>" ipv4.ignore-auto-dns no ipv6.ignore-auto-dns no`, then restart `systemd-resolved`.

## nvim: `<leader>gg` does nothing

- **Cause:** LazyVim only creates the lazygit mappings when `lazygit` is executable.
- **Fix:** `lazygit` is in `packages.yaml`, so it's installed on every machine.

## Terminal: Ctrl+Shift+C stops copying

- **Seen once on the VM.** Config and keys were fine; a restart fixed it.
- **If it recurs:** `systemctl --user restart omarchy-native-clipboard-bridge`, or open a new terminal.

## chezmoi: `MM` on a file / apply would delete lines

- **Cause:** the live file was edited after it was added.
- **Fix:** `chezmoi diff <file>`, then `re-add` (keep live) or `merge`. Never re-add a file that contains secrets;
  move them to `~/.bashrc.local` first.
