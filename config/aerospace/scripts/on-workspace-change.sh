#!/bin/bash
# Runs on every workspace change via exec-on-workspace-change in aerospace.toml.
# Queries visible workspaces ONCE here (not per item in spaces.sh) and passes via trigger env vars.
# `--monitor all` works for any monitor count; a hardcoded `--monitor 2` errors on
# laptop-only, leaves the var empty, and pushes spaces.sh onto the slow CLI path.
#
# Trailing debounce: fast workspace switching fires this repeatedly, and each run
# makes an aerospace CLI call back into the single-threaded WM server. A fresh
# switch kills the pending invocation, so a burst collapses into ONE query+trigger
# after 60ms of quiet instead of N of them piling up behind the switch ops.

PIDFILE="/tmp/aerospace_on_workspace_change.pid"
FOCUSED="$AEROSPACE_FOCUSED_WORKSPACE"

[ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null

(
  echo "$BASHPID" > "$PIDFILE"
  sleep 0.06

  VISIBLE=$(aerospace list-workspaces --monitor all --visible 2>/dev/null | tr '\n' ' ')

  "$HOME"/.config/aerospace/scripts/sb-trigger.sh aerospace_workspace_change \
    FOCUSED_WORKSPACE="$FOCUSED" \
    VISIBLE="$VISIBLE"

  rm -f "$PIDFILE"
) &
