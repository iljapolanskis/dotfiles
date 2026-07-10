#!/usr/bin/env bash

# Shows "<position>/<total>" of focused window in its workspace.
# Subscribed to window_focus_changed / aerospace_workspace_change / front_app_switched,
# all of which can fire in rapid bursts (nav keybinds, fast workspace switching).
#
# Two anti-lag measures:
#  1. Trailing debounce — a fresh event kills the pending one, so a burst of N
#     events results in ONE aerospace query after 80ms of quiet, not N*queries.
#     AeroSpace's server is single-threaded; coalescing here prevents the query
#     pileup that caused stalls/freezes during heavy navigation.
#  2. Two CLI calls instead of three — the workspace window list is fetched once
#     and reused for both the count and the position lookup.

PIDFILE="/tmp/sketchybar_window_count.pid"

# Kill any still-pending invocation so only the latest event does real work.
[ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null

(
  echo "$BASHPID" > "$PIDFILE"
  sleep 0.08

  FOCUSED_ID=$(aerospace list-windows --focused --format "%{window-id}" 2>/dev/null | tr -d '[:space:]')

  # Single fetch of the focused workspace's window list — reused for count + position.
  LIST=$(aerospace list-windows --workspace focused --format "%{window-id}" 2>/dev/null)
  TOTAL=$(printf '%s\n' "$LIST" | grep -c .)

  # Hide when no focused window or only 1 window (nothing to navigate).
  if [ -z "$FOCUSED_ID" ] || [ "$TOTAL" -le 1 ]; then
    sketchybar --set "$NAME" drawing=off
    rm -f "$PIDFILE"
    exit 0
  fi

  # Position of focused window in tree order = navigation order.
  POSITION=$(printf '%s\n' "$LIST" | grep -n "^${FOCUSED_ID}$" | cut -d: -f1)
  [ -z "$POSITION" ] && POSITION="?"

  sketchybar --set "$NAME" label="${POSITION}/${TOTAL}" drawing=on
  rm -f "$PIDFILE"
) &
