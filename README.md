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

## Setup

```sh
git clone https://github.com/iljapolanskis/dotfiles.git ~/personal/dotfiles
cd ~/personal/dotfiles
./install.sh --dry-run   # preview
./install.sh             # apply
```

`install.sh` symlinks each repo path to its `$HOME` target. Anything already in the way is
moved to `~/.dotfiles-backup/<timestamp>/` first (never deleted). Re-running is safe —
already-linked paths are skipped.

## Notes

- Secrets and machine state (`gh`, `atuin`, `git` creds, `1Password`, `configstore`, `.jira`,
  `uv`, `wireshark`, ...) are intentionally **not** tracked.
- `~/.ssh/config` is intentionally excluded.
- `.claude/` and `settings.local.json` are gitignored (local Claude Code state).
