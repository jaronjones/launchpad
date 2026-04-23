# Manual install — Linux (Ubuntu/Debian)

Step-by-step equivalent of `bootstrap_linux.sh`. Follow top to bottom. Each block is idempotent — skip it if the tool is already installed.

Tested on Ubuntu 22.04+ and Debian 12+.

Before you begin, confirm your distro codename — a few steps need it:

```bash
. /etc/os-release
echo "$ID $VERSION_CODENAME"    # e.g. "ubuntu jammy" or "debian bookworm"
```

---

## 1. apt prerequisites

```bash
sudo apt-get update -y
sudo apt-get install -y \
  build-essential curl wget git ca-certificates gnupg \
  lsb-release software-properties-common zsh unzip
```

## 2. Shell & terminal

Install Starship via its official installer (the apt version lags):

```bash
curl -sS https://starship.rs/install.sh | sh -s -- -y
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
```

Seed the Starship config (optional — uses the one in this repo):

```bash
mkdir -p ~/.config
cp templates/starship.toml ~/.config/starship.toml
```

Make zsh your default shell (takes effect after a re-login):

```bash
chsh -s "$(which zsh)"
```

Install the JetBrainsMono Nerd Font:

```bash
mkdir -p ~/.local/share/fonts
curl -fsSL -o /tmp/JetBrainsMono.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -qo /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMonoNerd
fc-cache -f
rm -f /tmp/JetBrainsMono.zip
```

## 3. Git & GitHub CLI

Git is already in from step 1. Add the GitHub CLI from the official repo:

```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
sudo apt-get update -y
sudo apt-get install -y gh
```

Seed global git config from the templates (only if you don't already have one):

```bash
[ ! -f ~/.gitconfig ] && cp templates/gitconfig.sample ~/.gitconfig
[ ! -f ~/.gitignore_global ] && cp templates/gitignore_global ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
```

## 4. Go toolchain

The apt-packaged Go is usually stale — use the official tarball.

```bash
GO_VERSION=1.22.12
ARCH=$(dpkg --print-architecture)    # amd64 or arm64
curl -fsSL -o /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz
```

Add Go + `$GOBIN` to `PATH`:

```bash
cat >> ~/.zshrc <<'EOF'

# Go
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"
EOF

export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"
mkdir -p "$GOBIN"
```

Install the Go CLI tools:

```bash
go install golang.org/x/tools/gopls@latest
go install github.com/go-delve/delve/cmd/dlv@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install github.com/air-verse/air@latest
go install github.com/a-h/templ/cmd/templ@latest
go install golang.org/x/tools/cmd/goimports@latest
go install go.uber.org/mock/mockgen@latest
```

## 5. Node.js (via fnm)

Needed by Claude Code and several Neovim LSPs.

```bash
curl -fsSL https://fnm.vercel.app/install \
  | bash -s -- --install-dir "$HOME/.local/share/fnm" --skip-shell

cat >> ~/.zshrc <<'EOF'

# fnm
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --use-on-cd)"
EOF

export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env)"

fnm install --lts
fnm default lts-latest
```

Verify: `node --version && npm --version`

## 6. Docker Engine (from the official repo)

Remove any distro-shipped Docker that would conflict:

```bash
for p in docker.io docker-doc docker-compose podman-docker containerd runc; do
  sudo apt-get remove -y "$p" >/dev/null 2>&1 || true
done
```

Add the Docker apt repo — replace `ubuntu` with `debian` if you're on Debian:

```bash
DISTRO_ID=ubuntu    # or: debian
. /etc/os-release
DISTRO_CODENAME="$VERSION_CODENAME"

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/$DISTRO_ID/gpg" \
  | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO_ID $DISTRO_CODENAME stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Add yourself to the `docker` group (takes effect after a new login session):

```bash
sudo usermod -aG docker "$USER"
```

Optional TUI:

```bash
curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
```

## 7. Postgres

Pick **one** mode.

**Option A — Dockerized Postgres (recommended):** nothing to install now. Later:

```bash
docker compose -f templates/docker-compose.postgres.yml up -d
```

**Option B — Native Postgres 16 from PGDG:**

```bash
. /etc/os-release
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -fsSL -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
  https://www.postgresql.org/media/keys/ACCC4CF8.asc
echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" \
  | sudo tee /etc/apt/sources.list.d/pgdg.list >/dev/null
sudo apt-get update -y
sudo apt-get install -y postgresql-16
sudo systemctl enable --now postgresql
```

Client tools (install regardless of mode):

```bash
sudo apt-get install -y postgresql-client pgcli
```

## 8. Claude Code

```bash
npm install -g @anthropic-ai/claude-code
mkdir -p ~/.claude
```

Seed `~/.claude/settings.json` (skip if it already exists):

```bash
cat > ~/.claude/settings.json <<'JSON'
{
  "theme": "dark",
  "permissions": {
    "allow": ["Bash(git status)", "Bash(git diff:*)", "Bash(git log:*)"]
  }
}
JSON
```

Browser auth happens the first time you run `claude` — covered in `POSTINSTALL.md`.

## 9. Neovim + LazyVim

Ubuntu's `apt` Neovim often ships 0.9.x — LazyVim needs ≥ 0.10. On Ubuntu, use the unstable PPA; on Debian, use the AppImage.

**Ubuntu:**

```bash
sudo add-apt-repository -y ppa:neovim-ppa/unstable
sudo apt-get update -y
sudo apt-get install -y neovim
```

**Debian (AppImage fallback):**

```bash
sudo curl -fsSL -o /usr/local/bin/nvim \
  https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
sudo chmod +x /usr/local/bin/nvim
```

Companion tools:

```bash
sudo apt-get install -y ripgrep fd-find
# Ubuntu/Debian ship fd as "fdfind" — add a shim
mkdir -p ~/.local/bin
ln -sf "$(which fdfind)" ~/.local/bin/fd
```

Install lazygit:

```bash
case "$(uname -m)" in
  x86_64) LG_ARCH=Linux_x86_64 ;;
  aarch64|arm64) LG_ARCH=Linux_arm64 ;;
