#!/bin/bash
# Size every window of a client's session to that client's screen, so windows
# restored by tmux-resurrect/continuum (or last viewed on another monitor)
# don't keep the old size and pane proportions. Panes are scaled
# proportionally. Afterwards each window's size is handed back to tmux
# (window-size unset -> global "latest"), so nothing stays pinned.
# Run by hooks in tmux.conf (attach, session switch, terminal resize, after a
# restore) and by prefix + F. Docs: docs/tools.md#tmux
#
# Usage: fit-windows.sh [client]   (default: the current/most recent client)
set -uo pipefail

client=${1:-}
target=()
[ -n "$client" ] && target=(-c "$client" -t "$client")   # -t: the client's own session

# The active window is already sized to the client by tmux; use its size
# (client height minus the status line).
read -r width height session < <(tmux display-message -p "${target[@]}" \
  '#{window_width} #{window_height} #{session_name}' 2>/dev/null) || exit 0
[ -n "${session:-}" ] || exit 0

tmux list-windows -t "=$session" -F '#{window_id} #{window_width} #{window_height}' |
while read -r win w h; do
  [ "$w" = "$width" ] && [ "$h" = "$height" ] && continue
  tmux resize-window -t "$win" -x "$width" -y "$height"
  tmux set-option -wu -t "$win" window-size   # resize-window pinned it to manual
done
exit 0
