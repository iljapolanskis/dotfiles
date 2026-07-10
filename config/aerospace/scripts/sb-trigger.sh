#!/bin/bash
# Guarded sketchybar --trigger. A wedged/dead bar daemon makes `sketchybar
# --trigger` block forever on its mach call; fired on every focus/workspace
# change, those hung clients pile up by the hundreds. timeout caps each at 3s
# (SIGKILL at 4s) so none can accumulate. Absolute paths because aerospace
# exec-and-forget runs with a minimal PATH lacking /opt/homebrew/bin.
exec /opt/homebrew/bin/timeout -k 1 3 /opt/homebrew/bin/sketchybar --trigger "$@"
