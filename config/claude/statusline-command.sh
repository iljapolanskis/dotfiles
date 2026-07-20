#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

settings_file="$HOME/.claude/settings.json"

# Shorten home directory to ~
short_cwd=$(echo "$cwd" | sed "s|^$HOME|~|")

# AWS profile
aws_profile="${AWS_PROFILE:-}"

# Context usage (tokens, e.g. ctx:45k/1M)
fmt_tokens() {
    n="$1"
    if [ "$n" -ge 1000000 ] 2>/dev/null; then
        printf '%sM' "$(( (n + 500000) / 1000000 ))"
    elif [ "$n" -ge 1000 ] 2>/dev/null; then
        printf '%sk' "$(( (n + 500) / 1000 ))"
    else
        printf '%s' "$n"
    fi
}
ctx_info=""
if [ -n "$used_tokens" ]; then
    ctx_info="ctx:$(fmt_tokens "$used_tokens")"
    [ -n "$ctx_size" ] && ctx_info="${ctx_info}/$(fmt_tokens "$ctx_size")"
fi

# Git info
branch=""
git_meta=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
    # Count staged, unstaged changes and untracked files
    added=$(git -C "$cwd" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    changed=$(git -C "$cwd" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    parts=""
    [ "$added" -gt 0 ] && parts="${parts}+${added} "
    [ "$changed" -gt 0 ] && parts="${parts}~${changed} "
    [ "$untracked" -gt 0 ] && parts="${parts}?${untracked} "
    git_meta=$(echo "$parts" | sed 's/ $//')
fi

# Assemble: model : context | aws profile | cwd | branch [meta]
line=""

# model : context [CAVEMAN] [effort]
if [ -n "$model" ]; then
    line="${line}$(printf '\033[36m%s\033[0m' "$model")"
    if [ -n "$ctx_info" ]; then
        line="${line}$(printf ' \033[90m: %s\033[0m' "$ctx_info")"
    fi
else
    [ -n "$ctx_info" ] && line="${line}$(printf '\033[90m%s\033[0m' "$ctx_info")"
fi

# | aws profile
if [ -n "$aws_profile" ]; then
    line="${line}$(printf ' \033[90m|\033[0m \033[33maws:%s\033[0m' "$aws_profile")"
fi

# | cwd
line="${line}$(printf ' \033[90m|\033[0m \033[34m%s\033[0m' "$short_cwd")"

# | branch [meta]
if [ -n "$branch" ]; then
    line="${line}$(printf ' \033[90m|\033[0m \033[33m%s\033[0m' "$branch")"
    if [ -n "$git_meta" ]; then
        line="${line}$(printf ' \033[90m%s\033[0m' "$git_meta")"
    fi
fi

printf '%s' "$line"
