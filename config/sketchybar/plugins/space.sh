#!/bin/sh

# Highlights workspace items based on AeroSpace focus state.
# Shows label only for the focused workspace.
# $NAME              — set by sketchybar: "space.<workspace-name>"
# $FOCUSED_WORKSPACE — passed via aerospace_workspace_change trigger
# $VISIBLE_M1/M2     — passed via trigger (queried once in on-workspace-change.sh)

WORKSPACE="${NAME#space.}"

# Prefer event-passed vars; fall back to CLI only on system_woke
if [ -n "$FOCUSED_WORKSPACE" ]; then
  FOCUSED="$FOCUSED_WORKSPACE"
else
  FOCUSED=$(aerospace list-workspaces --focused 2>/dev/null)
fi

if [ -n "$VISIBLE_M1" ] && [ -n "$VISIBLE_M2" ]; then
  V1="$VISIBLE_M1"
  V2="$VISIBLE_M2"
else
  V1=$(aerospace list-workspaces --monitor 1 --visible 2>/dev/null | head -1)
  V2=$(aerospace list-workspaces --monitor 2 --visible 2>/dev/null | head -1)
fi

if [ "$WORKSPACE" = "$FOCUSED" ]; then
  sketchybar --set "$NAME" background.drawing=on background.color=0x60ffffff label.drawing=on
elif [ "$WORKSPACE" = "$V1" ] || [ "$WORKSPACE" = "$V2" ]; then
  sketchybar --set "$NAME" background.drawing=on background.color=0x30ffffff label.drawing=off
else
  sketchybar --set "$NAME" background.drawing=off label.drawing=off
fi
