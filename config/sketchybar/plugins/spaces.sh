#!/bin/sh

# Highlights all workspace items in ONE process and ONE batched sketchybar call.
# Usage (as the hidden `spaces` item's script): spaces.sh <ws> [<ws> ...]
# $FOCUSED_WORKSPACE — passed via aerospace_workspace_change trigger
# $VISIBLE           — space-separated visible workspaces, all monitors
#                      (queried once in on-workspace-change.sh)
#
# Why one script instead of a script per item: every exec on this machine is
# vetted by ThreatLocker, so a burst of ~30 execs (10 items x shell + script +
# sketchybar --set) queues up and delays the highlight by ~1s.

# Trust event-passed vars; hit the CLI only for system_woke / forced --update.
if [ "$SENDER" != "aerospace_workspace_change" ]; then
  FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null)
  VISIBLE=$(aerospace list-workspaces --monitor all --visible 2>/dev/null | tr '\n' ' ')
fi

set_args=""
for ws in "$@"; do
  if [ "$ws" = "$FOCUSED_WORKSPACE" ]; then
    props="background.drawing=on background.color=0x60ffffff label.drawing=on"
  else
    case " $VISIBLE " in
      *" $ws "*) props="background.drawing=on background.color=0x30ffffff label.drawing=off" ;;
      *)         props="background.drawing=off label.drawing=off" ;;
    esac
  fi
  set_args="$set_args --set space.$ws $props"
done

# Unquoted on purpose: word-splits into the batched argument list.
sketchybar $set_args
