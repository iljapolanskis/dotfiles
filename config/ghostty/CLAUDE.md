# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Ghostty terminal emulator config at `~/.config/ghostty/config`. Single file, no build step.

## Config format

`key = value` pairs. Repeated keys like `palette = N=#hex` are all valid — ghostty accumulates them.

Palette slots: 0=black, 1=red, 2=green, 3=yellow, 4=blue, 5=magenta, 6=cyan, 7=white (normal). Slots 8-15 = bright variants.

## Applying changes

Ghostty hot-reloads config on save. No restart needed for most settings. Font changes may require restart.

## Documentation

Use context7 MCP to fetch current Ghostty docs when looking up config options, keybindings, or CLI flags:
- Library ID: `/ghostty-org/ghostty`
- Use for: config key reference, keybind syntax, theme format, CLI subcommands

## Useful commands

```sh
# Validate config (ghostty CLI)
ghostty +validate-config

# List available themes
ghostty +list-themes

# List available fonts
ghostty +list-fonts
```
