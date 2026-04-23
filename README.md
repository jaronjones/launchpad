# dev-starter

Opinionated fresh-box setup for developing **Go + htmx** apps backed by **Postgres**, running in **Docker**, versioned on **GitHub**, and edited with **Claude Code + Neovim (LazyVim)**.

Targets **macOS** (Apple Silicon or Intel) and **Ubuntu/Debian** Linux.

## Quick start

```bash
git clone <this-repo> ~/my-dev/dev-starter
cd ~/my-dev/dev-starter

# macOS
bash bootstrap_macos.sh

# Linux (Ubuntu/Debian)
bash bootstrap_linux.sh
```

Then work through [`POSTINSTALL.md`](POSTINSTALL.md) for the manual steps (accounts, SSH keys, Claude Code auth).

Both scripts are **idempotent** — re-running them is safe and only installs what's missing.

## Reference cheatsheets

New to the terminal or git? Start here:

- [`TERMINAL_COMMANDS.md`](TERMINAL_COMMANDS.md) — top 20 terminal commands (navigation, file ops, search, processes, networking)
- [`GITHUB_COMMANDS.md`](GITHUB_COMMANDS.md) — top 10 git/GitHub commands (daily workflow, branching, `gh` CLI basics)

### Useful flags

```
--skip-editor        Skip Neovim + LazyVim install
--skip-docker        Skip Docker/OrbStack install
--dry-run            Print what would be installed, don't do it
--verbose            Verbose output
```

### Non-interactive mode (for CI / VM testing)

```
POSTGRES_MODE=docker          # docker | native | brew-service
DOCKER_RUNTIME=orbstack       # orbstack | desktop      (macOS only)
SKIP_PROMPTS=1                # accept defaults everywhere
```

## The list — everything a dev needs

### 1. OS prerequisites
- **macOS**: latest point-update, Xcode Command Line Tools (`xcode-select --install`)
- **Linux**: `apt update && apt upgrade`, `build-essential`, `curl`, `git`, `ca-certificates`, `gnupg`, `lsb-release`

### 2. Package manager
- **macOS**: Homebrew (auto-detects `/opt/homebrew` on Apple Silicon, `/usr/local` on Intel)
- **Linux**: `apt` + official upstream repos for Docker, Go, Postgres, GitHub CLI

### 3. Shell & terminal
- zsh (default on macOS; `apt install zsh` + `chsh` on Linux)
- Starship prompt (config in `templates/starship.toml`)
- JetBrainsMono Nerd Font — required by LazyVim icons
- Terminal emulator: **Ghostty** (macOS) / **WezTerm** (cross-platform)

### 4. Git & GitHub
- `git`
- `gh` — GitHub CLI
- Generate ed25519 SSH key and upload via `gh ssh-key add`  _(manual)_
- `gh auth login`  _(manual)_
- Global gitconfig seeded from `templates/gitconfig.sample` (`user.email=jaron.jones@gmail.com`, `pull.rebase=true`, `init.defaultBranch=main`)
- Global `.gitignore` seeded from `templates/gitignore_global`
- GPG signing key — optional  _(manual)_

### 5. Go toolchain
- `go` — latest stable (brew on macOS, official tarball to `/usr/local/go` on Linux since apt lags)
- `$GOBIN` = `$HOME/go/bin` added to `PATH`
- CLI tools installed via `go install`:
  - `gopls` — LSP
  - `dlv` (delve) — debugger
  - `golangci-lint`
  - `air` — hot reload for Go web apps
  - `templ` — htmx-friendly Go templating (`a-h/templ`)
  - `goimports`
  - `mockgen`

### 6. htmx + friends
No install — serve from vendored `/static/htmx.min.js` (CDN is fine for prototypes; vendor for prod).

Complements worth knowing:
- **Alpine.js** — small client-side state
- **Tailwind CSS standalone CLI** — single binary, no npm needed for simple projects
- htmx extensions worth bookmarking: `response-targets`, `sse`, `preload`, `ws`

### 7. Postgres — pick your flavor (script prompts you)

