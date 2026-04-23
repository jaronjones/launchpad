#!/usr/bin/env bash
#
# bootstrap_macos.sh — fresh-box setup for Go/htmx/Postgres/Docker/GitHub/Claude Code
# Idempotent: safe to re-run.
#
# Usage:
#   bash bootstrap_macos.sh [--skip-editor] [--skip-docker] [--dry-run] [--verbose]
#
# Non-interactive:
#   POSTGRES_MODE=docker|native|brew-service
#   DOCKER_RUNTIME=orbstack|desktop
#   SKIP_PROMPTS=1

set -euo pipefail
IFS=$'\n\t'

# --- flags ----------------------------------------------------------------
SKIP_EDITOR=0
SKIP_DOCKER=0
DRY_RUN=0
VERBOSE=0
for arg in "$@"; do
  case "$arg" in
    --skip-editor) SKIP_EDITOR=1 ;;
    --skip-docker) SKIP_DOCKER=1 ;;
    --dry-run)     DRY_RUN=1 ;;
    --verbose)     VERBOSE=1 ;;
    -h|--help)     sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

# --- helpers --------------------------------------------------------------
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
skip() { printf '\033[1;32m✓\033[0m %s\n' "$*"; }

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '\033[1;35mDRY-RUN\033[0m %s\n' "$*"
    return 0
  fi
  [[ $VERBOSE -eq 1 ]] && printf '\033[2m$ %s\033[0m\n' "$*"
  eval "$@"
}

need_cmd() { command -v "$1" >/dev/null 2>&1; }

brew_install() {
  local formula="$1"
  if brew list --formula "$formula" >/dev/null 2>&1; then
    skip "$formula already installed"
  else
    run brew install "$formula"
  fi
}

brew_cask_install() {
  local cask="$1"
  if brew list --cask "$cask" >/dev/null 2>&1; then
    skip "$cask already installed"
  else
    run brew install --cask "$cask"
  fi
}

prompt_choice() {
  # prompt_choice VAR_NAME "prompt" "opt1" "opt2" ...
  local var_name="$1"; shift
  local prompt="$1"; shift
  local -a opts=("$@")
  if [[ ${SKIP_PROMPTS:-0} -eq 1 ]]; then
    printf -v "$var_name" '%s' "${opts[0]}"
    return
  fi
  echo
  echo "$prompt"
  local i=1
  for o in "${opts[@]}"; do echo "  $i) $o"; i=$((i+1)); done
  local choice
  read -r -p "Pick [1-${#opts[@]}]: " choice
  choice=${choice:-1}
  printf -v "$var_name" '%s' "${opts[$((choice-1))]}"
}

# --- platform sanity ------------------------------------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
  warn "This script targets macOS. For Linux use bootstrap_linux.sh"
  exit 1
fi

ARCH="$(uname -m)"
case "$ARCH" in
  arm64) BREW_PREFIX="/opt/homebrew" ;;
  x86_64) BREW_PREFIX="/usr/local" ;;
  *) warn "unknown arch: $ARCH"; exit 1 ;;
esac

# --- 1. xcode command line tools -----------------------------------------
install_xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    skip "Xcode Command Line Tools installed"
  else
    log "Installing Xcode Command Line Tools (GUI prompt will appear)"
    run xcode-select --install || true
    echo "Re-run this script after the CLT install finishes."
    exit 0
  fi
}

# --- 2. homebrew ----------------------------------------------------------
install_homebrew() {
  if need_cmd brew; then
    skip "Homebrew installed"
  else
    log "Installing Homebrew"
    run '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  fi
  # shellcheck disable=SC2016
  if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    run "echo 'eval \"\$($BREW_PREFIX/bin/brew shellenv)\"' >> $HOME/.zprofile"
  fi
  eval "$($BREW_PREFIX/bin/brew shellenv)"
}

# --- 3. shell & terminal --------------------------------------------------
install_shell_stack() {
  brew_install starship
  brew_cask_install font-jetbrains-mono-nerd-font
  brew_cask_install ghostty
  if ! grep -q 'starship init zsh' "$HOME/.zshrc" 2>/dev/null; then
    run "echo 'eval \"\$(starship init zsh)\"' >> $HOME/.zshrc"
  fi
  local starship_cfg="$HOME/.config/starship.toml"
  if [[ ! -f "$starship_cfg" && -f templates/starship.toml ]]; then
    run "mkdir -p $HOME/.config && cp templates/starship.toml $starship_cfg"
  fi
}

# --- 4. git & github ------------------------------------------------------
install_git_stack() {
  brew_install git
  brew_install gh
  if [[ -f templates/gitconfig.sample ]]; then
    if [[ ! -f "$HOME/.gitconfig" ]]; then
      run "cp templates/gitconfig.sample $HOME/.gitconfig"
    else
      skip "~/.gitconfig exists — leaving alone (see templates/gitconfig.sample)"
    fi
  fi
  if [[ -f templates/gitignore_global && ! -f "$HOME/.gitignore_global" ]]; then
    run "cp templates/gitignore_global $HOME/.gitignore_global"
    run "git config --global core.excludesfile $HOME/.gitignore_global"
  fi
}

