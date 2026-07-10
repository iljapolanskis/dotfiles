# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Docs

Use context7 MCP to fetch current AeroSpace docs before editing config or answering questions about commands/options:
1. `mcp__plugin_context7_context7__resolve-library-id` with query `AeroSpace window manager`
2. `mcp__plugin_context7_context7__query-docs` with resolved ID

## What this is

AeroSpace tiling window manager config for macOS. Single file: `aerospace.toml`. Docs: https://nikitabobko.github.io/AeroSpace/

## Apply changes

Reload config without restart: enter service mode (`alt-shift-semicolon`), press `esc`.

Or via CLI: `aerospace reload-config`

## Config structure

- **Global settings** — top of file (startup commands, normalizations, gaps, persistent workspaces)
- **`on-window-detected`** — per-app rules (float/tile specific apps by `app-id`)
- **`[mode.main.binding]`** — always-active keybinds
- **`[mode.service.binding]`** — secondary mode for layout management (enter via `alt-shift-semicolon`)

## Current keybind conventions

- `alt-hjkl` — vim-style focus navigation
- `alt-shift-hjkl` — move windows
- `alt-1..9` / `alt-shift-1..9` — switch / move-to workspace
- `alt-slash` — tiles layout, `alt-comma` — accordion layout
- `alt-minus/equal` — resize ±50

## Monitors

- Monitor 1 (left): `P24h-30 (1)`
- Monitor 2 (right): `P24h-30 (2)`

Use sequence numbers (`1`, `2`) in `workspace-to-monitor-force-assignment` — left→right order confirmed.

## Status bar

sketchybar replaces native macOS menu bar. Native bar set to `Always` autohide (System Settings → Control Centre → Menu Bar). sketchybar launched via `after-startup-command` in `aerospace.toml` and receives workspace change events via `exec-on-workspace-change`.

## Floating apps

Ghostty (`com.mitchellh.ghostty`) and TablePlus (`com.tinyapp.TablePlus`) forced floating via `on-window-detected`.

To add more: find app bundle ID with `osascript -e 'id of app "AppName"'`, then add an `[[on-window-detected]]` block.
