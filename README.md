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

- Secrets and machine state (`gh`, `atuin`, `git` creds, `1Password`, `configstore`, `.jira`,
  `uv`, `wireshark`, ...) are intentionally **not** tracked.
- `~/.ssh/config` is intentionally excluded.
- `.claude/` and `settings.local.json` are gitignored (local Claude Code state).