# --- 5. go ----------------------------------------------------------------
install_go() {
  brew_install go
  # PATH entry for $GOBIN
  if ! grep -q 'GOBIN' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'EOF'

# Go
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"
EOF
  fi
  export GOPATH="$HOME/go"
  export GOBIN="$GOPATH/bin"
  export PATH="$GOBIN:$PATH"
  mkdir -p "$GOBIN"

  local tools=(
    "golang.org/x/tools/gopls@latest"
    "github.com/go-delve/delve/cmd/dlv@latest"
    "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
    "github.com/air-verse/air@latest"
    "github.com/a-h/templ/cmd/templ@latest"
    "golang.org/x/tools/cmd/goimports@latest"
    "go.uber.org/mock/mockgen@latest"
  )
  for t in "${tools[@]}"; do
    local bin="${t##*/}"; bin="${bin%@*}"
    if [[ -x "$GOBIN/$bin" ]]; then
      skip "go tool $bin installed"
    else
      run "go install $t"
    fi
  done
}

# --- 6. node (for claude-code & LSPs) -------------------------------------
install_node() {
  brew_install fnm
  if ! grep -q 'fnm env' "$HOME/.zshrc" 2>/dev/null; then
    run "echo 'eval \"\$(fnm env --use-on-cd)\"' >> $HOME/.zshrc"
  fi
  eval "$(fnm env)"
  if ! fnm list | grep -q 'lts\|v[0-9]'; then
    run "fnm install --lts"
    run "fnm default lts-latest"
  else
    skip "Node already installed via fnm"
  fi
}

# --- 7. docker ------------------------------------------------------------
install_docker() {
  [[ $SKIP_DOCKER -eq 1 ]] && { skip "Docker skipped (--skip-docker)"; return; }
  local runtime="${DOCKER_RUNTIME:-}"
  if [[ -z "$runtime" ]]; then
    prompt_choice runtime "Pick a Docker runtime:" "orbstack" "desktop"
  fi
  case "$runtime" in
    orbstack) brew_cask_install orbstack ;;
    desktop)  brew_cask_install docker ;;
    *) warn "unknown DOCKER_RUNTIME=$runtime"; exit 1 ;;
  esac
  brew_install lazydocker
}

# --- 8. postgres ----------------------------------------------------------
install_postgres() {
  local mode="${POSTGRES_MODE:-}"
  if [[ -z "$mode" ]]; then
    prompt_choice mode "How should Postgres run locally?" "docker" "native" "brew-service"
  fi
  case "$mode" in
    docker)
      skip "Using Dockerized Postgres — see templates/docker-compose.postgres.yml"
      ;;
    native|brew-service)
      brew_install postgresql@16
      if [[ "$mode" == "brew-service" ]]; then
        run "brew services start postgresql@16"
      fi
      ;;
    *) warn "unknown POSTGRES_MODE=$mode"; exit 1 ;;
  esac
  # clients installed regardless
  brew_install libpq
  brew_install pgcli
  brew_cask_install tableplus
}

# --- 9. claude code -------------------------------------------------------
install_claude_code() {
  if need_cmd claude; then
    skip "Claude Code installed"
  else
    run "npm install -g @anthropic-ai/claude-code"
  fi
  mkdir -p "$HOME/.claude"
  if [[ ! -f "$HOME/.claude/settings.json" ]]; then
    cat > "$HOME/.claude/settings.json" <<'JSON'
{
  "theme": "dark",
  "permissions": {
    "allow": ["Bash(git status)", "Bash(git diff:*)", "Bash(git log:*)"]
  }
}
JSON
  fi
}

# --- 10. neovim + lazyvim -------------------------------------------------
install_neovim() {
  [[ $SKIP_EDITOR -eq 1 ]] && { skip "Neovim skipped (--skip-editor)"; return; }
  brew_install neovim
  brew_install ripgrep
  brew_install fd
  brew_install lazygit
  local nvim_cfg="$HOME/.config/nvim"
  if [[ -d "$nvim_cfg" ]]; then
    skip "Neovim config exists at $nvim_cfg — not overwriting"
  else
    run "git clone https://github.com/LazyVim/starter $nvim_cfg"
    run "rm -rf $nvim_cfg/.git"
  fi
}

# --- 11. cli utilities ----------------------------------------------------
install_cli_utils() {
  local formulas=(
    fzf bat eza jq yq httpie direnv tmux tree btop coreutils
  )
  for f in "${formulas[@]}"; do brew_install "$f"; done
  brew_install 1password-cli || true
  if ! grep -q 'direnv hook zsh' "$HOME/.zshrc" 2>/dev/null; then
    run "echo 'eval \"\$(direnv hook zsh)\"' >> $HOME/.zshrc"
  fi
}

# --- main -----------------------------------------------------------------
main() {
  log "dev-starter bootstrap (macOS / $ARCH)"
  install_xcode_clt
  install_homebrew
  install_shell_stack
  install_git_stack
  install_go
  install_node
  install_docker
  install_postgres
  install_claude_code
  install_neovim
  install_cli_utils
  cat <<'EOF'

=============================================================
Bootstrap complete. Manual follow-ups:

  1. Restart your terminal (or `exec zsh`) so PATH changes take effect.
  2. gh auth login                      # GitHub CLI
  3. ssh-keygen -t ed25519 -C you@...   # then: gh ssh-key add ~/.ssh/id_ed25519.pub
  4. claude                             # authenticate Claude Code in browser
  5. Open Ghostty → set font to "JetBrainsMono Nerd Font"
  6. nvim +"LazyExtras"                 # enable: lang.go, lang.docker, lang.sql, lang.tailwind

See POSTINSTALL.md for the full checklist.
=============================================================
EOF
}

main "$@"
