# Manual install — macOS

Step-by-step equivalent of `bootstrap_macos.sh`. Follow top to bottom. Each block is idempotent — skip it if the tool is already installed.

Tested on macOS 14+ (Apple Silicon and Intel).

---

## 1. Xcode Command Line Tools

Required by Homebrew, Go, and most build tooling.

```bash
xcode-select --install
```

A GUI prompt appears; accept and wait for it to finish. Verify:

```bash
xcode-select -p
# → /Library/Developer/CommandLineTools
```

## 2. Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Add `brew` to your shell (Apple Silicon uses `/opt/homebrew`, Intel uses `/usr/local`):

```bash
# Apple Silicon
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

Verify: `brew --version`

## 3. Shell & terminal

```bash
brew install starship
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask ghostty
```

Enable Starship in zsh:

```bash
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
```

Seed the Starship config (optional — uses the one in this repo):

```bash
mkdir -p ~/.config
cp templates/starship.toml ~/.config/starship.toml
```

## 4. Git & GitHub CLI

```bash
brew install git gh
```

Seed global git config from the templates (only if you don't already have one):

```bash
[ ! -f ~/.gitconfig ] && cp templates/gitconfig.sample ~/.gitconfig
[ ! -f ~/.gitignore_global ] && cp templates/gitignore_global ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
```

## 5. Go toolchain

```bash
brew install go
```

Add `$GOBIN` to `PATH`:

```bash
cat >> ~/.zshrc <<'EOF'

# Go
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"
EOF

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

## 6. Node.js (via fnm)

Needed by Claude Code and several Neovim LSPs.

```bash
brew install fnm
echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
eval "$(fnm env)"

fnm install --lts
fnm default lts-latest
```

Verify: `node --version && npm --version`

## 7. Docker

Pick **one** runtime.

**Option A — OrbStack (recommended; paid for commercial use):**

```bash
brew install --cask orbstack
```

**Option B — Docker Desktop (free for personal / small business):**

```bash
brew install --cask docker
```

Optional TUI:

```bash
brew install lazydocker
```

Start the app once from `/Applications` so the Docker socket comes up, then:

```bash
docker run --rm hello-world
```

## 8. Postgres

Pick **one** mode.

**Option A — Dockerized Postgres (recommended):** nothing to install now. Later:

```bash
docker compose -f templates/docker-compose.postgres.yml up -d
```

**Option B — Native via Homebrew:**

```bash
brew install postgresql@16
```

**Option C — Homebrew service (starts on login):**

```bash
brew install postgresql@16
brew services start postgresql@16
```

Client tools (install regardless of mode):

```bash
brew install libpq pgcli
brew install --cask tableplus
```

## 9. Claude Code

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

## 10. Neovim + LazyVim

```bash
brew install neovim ripgrep fd lazygit
```

Clone the LazyVim starter into `~/.config/nvim` (only if you don't already have a nvim config):

```bash
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

## 11. CLI utilities

```bash
brew install fzf bat eza jq yq httpie direnv tmux tree btop coreutils
brew install 1password-cli
```

Enable direnv in zsh:

```bash
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
```

---

## Post-install

1. Restart your shell so all `~/.zshrc` changes take effect:
   ```bash
   exec zsh
   ```
2. `gh auth login` — GitHub CLI
3. `ssh-keygen -t ed25519 -C you@example.com` then `gh ssh-key add ~/.ssh/id_ed25519.pub`
4. `claude` — authenticate Claude Code in browser
5. Open Ghostty → set font to **JetBrainsMono Nerd Font**
6. `nvim` → `:LazyExtras` → enable `lang.go`, `lang.docker`, `lang.sql`, `lang.tailwind`, `lang.json`, `lang.yaml`

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
