# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

LazyVim starter config. Framework handles plugin management, LSP, treesitter, keymaps. User files are thin overrides.

## Formatting

Lua files use `stylua`: 2-space indent, 120-column width.

```sh
stylua lua/
```

## Architecture

```
init.lua                  → bootstraps lazy.nvim, loads config.lazy
lua/config/
  lazy.lua                → lazy.nvim setup + plugin spec import
  options.lua             → vim options (appended to LazyVim defaults)
  keymaps.lua             → keymaps (appended to LazyVim defaults)
  autocmds.lua            → autocmds (appended to LazyVim defaults)
lua/plugins/
  *.lua                   → auto-imported plugin specs
lazyvim.json              → enabled LazyVim extras (source of truth)
```

## Active LazyVim extras

- `lazyvim.plugins.extras.ai.claudecode` — Claude Code integration
- `lazyvim.plugins.extras.ai.copilot` — GitHub Copilot
- `lazyvim.plugins.extras.lang.php` — PHP LSP (intelephense), treesitter, phpcs, php-cs-fixer

## How to add/modify plugins

Create or edit files under `lua/plugins/`. Each file returns a list of lazy.nvim specs. To override a LazyVim default plugin, use the same plugin short name and set `opts`, `keys`, or `enabled`.

To disable a plugin: `{ "author/plugin", enabled = false }`.

To extend opts without overriding: use `opts = function(_, opts) ... return opts end`.

## How to enable/disable LazyVim extras

Open nvim and run `:LazyExtras` — the UI manages `lazyvim.json`. Don't edit `lazyvim.json` manually.

## Project-local tool overrides

`vim.o.exrc = true` is set — nvim loads `.nvim.lua` from project root on open.

Pattern for docker-wrapped tools (see `~/work/erp-stl-eu/.nvim.lua`):
```lua
vim.api.nvim_create_autocmd("User", { pattern = "VeryLazy", once = true, callback = function()
  require("conform").formatters.php_cs_fixer = { command = root .. "/bin/cs-fixer", ... }
  require("lint").linters.phpcs.cmd = root .. "/bin/phpcs"
end })
```

## Plugin management in nvim

- `:Lazy` — plugin manager UI (install, update, clean)
- `:LazyExtras` — toggle LazyVim feature bundles
- `:Mason` — LSP/linter/formatter installer
