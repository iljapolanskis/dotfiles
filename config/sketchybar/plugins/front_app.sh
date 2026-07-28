#!/bin/sh

# Some events send additional information specific to the event in the $INFO
# variable. E.g. the front_app_switched event sends the name of the newly
# focused application in the $INFO variable:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

if [ "$SENDER" = "front_app_switched" ]; then
  sketchybar --set "$NAME" label="$INFO"
else
  # Forced --update / non-event: query current front app so the item is
  # populated on startup instead of blank until the first app switch.
  sketchybar --set "$NAME" label="$(osascript -e 'tell application "System Events" to name of first application process whose frontmost is true')"
fi
