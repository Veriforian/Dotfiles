# Troubleshooting

[← README](../README.md) · Last updated: 2026-10-16

Problems hit so far, newest first. Add new ones at the top with symptom → cause → fix.

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
