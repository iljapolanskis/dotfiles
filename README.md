# dotfiles

Personal config, version-controlled and symlinked into place.

## Tracked

| Repo path            | Symlinked to           |
|----------------------|------------------------|
| `zsh/.zshrc`         | `~/.zshrc`             |
| `config/nvim`        | `~/.config/nvim`       |
| `config/ghostty`     | `~/.config/ghostty`    |
| `config/aerospace`   | `~/.config/aerospace`  |
| `config/sketchybar`  | `~/.config/sketchybar` |
| `config/lazygit`     | `~/.config/lazygit`    |
| `config/atuin`       | `~/.config/atuin`      |

### Herdr

Only `config.toml` is linked, not the whole directory — herdr keeps its sockets,
logs and `session.json` in `~/.config/herdr/`.

| Repo path                  | Symlinked to                   |
|----------------------------|--------------------------------|
| `config/herdr/config.toml` | `~/.config/herdr/config.toml`  |

Apply changes without restarting: `herdr server reload-config`.

### Claude Code (global)

`~/.claude` is a symlink to `~/.config/claude` on this setup, so targets point at the real
`~/.config/claude` paths.

| Repo path                            | Symlinked to                          |
|--------------------------------------|---------------------------------------|
| `config/claude/settings.json`        | `~/.config/claude/settings.json`      |
| `config/claude/statusline-command.sh`| `~/.config/claude/statusline-command.sh` |
| `config/claude/.mcp.json`            | `~/.config/claude/.mcp.json`          |
| `config/claude/hooks`                | `~/.config/claude/hooks`              |
| `config/claude/skills/*`             | `~/.config/claude/skills/*` (local skills) |
| `config/agents`                      | `~/.agents` (`npx skills` store)      |

Global skills are managed by [`npx skills`](https://github.com/vercel-labs/skills), which
installs into `~/.agents/skills/` and records provenance in `~/.agents/.skill-lock.json`.
The whole `~/.agents` folder is snapshotted here, so a new machine gets the exact skill
content without re-downloading (survives upstream repos being deleted/renamed).

Claude Code reads user skills from `~/.config/claude/skills/`, so `install.sh` also recreates
the per-skill symlink farm there (`~/.config/claude/skills/<name>` -> `~/.agents/skills/<name>`)
for every skill in the tracked `~/.agents` copy. Hand-authored local skills that `npx skills`
does not manage (`codebase-memory`, `opensearch`) live under `config/claude/skills/` instead.

### Homebrew

`Brewfile` is a snapshot of installed formulae, casks, and taps. Regenerate and restore with:

```sh
brew bundle dump --force --file=Brewfile   # snapshot current machine
brew bundle install --file=Brewfile        # install everything on a new machine
```

## Common commands

Cheat sheet for things I look up repeatedly.

### Sketchybar

```sh
sketchybar --reload                # re-run sketchybarrc in place (config/plugin edits)
brew services restart sketchybar   # full restart (after brew upgrade, or wedged process)
pkill sketchybar && sketchybar &   # manual respawn when not under brew services
```

`~/.config/sketchybar` is a symlink into this repo, so `--reload` picks up repo edits
instantly. Plugin scripts under `config/sketchybar/plugins/` need no reload at all — the
next event tick execs the new file.

### Herdr

```sh
herdr server reload-config   # apply config.toml changes without restart
```

### Atuin

History is scoped per git repo (`filter_mode = "workspace"`). Outside a repo it falls back
to global. `ctrl-r` inside the search TUI cycles scopes in `search.filters` order:
`workspace -> global -> directory -> host -> session`.

```sh
atuin search --filter-mode workspace -i   # search only this repo's history
atuin search --filter-mode global -i      # search everything
atuin stats                               # top commands
atuin sync                                # force sync now (daemon syncs every 5m)
atuin config get filter_mode              # read one effective value
atuin config print                        # dump config.toml as parsed
atuin doctor                              # version/shell/daemon diagnostics (for bug reports)
```

Config is read fresh per invocation — no reload needed after editing.

### Mago (PHP)

Rust PHP toolchain — formatter, linter and static analyzer in one binary. Config is a
`mago.toml` at the repo root; it is **not** searched for upward, so run from the root or
pass `--workspace=<dir>`.

```sh
mago init                     # interactive starter mago.toml
mago config                   # dump the effective config as JSON (all defaults visible)
mago list-files               # what source.paths actually resolves to
mago format                   # rewrite files
mago format --check           # exit 1 if anything is unformatted (CI)
mago lint                     # style + correctness rules
mago lint --fix --format-after-fix   # apply safe fixes, then reformat
mago lint --staged            # only files staged in git
mago analyze                  # type check
mago analyze --reporting-format=count   # just the totals
mago lint --explain <rule>    # what a rule means and why
```

Adopting Mago in a repo that already has issues — baseline them and only see new ones:

```sh
mago analyze --baseline mago-baseline.toml --generate-baseline
mago analyze --baseline mago-baseline.toml
```

`source.paths` is first-party code; `source.includes` (e.g. `vendor`) is indexed for types
but never reported on. `[linter] integrations = ["symfony", "phpunit"]` teaches the linter
about framework conventions.

**Editor routing** (`config/nvim/lua/util/php_tooling.lua`): a repo is on Mago when it has a
`mago.toml` and **no** phpstan config. That keeps phpcs/phpstan repos on php-cs-fixer +
phpstan even if a `mago.toml` is lying around from trying the CLI. To migrate a repo, delete
its `phpstan.neon`.

### Homebrew

```sh
brew bundle dump --force --file=Brewfile   # snapshot current machine
brew bundle install --file=Brewfile        # install everything on a new machine
```

## Setup

```sh
git clone https://github.com/iljapolanskis/dotfiles.git ~/personal/dotfiles
cd ~/personal/dotfiles
./install.sh --dry-run   # preview
./install.sh             # apply
brew bundle install --file=Brewfile   # install apps (optional)
```

`install.sh` symlinks each repo path to its `$HOME` target. Anything already in the way is
moved to `~/.dotfiles-backup/<timestamp>/` first (never deleted). Re-running is safe —
already-linked paths are skipped.

## Notes

- Secrets and machine state (`gh`, `git` creds, `1Password`, `configstore`, `.jira`,
  `uv`, `wireshark`, ...) are intentionally **not** tracked.
- Atuin: `config/atuin` is tracked, but `~/.local/share/atuin` (encryption `key`,
  `session`, `history.db`, `records.db`) is **not** — that is per-machine secret state.
- `~/.ssh/config` is intentionally excluded.
- `.claude/` and `settings.local.json` are gitignored (local Claude Code state).