esac
curl -fsSLo /tmp/lazygit.tar.gz \
  "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_0.43.1_${LG_ARCH}.tar.gz"
sudo tar -xzf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
rm /tmp/lazygit.tar.gz
```

Clone the LazyVim starter into `~/.config/nvim` (only if you don't already have a nvim config):

```bash
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

## 10. CLI utilities

Core set from apt:

```bash
sudo apt-get install -y fzf bat jq httpie direnv tmux tree btop
# bat ships as "batcat" on Ubuntu/Debian — add a shim
mkdir -p ~/.local/bin
ln -sf "$(which batcat)" ~/.local/bin/bat
```

`eza` (not in older apt repos — use the official one):

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
  | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
  | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
sudo apt-get update -y
sudo apt-get install -y eza
```

`yq` (standalone binary):

```bash
case "$(uname -m)" in
  x86_64) YQ_ARCH=amd64 ;;
  aarch64|arm64) YQ_ARCH=arm64 ;;
esac
sudo curl -fsSLo /usr/local/bin/yq \
  "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${YQ_ARCH}"
sudo chmod +x /usr/local/bin/yq
```

1Password CLI (optional):

```bash
curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
  | sudo gpg --dearmor --yes -o /usr/share/keyrings/1password-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
  | sudo tee /etc/apt/sources.list.d/1password.list >/dev/null
sudo apt-get update -y
sudo apt-get install -y 1password-cli
```

Enable direnv and make sure `~/.local/bin` is on `PATH`:

```bash
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

---

## Post-install

1. Set zsh as your default (if you didn't in step 2) and re-login:
   ```bash
   chsh -s "$(which zsh)"
   ```
2. Log out and back in so the **docker group** membership takes effect.
3. `gh auth login` — GitHub CLI
4. `ssh-keygen -t ed25519 -C you@example.com` then `gh ssh-key add ~/.ssh/id_ed25519.pub`
5. `claude` — authenticate Claude Code in browser
6. Configure your terminal emulator to use **JetBrainsMono Nerd Font**
7. `nvim` → `:LazyExtras` → enable `lang.go`, `lang.docker`, `lang.sql`, `lang.tailwind`, `lang.json`, `lang.yaml`

See `POSTINSTALL.md` for the full follow-up checklist.

## Smoke test

```bash
go version
gh auth status
docker run --rm hello-world
claude --version
nvim --headless "+Lazy! sync" +qa
rg --version && fd --version && fzf --version && jq --version && direnv --version
```