| Option | When to use |
|---|---|
| **Docker container** (recommended) | Per-project isolation, matches prod, nothing on host. Uses `templates/docker-compose.postgres.yml`. |
| **Native install** | Always-on local DB, no Docker overhead. macOS: Postgres.app or `brew install postgresql@16`. Linux: `apt install postgresql-16` from the PGDG repo. |
| **Homebrew service** (macOS only) | `brew services start postgresql@16` — survives reboots, easy to manage. |

Client tools installed regardless of choice:
- `psql`
- `pgcli` — better REPL with autocomplete
- **TablePlus** (macOS) or **DBeaver CE** (cross-platform) — GUI

### 8. Docker — pick your runtime (script prompts you on macOS)

| Option | When to use |
|---|---|
| **OrbStack** (macOS only, recommended) | Faster, lighter, better battery. **Paid for commercial use.** |
| **Docker Desktop** | Official, maximum compatibility. Free for personal/small-biz. |
| **Docker Engine** (Linux) | Installed from the official `docs.docker.com` apt repo; no Desktop needed. User added to `docker` group. |

Both runtimes include `docker compose` v2. `lazydocker` installed as an optional TUI.

### 9. Node.js
Required by Claude Code and some Neovim LSPs.
- `fnm` (Fast Node Manager) — lighter and faster than nvm
- Node LTS installed via `fnm install --lts`

### 10. Claude Code
- `npm install -g @anthropic-ai/claude-code`
- `claude` → browser auth  _(manual — requires Anthropic account)_
- `~/.claude/settings.json` seeded with sensible defaults if absent
- Neovim integration: `coder/claudecode.nvim` plugin (added to LazyVim plugin spec)

### 11. Editor — Neovim + LazyVim
- Neovim ≥ 0.10 (`brew install neovim` / `apt install neovim` — if apt ships older, script installs from the unstable PPA)
- LazyVim starter cloned into `~/.config/nvim` (git history stripped so it's yours)
- Companion tools (LazyVim hard deps): `ripgrep`, `fd`, `lazygit`, Nerd Font, `gcc`/`make`, `node`, `git`
- LazyVim extras to enable on first launch (`:LazyExtras`):
  - `lang.go`
  - `lang.docker`
  - `lang.sql`
  - `lang.tailwind`
  - `lang.json` / `lang.yaml`
  - `editor.telescope`
- htmx works via the HTML LSP; add filetype detection for `*.templ` via the go-templ tree-sitter parser

### 12. Developer CLI utilities
Installed as one batch:
`ripgrep`, `fd`, `fzf`, `bat`, `eza`, `jq`, `yq`, `httpie`, `direnv`, `tmux`, `tree`, `btop`, `lazygit`, `1password-cli` (`op`), GNU coreutils (macOS only)

### 13. Accounts (manual — see POSTINSTALL.md)
- Apple ID (macOS) — signed in
- GitHub — 2FA enabled, SSH key uploaded
- Anthropic — Claude Code authenticated
- Docker Hub — only if you need private images
- 1Password — recommended for API keys/secrets

## File layout

```
dev-starter/
├── README.md                         # this file
├── bootstrap_macos.sh                # idempotent macOS installer
├── bootstrap_linux.sh                # idempotent Ubuntu/Debian installer
├── POSTINSTALL.md                    # manual follow-up steps
├── TERMINAL_COMMANDS.md              # top 20 terminal commands cheatsheet
├── GITHUB_COMMANDS.md                # top 10 git/GitHub commands cheatsheet
├── .gitignore
└── templates/
    ├── docker-compose.postgres.yml   # Postgres 16 + volume + healthcheck
    ├── gitconfig.sample              # seed for ~/.gitconfig
    ├── gitignore_global              # seed for ~/.gitignore_global
    └── starship.toml                 # seed for ~/.config/starship.toml
```

## Verifying the install

```bash
go version
gh auth status
docker run --rm hello-world
docker compose -f templates/docker-compose.postgres.yml up -d && pg_isready -h localhost
claude --version
nvim --headless "+Lazy! sync" +qa
rg --version && fd --version && fzf --version && jq --version && direnv --version
```

Re-run `bootstrap_macos.sh` or `bootstrap_linux.sh` on an already-provisioned box — it should be a near-instant no-op.
