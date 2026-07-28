#!/bin/sh

# Current keyboard input source, mapped to a short 2-letter code.
# Driven by the `input_change` event (bound to the macOS
# AppleSelectedInputSourcesChangedNotification) — no polling.

SOURCE=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleCurrentKeyboardLayoutInputSourceID 2>/dev/null)
LAYOUT=${SOURCE##*.}   # strip "com.apple.keylayout." / "com.apple.inputmethod." prefix

case "$LAYOUT" in
  US|ABC)     LABEL="US" ;;
  Latvian)    LABEL="LV" ;;
  RussianWin) LABEL="RU" ;;
  Portuguese) LABEL="PT" ;;
  *)          LABEL=$(printf '%s' "$LAYOUT" | tr '[:lower:]' '[:upper:]' | cut -c1-2) ;;
esac

sketchybar --set "$NAME" label="$LABEL"
