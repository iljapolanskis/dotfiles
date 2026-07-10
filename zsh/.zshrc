# ── Powerlevel10k instant prompt ──────────────────────────────────
# Must be at the very top — forks a background worker before anything else loads
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── Environment variables (loaded early so aliases & tools can use them) ──
[[ -f ~/.zshrc.env ]] && source ~/.zshrc.env

# ── NVM For Node versioning (lazy-loaded)
export NVM_DIR="$HOME/.nvm"
_nvm_load() {
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
}
nvm() { unfunction nvm; _nvm_load; nvm "$@"; }
node() { unfunction node; _nvm_load; node "$@"; }
npm() { unfunction npm; _nvm_load; npm "$@"; }
npx() { unfunction npx; _nvm_load; npx "$@"; }

# ── Editor ────────────────────────────────────────────────────────
export EDITOR="${SSH_CONNECTION:+vim}"
export EDITOR="${EDITOR:-nvim}"

export GPG_TTY=$TTY

# ── PATH (single assignment — prepend order = priority order) ─────
export PATH="$HOME/go/bin:$HOME/.local/bin:/opt/homebrew/opt/bison/bin:$HOME/.pyenv/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"

# ── Completion (cached — skips security audit if dump is <24h old) ─
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# ── History ───────────────────────────────────────────────────────
# HISTFILE=$HOME/.zsh_history
# HISTSIZE=10000
# SAVEHIST=10000
# setopt share_history hist_ignore_dups hist_ignore_space hist_verify

# ── Options ───────────────────────────────────────────────────────
setopt auto_cd interactive_comments

# ── Key bindings (history search with arrow keys) ─────────────────
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# ── Plugins (Homebrew-managed, no framework) ──────────────────────
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── p10k prompt config ────────────────────────────────────────────
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ── Aliases ───────────────────────────────────────────────────────
alias p="cd ~/work"
alias h="history"
alias vim="nvim"
alias ll="ls -lhaF"

# Docker
alias d="docker"
alias dc="docker-compose"
alias ds="docker-sync"
alias sfdev="AWS_PROFILE=ecr docker run --pull=always \
  --env GITHUB_TOKEN=$GITHUB_TOKEN \
  --env DOCKER_USERNAME=$DOCKER_USERNAME \
  --env DOCKER_PASSWORD=$DOCKER_PASSWORD \
  --rm \
  -v $HOME/.aws/:/home/www-data/.aws/:ro \
  -v $HOME/.sfdev/:/home/www-data/.sfdev/:rw \
  -ti 935144294771.dkr.ecr.eu-west-1.amazonaws.com/sunfinancegroup/cli-devtool:latest"

# Git
alias gs="git status -s"

# AWS profile switchers
alias staging='export AWS_PROFILE=staging'
alias ecr='export AWS_PROFILE=ecr'
alias infra='export AWS_PROFILE=infra'
alias kuki-pl='export AWS_PROFILE=kuki-pl'
alias finbo-pl='export AWS_PROFILE=finbo-pl'
alias oros-pl='export AWS_PROFILE=oros-pl'
alias luzo-es='export AWS_PROFILE=luzo-es'

### EU1 Specific commands
alias eu1-start='~/work/dev.sh start'
alias eu1-stop='~/work/dev.sh stop'

# ── Functions ─────────────────────────────────────────────────────
# Shared JMESPath filter for ec2ls / ec2ssh
_ec2_excl='!starts_with(ComputerName, `ip-10`)  &&
           !starts_with(ComputerName, `SUN`)    &&
           !starts_with(ComputerName, `all`)    &&
           !starts_with(ComputerName, `healthcheck`) &&
           !starts_with(ComputerName, `k8s-`)   &&
           !starts_with(ComputerName, `lb-`)    &&
           !starts_with(ComputerName, `oracle`) &&
           !starts_with(ComputerName, `odi`)'

ec2ls() {
  aws ssm describe-instance-information \
    --query "sort_by(InstanceInformationList[? ${_ec2_excl}], &ComputerName)[].[InstanceId, IPAddress, ComputerName]" \
    --output table
}

ec2ssh() {
  local selected
  selected=$(aws ssm describe-instance-information \
    --query "sort_by(InstanceInformationList[? ${_ec2_excl}], &ComputerName)[].[InstanceId, ComputerName]" \
    --output text | fzf --with-nth=2)
  [[ -n "$selected" ]] && ssh "$(awk '{print $1}' <<< "$selected")"
}

pr-checkout() {
  local pr_number
  pr_number=$(
    gh api 'repos/:owner/:repo/pulls' |
    jq --raw-output '.[] | "#\(.number) \(.title)"' |
    fzf |
    awk -F'[ #]' '{print $2}'
  )
  [[ -n "$pr_number" ]] && gh pr checkout "$pr_number"
}

# ── pyenv (lazy-loaded — pays init cost only on first use) ────────
pyenv() {
  unfunction pyenv
  eval "$(command pyenv init --path)"
  eval "$(command pyenv init -)"
  eval "$(command pyenv virtualenv-init -)"
  pyenv "$@"
}

eval "$(atuin init zsh)"

# ── Claude wrapper — loads DBHUB_DSN from .env if present ─────────
claude() {
  if [[ -f ".env" ]]; then
    local dsn
    dsn=$(grep -E '^DBHUB_DSN=' .env | cut -d'=' -f2- | tr -d "'\"" )
    [[ -n "$dsn" ]] && export DBHUB_DSN="$dsn"
  fi
  command claude "$@"
}


# ── pr-eu1: PR create for erp-stl-eu with default reviewers ───────
pr-eu1() {
    gh pr create --draft \
        --reviewer Daniels-Ribkins,Grundmanis,vladlens-bogdanovs-sub-zero \
        --editor \
        "$@"
}
