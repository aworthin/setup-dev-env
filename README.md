# setup-dev-env

Cross-platform development environment installer for macOS and Linux.

> **Two-pass setup for Walmart developers**: this script is Pass 1 (run off VPN).
> Pass 2 (Walmart-specific tools) is a separate internal script.

## Quick start

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/aworthin/setup-dev-env/main/setup-dev-env.sh)"
```

> **Note**: Run off corporate VPN. The script checks `formulae.brew.sh` reachability at startup and warns if the network will block Homebrew installs.

Idempotent — safe to re-run anytime to update packages and pull latest dotfiles.

---

## What it installs

### Shell
- oh-my-zsh with zsh-autosuggestions, zsh-syntax-highlighting, Dracula theme
- fzf + fzf-git.sh integration
- TPM (Tmux Plugin Manager)
- Changes default shell to zsh

### Brew formulae — Core
`git` `bat` `eza` `fd` `fzf` `jq` `ripgrep` `thefuck` `tmux` `neovim` `zoxide` `stow` `direnv` `go-task` `git-lfs` `git-filter-repo` `fx` `zig` `air`

### Brew formulae — Docker
`colima` `docker` `docker-buildx` `docker-compose` `docker-credential-helper` `lazydocker` `kubernetes-cli`

### Brew formulae — Languages & Tools
`go` `golang-migrate` `pyenv` `pyenv-virtualenv` `ruff` `node` `jenv` `openjdk@17` `openjdk@21` `maven` `gh` `lazygit` `git-delta`

### Brew formulae — Databases
`postgresql@16` `beads` `dolt` `msodbcsql17` `msodbcsql18` `mssql-tools`

### Curl installers
`rustup` (Rust) · `nvm` (Node version manager) · `bun` · `uv` (Python package manager) · `specify` (GitHub Spec Kit)

### macOS apps (casks)
`iterm2` `visual-studio-code` `zed` `intellij-idea` `datagrip` `goland` `pycharm` `dbeaver-community` `bruno` `gcloud-cli` `caffeine` `raycast` `font-jetbrains-mono-nerd-font` `zulu@25`

### AI
`claude-code`

### Dotfiles
Clones `github.com/aworthin/dotfiles` to `~/dotfiles` and runs `stow zsh tmux nvim`.

---

## Shell config after install

Three files — source order: `.zshrc` → `.zshrc.wmt` → `.zshrc.local`

| File | Purpose | Committed? |
|------|---------|-----------|
| `~/.zshrc` | Generic config, lazy loaders, tool inits | ✅ Yes (dotfiles) |
| `~/.zshrc.wmt` | Work/corporate-specific config | No (gitignored) |
| `~/.zshrc.local` | Personal overrides | No (gitignored) |

Lazy loaders are used for NVM, jenv, gcloud, and thefuck — shell startup stays under 1 second.

---

## After install

1. **Restart terminal**: `exec zsh`
2. **Tmux plugins**: open tmux → `Ctrl+b` then `Shift+I`
3. **Neovim plugins**: open `nvim` — lazy.nvim auto-installs on first launch
4. **Register JDKs with jenv**:
   ```bash
   jenv add /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
   jenv add /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
   jenv add /Library/Java/JavaVirtualMachines/zulu-25.jdk/Contents/Home
   jenv global 21
   ```
5. **Docker** (optional): create `~/.docker/config.json`:
   ```json
   { "cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"] }
   ```
6. **pyenv** (optional): add to `~/.zshrc.local`:
   ```bash
   export PYENV_ROOT="$HOME/.pyenv"
   export PATH="$PYENV_ROOT/bin:$PATH"
   eval "$(pyenv init -)"
   eval "$(pyenv virtualenv-init -)"
   ```

---

## Dotfiles drift detection

After installing new tools, installers often append lines to `~/.zshrc`. The shell warns you on the next open:

```
⚠️  Shell config changed — run 'zshrc-drift' to review
```

Run `zshrc-drift` to triage each new block: move to `.zshrc.wmt`, `.zshrc.local`, keep and commit, or delete.

---

## Customization

1. Fork this repo
2. Update the dotfiles URL in `clone_dotfiles()`:
   ```bash
   local DOTFILES_REPO="https://github.com/yourusername/dotfiles.git"
   ```
3. Edit package lists and casks to match your preferences

---

## Related

- [dotfiles](https://github.com/aworthin/dotfiles) — shell, tmux, neovim configs managed by this script
