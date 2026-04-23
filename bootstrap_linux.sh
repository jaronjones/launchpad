#!/usr/bin/env bash
#
# bootstrap_linux.sh — fresh-box setup for Go/htmx/Postgres/Docker/GitHub/Claude Code
# Target: Ubuntu 22.04+ / Debian 12+. Idempotent.
#
# Usage:
#   bash bootstrap_linux.sh [--skip-editor] [--skip-docker] [--dry-run] [--verbose]
#
# Non-interactive:
#   POSTGRES_MODE=docker|native
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

need_cmd()  { command -v "$1" >/dev/null 2>&1; }
pkg_installed() { dpkg -s "$1" >/dev/null 2>&1; }

apt_install() {
  local pkg="$1"
  if pkg_installed "$pkg"; then
    skip "$pkg already installed"
  else
    run "sudo apt-get install -y $pkg"
  fi
}

prompt_choice() {
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
if [[ "$(uname -s)" != "Linux" ]]; then
  warn "This script targets Linux. For macOS use bootstrap_macos.sh"
  exit 1
fi

if ! need_cmd apt-get; then
  warn "This script targets Debian/Ubuntu (apt). Detected a non-apt system."
  exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release
DISTRO_ID="$ID"          # ubuntu | debian
DISTRO_CODENAME="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo stable)}"

# --- 1. apt prerequisites -------------------------------------------------
install_prereqs() {
  log "Updating apt index"
  run "sudo apt-get update -y"
  for p in build-essential curl wget git ca-certificates gnupg lsb-release software-properties-common zsh; do
    apt_install "$p"
  done
}

# --- 2. shell & terminal --------------------------------------------------
install_shell_stack() {
  # starship via official installer (apt version lags)
  if need_cmd starship; then
    skip "starship installed"
  else
    run "curl -sS https://starship.rs/install.sh | sh -s -- -y"
  fi
  if ! grep -q 'starship init' "$HOME/.zshrc" 2>/dev/null; then
    run "echo 'eval \"\$(starship init zsh)\"' >> $HOME/.zshrc"
  fi
  local starship_cfg="$HOME/.config/starship.toml"
  if [[ ! -f "$starship_cfg" && -f templates/starship.toml ]]; then
    run "mkdir -p $HOME/.config && cp templates/starship.toml $starship_cfg"
  fi
  # change default shell if still bash
  if [[ "${SHELL##*/}" != "zsh" ]] && need_cmd zsh; then
    warn "To use zsh as default: chsh -s \"$(which zsh)\""
  fi
  # Nerd font: install JetBrainsMono Nerd Font to ~/.local/share/fonts
  local font_dir="$HOME/.local/share/fonts"
  if [[ -d "$font_dir" ]] && ls "$font_dir" 2>/dev/null | grep -qi 'JetBrainsMono.*Nerd'; then
    skip "JetBrainsMono Nerd Font installed"
  else
    run "mkdir -p $font_dir"
    run "curl -fsSL -o /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    run "unzip -qo /tmp/JetBrainsMono.zip -d $font_dir/JetBrainsMonoNerd"
    run "fc-cache -f"
    run "rm -f /tmp/JetBrainsMono.zip"
  fi
}

# --- 3. git & github ------------------------------------------------------
install_git_stack() {
  apt_install git
  # gh from official repo
  if need_cmd gh; then
    skip "gh installed"
  else
    run 'curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg'
    run 'sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg'
    run 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null'
    run "sudo apt-get update -y"
    apt_install gh
  fi
  if [[ -f templates/gitconfig.sample && ! -f "$HOME/.gitconfig" ]]; then
    run "cp templates/gitconfig.sample $HOME/.gitconfig"
  fi
  if [[ -f templates/gitignore_global && ! -f "$HOME/.gitignore_global" ]]; then
    run "cp templates/gitignore_global $HOME/.gitignore_global"
    run "git config --global core.excludesfile $HOME/.gitignore_global"
  fi
}

# --- 4. go (official tarball, apt lags) -----------------------------------
install_go() {
  local target_version="1.22.12"
  if need_cmd go && go version | grep -q "go$target_version\|go1.2[3-9]\|go[2-9]"; then
    skip "go $(go version | awk '{print $3}') installed"
  else
    local arch
    case "$(uname -m)" in
      x86_64) arch="amd64" ;;
      aarch64|arm64) arch="arm64" ;;
      *) warn "unknown arch"; exit 1 ;;
    esac
    local tarball="go${target_version}.linux-${arch}.tar.gz"
    run "curl -fsSL -o /tmp/$tarball https://go.dev/dl/$tarball"
    run "sudo rm -rf /usr/local/go"
    run "sudo tar -C /usr/local -xzf /tmp/$tarball"
    run "rm /tmp/$tarball"
  fi
  if ! grep -q '/usr/local/go/bin' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'EOF'

