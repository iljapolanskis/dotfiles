#!/bin/bash
# Runs on every workspace change via exec-on-workspace-change in aerospace.toml.
# Queries visible workspaces ONCE here (not 10x in space.sh) and passes via trigger env vars.
#
# Trailing debounce: fast workspace switching fires this repeatedly, and each run
# makes 2 aerospace CLI calls back into the single-threaded WM server. A fresh
# switch kills the pending invocation, so a burst collapses into ONE query+trigger
# after 60ms of quiet instead of N of them piling up behind the switch ops.

PIDFILE="/tmp/aerospace_on_workspace_change.pid"
FOCUSED="$AEROSPACE_FOCUSED_WORKSPACE"

[ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null

(
  echo "$BASHPID" > "$PIDFILE"
  sleep 0.06

  VISIBLE_M1=$(aerospace list-workspaces --monitor 1 --visible 2>/dev/null | head -1)
  VISIBLE_M2=$(aerospace list-workspaces --monitor 2 --visible 2>/dev/null | head -1)

  /Users/ilja.polanskis/.config/aerospace/scripts/sb-trigger.sh aerospace_workspace_change \
    FOCUSED_WORKSPACE="$FOCUSED" \
    VISIBLE_M1="$VISIBLE_M1" \
    VISIBLE_M2="$VISIBLE_M2"

  rm -f "$PIDFILE"
) &
