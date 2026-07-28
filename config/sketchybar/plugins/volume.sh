#!/bin/sh

# The volume_change event supplies a $INFO variable in which the current volume
# percentage is passed to the script.

# Prefer the event-supplied volume; fall back to the current system volume so
# the item is populated on startup (forced --update) instead of blank.
VOLUME="${INFO:-$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)}"

# Some audio devices report "output volume" as "missing value" — fall back to
# 100 so a sane percentage shows until a real volume_change event arrives.
case "$VOLUME" in
  ''|*[!0-9]*) VOLUME=100 ;;
esac

case "$VOLUME" in
  [6-9][0-9]|100) ICON="󰕾"
  ;;
  [3-5][0-9]) ICON="󰖀"
  ;;
  [1-9]|[1-2][0-9]) ICON="󰕿"
  ;;
  *) ICON="󰖁"
esac

sketchybar --set "$NAME" icon="$ICON" label="$VOLUME%"