# Go
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"
EOF
  fi
  export PATH="/usr/local/go/bin:$PATH"
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

# --- 5. node (fnm) --------------------------------------------------------
install_node() {
  if need_cmd fnm; then
    skip "fnm installed"
  else
    run 'curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/share/fnm" --skip-shell'
  fi
  if ! grep -q 'fnm env' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'EOF'

# fnm
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --use-on-cd)"
EOF
  fi
  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "$(fnm env)"
  if ! fnm list 2>/dev/null | grep -qE 'v[0-9]+'; then
    run "fnm install --lts"
    run "fnm default lts-latest"
  else
    skip "Node already installed via fnm"
  fi
}

# --- 6. docker engine (official repo) -------------------------------------
install_docker() {
  [[ $SKIP_DOCKER -eq 1 ]] && { skip "Docker skipped (--skip-docker)"; return; }
  if need_cmd docker; then
    skip "docker installed"
  else
    # uninstall any conflicting packages silently
    for p in docker.io docker-doc docker-compose podman-docker containerd runc; do
      sudo apt-get remove -y "$p" >/dev/null 2>&1 || true
    done
    run "sudo install -m 0755 -d /etc/apt/keyrings"
    run "curl -fsSL https://download.docker.com/linux/$DISTRO_ID/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg"
    run "sudo chmod a+r /etc/apt/keyrings/docker.gpg"
    run "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO_ID $DISTRO_CODENAME stable\" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null"
    run "sudo apt-get update -y"
    for p in docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; do
      apt_install "$p"
    done
  fi
  if ! id -nG "$USER" | grep -qw docker; then
    run "sudo usermod -aG docker $USER"
    warn "Added $USER to docker group — log out and back in for it to take effect."
  fi
  if need_cmd lazydocker; then
    skip "lazydocker installed"
  else
    run "curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash"
  fi
}

# --- 7. postgres ----------------------------------------------------------
install_postgres() {
  local mode="${POSTGRES_MODE:-}"
  if [[ -z "$mode" ]]; then
    prompt_choice mode "How should Postgres run locally?" "docker" "native"
  fi
  case "$mode" in
    docker)
      skip "Using Dockerized Postgres — see templates/docker-compose.postgres.yml"
      ;;
    native)
      # PGDG repo for pinned 16
      if ! pkg_installed postgresql-16; then
        run 'sudo install -d /usr/share/postgresql-common/pgdg'
        run 'sudo curl -fsSL -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc https://www.postgresql.org/media/keys/ACCC4CF8.asc'
        run "echo \"deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $DISTRO_CODENAME-pgdg main\" | sudo tee /etc/apt/sources.list.d/pgdg.list >/dev/null"
        run "sudo apt-get update -y"
        apt_install postgresql-16
        run "sudo systemctl enable --now postgresql"
      else
        skip "postgresql-16 installed"
      fi
      ;;
    *) warn "unknown POSTGRES_MODE=$mode"; exit 1 ;;
  esac
  # client tools regardless
  apt_install postgresql-client
  apt_install pgcli
}

# --- 8. claude code -------------------------------------------------------
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

