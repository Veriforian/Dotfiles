# Troubleshooting

[← README](../README.md) · Last updated: 2026-10-16

Problems hit so far, newest first. Add new ones at the top with symptom → cause → fix.

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
