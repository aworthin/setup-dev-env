# Dev Environment Setup Script

A comprehensive, cross-platform development environment installer for macOS and Linux. Sets up your entire dev stack with a single command.

## Quick Start

Run this command on a fresh machine or to update your existing environment:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/aworthin/setup-dev-env/main/setup-dev-env.sh)"
```

## What It Does

This script automates the setup of a complete development environment, including:

### Package Management
- ✅ Installs/updates Homebrew (macOS & Linux)
- ✅ Runs maintenance: `update`, `outdated`, `upgrade`, `upgrade --cask`, `cleanup`

### Shell Environment
- ✅ Installs oh-my-zsh with plugins:
  - zsh-autosuggestions
  - zsh-syntax-highlighting
  - Dracula theme
- ✅ Installs fzf with git integration (fzf-git.sh)
- ✅ Changes default shell to zsh
- ✅ Backs up existing `.zshrc` with timestamps

### CLI Development Tools
- ✅ Core: bat, eza, fd, fzf, jq, ripgrep, thefuck, tmux, neovim, zoxide, stow, git
- ✅ Docker: colima, docker, docker-buildx, docker-compose, lazydocker, kubernetes-cli
- ✅ Languages: go, golang-migrate, node, pyenv, jenv, openjdk@21, maven, ruff
- ✅ Git tools: gh, lazygit, git-delta
- ✅ Database: Microsoft SQL Server ODBC drivers and tools

### Applications (macOS)
- ✅ Terminal: iTerm2
- ✅ Editors/IDEs: Visual Studio Code, IntelliJ IDEA, DataGrip, GoLand, PyCharm
- ✅ API Testing: Bruno
- ✅ Productivity: Caffeine, Raycast
- ✅ Fonts: JetBrains Mono Nerd Font
- ✅ AI Tools: Claude Code CLI

### Dotfiles Management
- ✅ Clones your [dotfiles repository](https://github.com/aworthin/dotfiles)
- ✅ Uses GNU stow to symlink configurations (zsh, tmux, nvim)
- ✅ Creates `~/.zshrc.local` for machine-specific configs

## Features

### Idempotent & Safe
- Run multiple times without issues
- Updates existing packages
- Skips already-installed items
- Creates timestamped backups

### Cross-Platform
- Detects macOS vs Linux automatically
- Platform-specific application installation
- Homebrew works on both platforms

### Smart Backup System
- Backs up existing `.zshrc` with timestamps (`.zshrc.backup.YYYYMMDD_HHMMSS`)
- Creates `.zshbackup` symlink pointing to latest backup
- Never overwrites previous backups
- Easy to review backup history

### Post-Install Guidance
- Generates `~/.post-install-setup.txt` with configuration notes
- Clear documentation of what's already configured
- Guidance for optional configurations (Docker, jenv, pyenv)

## Platform Support

| Feature | macOS | Linux |
|---------|-------|-------|
| Homebrew | ✅ | ✅ |
| CLI Tools | ✅ | ✅ |
| oh-my-zsh | ✅ | ✅ |
| Dotfiles | ✅ | ✅ |
| GUI Apps (casks) | ✅ | ⚠️ Manual* |
| Claude Code | ✅ | ✅ |

\* Linux GUI apps require customization in the `install_linux_apps()` function

## Usage Scenarios

### New Machine Setup
```bash
# One command to set up everything
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/aworthin/setup-dev-env/main/setup-dev-env.sh)"
```

### Regular Updates
Run the same command monthly to:
- Update all Homebrew packages
- Update oh-my-zsh and plugins
- Pull latest dotfiles
- Keep everything current

### After System Recovery
Quickly restore your environment to the exact state you want.

## What Gets Configured Automatically

These configurations are **already in your dotfiles** and work automatically:

- ✅ **fzf** - Full shell integration with Dracula theme, fd/bat/eza integration
- ✅ **fzf-git.sh** - Git-specific fuzzy finding
- ✅ **zoxide** - Smart directory navigation (aliased as `cd`)
- ✅ **bat** - Syntax highlighting with Dracula theme
- ✅ **eza** - Modern ls replacement with icons and git status
- ✅ **thefuck** - Command correction (aliased as `oops`)

## Manual Configuration Required

Add these to `~/.zshrc.local` based on your needs:

### Docker (if using Docker/Colima)
Create `~/.docker/config.json`:
```json
{
  "cliPluginsExtraDirs": [
    "/opt/homebrew/lib/docker/cli-plugins"
  ]
}
```

Start colima:
```bash
brew services start colima
```

### Java Development (if using Java)
Add to `~/.zshrc.local`:
```bash
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"
```

One-time macOS system Java setup:
```bash
sudo ln -sfn /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk \
  /Library/Java/JavaVirtualMachines/openjdk-21.jdk
```

### Python Development (if using Python)
Add to `~/.zshrc.local`:
```bash
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
```

## Files Created

| File | Purpose |
|------|---------|
| `~/.zshrc.backup.YYYYMMDD_HHMMSS` | Timestamped backup of original .zshrc |
| `~/.zshbackup` | Symlink to latest backup |
| `~/.zshrc.local` | Machine-specific configurations |
| `~/.post-install-setup.txt` | Post-installation configuration notes |
| `~/dotfiles/` | Your dotfiles repository |
| `~/fzf-git.sh/` | fzf git integration |

## After Installation

1. **Restart your terminal** or run: `exec zsh`
2. **Review backups**: Check `~/.zshrc.backup.*` files and migrate custom configs to `~/.zshrc.local`
3. **Review post-install notes**: `cat ~/.post-install-setup.txt`
4. **Verify tools**: Test that your tools work correctly
5. **Linux users**: Customize `install_linux_apps()` function for GUI apps

## Customization

### For Your Own Use

1. Fork this repository
2. Update the dotfiles repository URL in the script (line ~470):
   ```bash
   local DOTFILES_REPO="https://github.com/yourusername/dotfiles.git"
   ```
3. Modify package lists to match your preferences
4. Customize Linux app installation for your distribution

### Linux GUI Apps

Edit the `install_linux_apps()` function in the script and uncomment/customize:

```bash
# Debian/Ubuntu example
sudo apt install code

# Arch example
sudo pacman -S code

# Install JetBrains Toolbox
curl -fsSL https://raw.githubusercontent.com/nagygergo/jetbrains-toolbox-install/master/jetbrains-toolbox.sh | bash
```

## Troubleshooting

### Script fails on Homebrew installation
- Ensure you have admin/sudo access
- Check your internet connection
- Visit [brew.sh](https://brew.sh) for Homebrew-specific issues

### Stow conflicts
- Script handles `.zshrc` conflicts automatically
- For other conflicts, check what files exist and whether they should be removed or kept

### Oh-my-zsh installation issues
- Check if `~/.oh-my-zsh` already exists
- Script is idempotent and handles existing installations

### Shell not changed to zsh
- Run manually: `chsh -s $(which zsh)`
- May require logout/login to take effect

## Related Repositories

- [Dotfiles](https://github.com/aworthin/dotfiles) - Configuration files managed by this script

## License

MIT License - Feel free to fork and customize for your own use.

## Contributing

This is a personal setup script, but suggestions and improvements are welcome via issues or pull requests.

---

**Note**: This script is designed for my personal development environment but can be easily customized for your needs. Review the script before running to ensure it matches your preferences.