# --- 9. neovim + lazyvim --------------------------------------------------
install_neovim() {
  [[ $SKIP_EDITOR -eq 1 ]] && { skip "Neovim skipped (--skip-editor)"; return; }
  # apt nvim lags — use the unstable PPA on Ubuntu, else AppImage
  if need_cmd nvim && nvim --version | head -1 | grep -qE 'v(0\.(1[0-9]|[2-9][0-9])|[1-9])'; then
    skip "Neovim $(nvim --version | head -1) installed"
  elif [[ "$DISTRO_ID" == "ubuntu" ]]; then
    run "sudo add-apt-repository -y ppa:neovim-ppa/unstable"
    run "sudo apt-get update -y"
    apt_install neovim
  else
    # AppImage fallback for Debian
    run "sudo curl -fsSL -o /usr/local/bin/nvim https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
    run "sudo chmod +x /usr/local/bin/nvim"
  fi
  apt_install ripgrep
  apt_install fd-find
  # ubuntu ships fd as fdfind; add a shim
  if ! need_cmd fd && need_cmd fdfind; then
    run "mkdir -p $HOME/.local/bin && ln -sf $(which fdfind) $HOME/.local/bin/fd"
  fi
  # lazygit
  if need_cmd lazygit; then
    skip "lazygit installed"
  else
    local lg_arch
    case "$(uname -m)" in
      x86_64) lg_arch="Linux_x86_64" ;;
      aarch64|arm64) lg_arch="Linux_arm64" ;;
    esac
    run "curl -fsSLo /tmp/lazygit.tar.gz https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_0.43.1_${lg_arch}.tar.gz"
    run "sudo tar -xzf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit"
    run "rm /tmp/lazygit.tar.gz"
  fi
  local nvim_cfg="$HOME/.config/nvim"
  if [[ -d "$nvim_cfg" ]]; then
    skip "Neovim config exists at $nvim_cfg — not overwriting"
  else
    run "git clone https://github.com/LazyVim/starter $nvim_cfg"
    run "rm -rf $nvim_cfg/.git"
  fi
}

# --- 10. cli utilities ----------------------------------------------------
install_cli_utils() {
  local pkgs=(fzf bat jq httpie direnv tmux tree btop unzip)
  for p in "${pkgs[@]}"; do apt_install "$p"; done
  # bat on debian/ubuntu ships as 'batcat' — shim
  if ! need_cmd bat && need_cmd batcat; then
    run "mkdir -p $HOME/.local/bin && ln -sf $(which batcat) $HOME/.local/bin/bat"
  fi
  # eza (apt lacks it on older releases — use official repo)
  if need_cmd eza; then
    skip "eza installed"
  else
    run "sudo mkdir -p /etc/apt/keyrings"
    run "curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg"
    run 'echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null'
    run "sudo apt-get update -y"
    apt_install eza
  fi
  # yq — standalone binary
  if need_cmd yq; then
    skip "yq installed"
  else
    local yq_arch
    case "$(uname -m)" in x86_64) yq_arch=amd64 ;; aarch64|arm64) yq_arch=arm64 ;; esac
    run "sudo curl -fsSLo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${yq_arch}"
    run "sudo chmod +x /usr/local/bin/yq"
  fi
  # 1password CLI
  if need_cmd op; then
    skip "1password-cli installed"
  else
    run "curl -fsSL https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --yes -o /usr/share/keyrings/1password-archive-keyring.gpg"
    run 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | sudo tee /etc/apt/sources.list.d/1password.list >/dev/null'
    run "sudo apt-get update -y"
    apt_install 1password-cli || warn "1password-cli install failed — optional, continuing"
  fi
  if ! grep -q 'direnv hook zsh' "$HOME/.zshrc" 2>/dev/null; then
    run "echo 'eval \"\$(direnv hook zsh)\"' >> $HOME/.zshrc"
  fi
  if ! grep -q 'export PATH.*.local/bin' "$HOME/.zshrc" 2>/dev/null; then
    run "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> $HOME/.zshrc"
  fi
}

# --- main -----------------------------------------------------------------
main() {
  log "dev-starter bootstrap (Linux / $DISTRO_ID $DISTRO_CODENAME)"
  install_prereqs
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

  1. chsh -s $(which zsh)               # set zsh as default shell, then re-login
  2. gh auth login                      # GitHub CLI
  3. ssh-keygen -t ed25519 -C you@...   # then: gh ssh-key add ~/.ssh/id_ed25519.pub
  4. claude                             # authenticate Claude Code in browser
  5. Configure your terminal to use "JetBrainsMono Nerd Font"
  6. nvim +"LazyExtras"                 # enable: lang.go, lang.docker, lang.sql, lang.tailwind
  7. Log out and back in so the docker group membership takes effect.

See POSTINSTALL.md for the full checklist.
=============================================================
EOF
}

main "$@"
