#!/bin/bash
# Nudge a floating window below sketchybar if it overlaps.
# Usage: float-below-bar.sh <bundle-id>
# Called via exec-and-forget from on-window-detected in aerospace.toml.

BUNDLE_ID="$1"
BAR_BOTTOM=55  # sketchybar height (40) + outer.top gap (10) + buffer (5)

for i in 1 2 3 4 5; do
  result=$(osascript <<EOF
tell application "System Events"
  try
    tell (first process whose bundle identifier is "$BUNDLE_ID")
      set {wx, wy} to position of window 1
      if wy < $BAR_BOTTOM then
        set position of window 1 to {wx, $BAR_BOTTOM}
      end if
      return "ok"
    end tell
  end try
end tell
EOF
)
  [ "$result" = "ok" ] && exit 0
  sleep 0.1
done
