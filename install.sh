#!/usr/bin/env bash
#
# install.sh — symlink tracked dotfiles into place, backing up anything it replaces.
#
# Usage:
#   ./install.sh            # link everything
#   ./install.sh --dry-run  # show what would happen, change nothing
#
set -euo pipefail

# Resolve the repo root from this script's own location so it works from any cwd / machine.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.dotfiles-backup/$TIMESTAMP"

# repo-relative source  ->  absolute destination in $HOME
MAP=(
  "zsh/.zshrc:$HOME/.zshrc"
  "config/nvim:$HOME/.config/nvim"
  "config/ghostty:$HOME/.config/ghostty"
  "config/aerospace:$HOME/.config/aerospace"
  "config/sketchybar:$HOME/.config/sketchybar"
  "config/lazygit:$HOME/.config/lazygit"
)

n_linked=0 n_skipped=0 n_backed=0

say() { printf '%s\n' "$*"; }
run() { if [[ $DRY_RUN -eq 1 ]]; then say "  [dry-run] $*"; else eval "$*"; fi; }

link() {
  local src="$DOTFILES_DIR/$1" dest="$2"

  if [[ ! -e "$src" ]]; then
    say "!! missing source, skip: $src"
    return
  fi

  # Already linked correctly -> nothing to do.
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    say "== skip (already linked): $dest"
    ((n_skipped++)) || true
    return
  fi

  # Something is in the way -> back it up (preserving its path under the backup dir).
  if [[ -e "$dest" || -L "$dest" ]]; then
    local rel="${dest#"$HOME"/}"
    local bpath="$BACKUP_DIR/$rel"
    say "-> backup: $dest  ->  $bpath"
    run "mkdir -p \"\$(dirname \"$bpath\")\""
    run "mv \"$dest\" \"$bpath\""
    ((n_backed++)) || true
  fi

  say "-> link: $dest  ->  $src"
  run "mkdir -p \"\$(dirname \"$dest\")\""
  run "ln -s \"$src\" \"$dest\""
  ((n_linked++)) || true
}

say "dotfiles: $DOTFILES_DIR"
[[ $DRY_RUN -eq 1 ]] && say "(dry-run — no changes will be made)"
say ""

for entry in "${MAP[@]}"; do
  link "${entry%%:*}" "${entry#*:}"
done

say ""
say "done. linked=$n_linked  skipped=$n_skipped  backed-up=$n_backed"
if [[ $n_backed -gt 0 && $DRY_RUN -eq 0 ]]; then
  say "backups: $BACKUP_DIR"
fi
