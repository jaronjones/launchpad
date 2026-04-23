# POSTINSTALL

Manual steps the bootstrap scripts cannot do for you. Work through these once after the first successful run.

## 1. Restart your shell

The scripts append to `~/.zshrc` and `~/.zprofile`. Pick up the changes:

```bash
exec zsh
```

On Linux, if you haven't yet:

```bash
chsh -s "$(which zsh)"
# log out + log in
```

## 2. GitHub

### SSH key

```bash
ssh-keygen -t ed25519 -C "jaron.jones@gmail.com"
# accept default path, add a passphrase
```

### Authenticate `gh` and upload the key

```bash
gh auth login
# pick: GitHub.com → SSH → upload your public key → login via browser
```

Verify:

```bash
gh auth status
ssh -T git@github.com
```

### Optional: GPG signing

```bash
gpg --full-generate-key              # pick ed25519 / never expires / your email
gpg --list-secret-keys --keyid-format LONG
# copy the key ID after "sec   ed25519/"
git config --global user.signingkey <KEYID>
git config --global commit.gpgsign true
gpg --armor --export <KEYID> | gh gpg-key add -
```

## 3. Claude Code

```bash
claude
```

- Opens a browser to authenticate with your Anthropic account
- Creates `~/.claude/settings.json` (already seeded by the script with safe defaults)
- First run inside a project writes `.claude/` locally — add to `.gitignore` if not already

## 4. Terminal font

Set your terminal emulator's font to **"JetBrainsMono Nerd Font"** (installed by the script). LazyVim uses Nerd Font glyphs for file-tree icons, diagnostics, and git status — without it, you'll see replacement squares.

- **Ghostty** (macOS): Settings → font-family = `JetBrainsMono Nerd Font`
- **WezTerm**: edit `~/.wezterm.lua`, `font = wezterm.font("JetBrainsMono Nerd Font")`
- **gnome-terminal**: Preferences → Profile → Custom font

## 5. Neovim first launch

```bash
nvim
```

LazyVim bootstraps on first launch and installs plugins. Then:

```vim
:LazyExtras
```

Toggle on (space to select, `<CR>` to install):

- `lang.go`
- `lang.docker`
- `lang.sql`
- `lang.tailwind`
- `lang.json`
- `lang.yaml`

Quit + reopen. Run `:checkhealth` to confirm LSPs, treesitter, and external tools are all found.

### Claude Code plugin for Neovim

Add to `~/.config/nvim/lua/plugins/claude.lua`:

```lua
return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
    keys = {
      { "<leader>a", nil, desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    },
  },
}
```

## 6. Docker group (Linux only)

The script adds you to the `docker` group, but **group membership only takes effect after a new login session**. Log out and back in, then:

```bash
docker run --rm hello-world
```

## 7. Postgres

### If you picked "docker"

```bash
docker compose -f templates/docker-compose.postgres.yml up -d
psql postgresql://dev:dev@localhost:5432/dev
```

### If you picked "native" or "brew-service"

```bash
# create your first DB + user
createdb dev
psql dev
```

## 8. Accounts to verify

- [ ] Apple ID signed in (macOS)
- [ ] GitHub — 2FA enabled, SSH key uploaded
- [ ] Anthropic — Claude Code authenticated (`claude --version` prints)
- [ ] Docker Hub — only if you need private images
- [ ] 1Password — recommended home for API keys (`op signin`)

## 9. Smoke test the whole stack

```bash
go version
gh auth status
docker run --rm hello-world
claude --version
nvim --headless "+Lazy! sync" +qa
rg --version && fd --version && fzf --version && jq --version && direnv --version
```

All commands should exit 0.

## 10. Keeping up to date

```bash
# macOS
brew update && brew upgrade
fnm install --lts && fnm default lts-latest

# Linux
sudo apt-get update && sudo apt-get upgrade -y
fnm install --lts && fnm default lts-latest

# Go tools (both platforms)
for t in gopls dlv golangci-lint air templ goimports mockgen; do
  go install "$(go list -m -f '{{.Path}}' "$(command -v $t)" 2>/dev/null || true)@latest" 2>/dev/null || true
done

# Claude Code
npm update -g @anthropic-ai/claude-code
```
