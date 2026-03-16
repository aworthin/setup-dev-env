#!/bin/bash

##############################################################################
# Dev Environment Setup Script
#
# A cross-platform (macOS/Linux) development environment installer
# Can be run via:
#   /bin/bash -c "$(curl -fsSL <your-raw-url>)"
#
# Features:
# - Installs/updates Homebrew and all development tools
# - Sets up oh-my-zsh with plugins and themes
# - Manages dotfiles with GNU stow
# - Idempotent: safe to run multiple times for updates
##############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

##############################################################################
# OS Detection
##############################################################################

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_info "Detected macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        log_info "Detected Linux"

        # Detect Linux distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            LINUX_DISTRO=$ID
            log_info "Linux distribution: $LINUX_DISTRO"
        fi
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

##############################################################################
# Homebrew Installation and Maintenance
##############################################################################

install_homebrew() {
    if ! command_exists brew; then
        log_info "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for this session
        if [[ "$OS" == "macos" ]]; then
            if [[ -d "/opt/homebrew/bin" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -d "/usr/local/bin" ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        elif [[ "$OS" == "linux" ]]; then
            if [[ -d "/home/linuxbrew/.linuxbrew/bin" ]]; then
                eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            fi
        fi

        log_success "Homebrew installed successfully"
    else
        log_info "Homebrew is already installed"
    fi
}

update_homebrew() {
    log_info "Updating Homebrew..."
    brew update

    log_info "Checking for outdated packages..."
    brew outdated

    log_info "Upgrading packages..."
    brew upgrade

    log_info "Upgrading casks..."
    brew upgrade --cask || log_warning "Cask upgrade skipped (may not be available on Linux)"

    log_info "Cleaning up old versions..."
    brew cleanup

    log_success "Homebrew maintenance completed"
}

##############################################################################
# Zsh Setup
##############################################################################

backup_zshrc() {
    if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
        # Create timestamped backup
        local TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        local BACKUP_FILE="$HOME/.zshrc.backup.$TIMESTAMP"

        log_info "Backing up existing .zshrc to .zshrc.backup.$TIMESTAMP"
        cp "$HOME/.zshrc" "$BACKUP_FILE"
        log_success ".zshrc backed up to $BACKUP_FILE"

        # Also create/update .zshbackup symlink to point to the latest backup
        # This maintains backward compatibility with the handle_zshlocal function
        ln -sf "$BACKUP_FILE" "$HOME/.zshbackup"
        log_info "Created symlink .zshbackup -> .zshrc.backup.$TIMESTAMP"
    else
        log_info "No .zshrc to backup or .zshrc is already a symlink"
    fi
}

install_ohmyzsh() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Installing oh-my-zsh..."
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        log_success "oh-my-zsh installed"
    else
        log_info "oh-my-zsh is already installed"
    fi
}

install_zsh_plugins() {
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        log_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        log_success "zsh-autosuggestions installed"
    else
        log_info "zsh-autosuggestions already installed"
    fi

    # zsh-syntax-highlighting
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        log_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        log_success "zsh-syntax-highlighting installed"
    else
        log_info "zsh-syntax-highlighting already installed"
    fi

    # Dracula theme for zsh
    if [[ ! -d "$ZSH_CUSTOM/themes/dracula" ]]; then
        log_info "Installing Dracula theme for zsh..."
        git clone https://github.com/dracula/zsh.git "$ZSH_CUSTOM/themes/dracula"
        ln -sf "$ZSH_CUSTOM/themes/dracula/dracula.zsh-theme" "$ZSH_CUSTOM/themes/dracula.zsh-theme"
        log_success "Dracula theme installed"
    else
        log_info "Dracula theme already installed"
    fi
}

install_fzf_git() {
    # Install fzf via brew (handled in install_cli_tools)
    # Install fzf-git.sh integration to match dotfiles path
    if [[ ! -d "$HOME/fzf-git.sh" ]]; then
        log_info "Installing fzf-git.sh..."
        git clone https://github.com/junegunn/fzf-git.sh.git "$HOME/fzf-git.sh"
        log_success "fzf-git.sh installed to ~/fzf-git.sh/"
    else
        log_info "fzf-git.sh already installed"
        cd "$HOME/fzf-git.sh"
        git pull
        log_info "fzf-git.sh updated"
    fi
}

install_tpm() {
    local TPM_DIR="$HOME/.tmux/plugins/tpm"

    if [[ ! -d "$TPM_DIR" ]]; then
        log_info "Installing TPM (Tmux Plugin Manager)..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
        log_success "TPM installed to ~/.tmux/plugins/tpm"
    else
        log_info "TPM already installed, updating..."
        cd "$TPM_DIR"
        git pull
        log_success "TPM updated"
    fi
}

change_default_shell() {
    if [[ "$SHELL" != *"zsh"* ]]; then
        log_info "Changing default shell to zsh..."

        # Get zsh path
        ZSH_PATH=$(command -v zsh)

        # Check if zsh is in /etc/shells
        if ! grep -q "$ZSH_PATH" /etc/shells; then
            log_info "Adding zsh to /etc/shells (requires sudo)..."
            echo "$ZSH_PATH" | sudo tee -a /etc/shells
        fi

        log_info "Running chsh (may require password)..."
        chsh -s "$ZSH_PATH"
        log_success "Default shell changed to zsh. Please restart your terminal or log out/in."
    else
        log_info "Default shell is already zsh"
    fi
}

##############################################################################
# CLI Tools Installation (Cross-platform)
##############################################################################

install_cli_tools() {
    log_info "Installing CLI tools via Homebrew..."

    # Add taps
    brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release

    # Core tools from .Brewfile.core
    local core_tools=(
        git
        bat
        eza
        fd
        fzf
        jq
        ripgrep
        thefuck
        tmux
        neovim
        zoxide
        stow
    )

    # Docker tools from .Brewfile.docker
    local docker_tools=(
        colima
        docker
        docker-buildx
        docker-compose
        docker-credential-helper
        lazydocker
        kubernetes-cli
    )

    # Language tools from .Brewfile.languages
    local language_tools=(
        go
        golang-migrate
        pyenv
        pyenv-virtualenv
        ruff
        node
        jenv
        openjdk@21
        maven
        gh
        lazygit
        git-delta
    )

    # Additional tools from current script
    local additional_tools=(
        beads
    )

    # Combine all tools
    local all_tools=("${core_tools[@]}" "${docker_tools[@]}" "${language_tools[@]}" "${additional_tools[@]}")

    # Install each tool
    for tool in "${all_tools[@]}"; do
        if ! brew list "$tool" &>/dev/null; then
            log_info "Installing $tool..."
            brew install "$tool"
        else
            log_info "$tool already installed"
        fi
    done

    # Microsoft SQL Server tools
    local mssql_tools=(
        microsoft/mssql-release/msodbcsql17
        microsoft/mssql-release/msodbcsql18
        microsoft/mssql-release/mssql-tools
    )

    for tool in "${mssql_tools[@]}"; do
        if ! brew list "${tool##*/}" &>/dev/null; then
            log_info "Installing $tool..."
            HOMEBREW_NO_ENV_FILTERING=1 ACCEPT_EULA=Y brew install "$tool"
        else
            log_info "${tool##*/} already installed"
        fi
    done

    log_success "CLI tools installation completed"
}

##############################################################################
# Claude Code Installation (Cross-platform)
##############################################################################

install_claude_code() {
    if command_exists claude; then
        log_info "Claude Code is already installed"
        return
    fi

    log_info "Installing Claude Code CLI..."
    log_info "Using native installer (auto-updates in background)..."

    # Use the native installer which works on both macOS and Linux
    curl -fsSL https://claude.ai/install.sh | bash

    log_success "Claude Code installed successfully"
    log_info "You can run 'claude' in any project directory after restarting your terminal"
}

##############################################################################
# macOS-specific Applications
##############################################################################

install_macos_apps() {
    if [[ "$OS" != "macos" ]]; then
        return
    fi

    log_info "Installing macOS applications via Homebrew Cask..."

    local casks=(
        # Terminal
        iterm2

        # Editors & IDEs
        visual-studio-code
        intellij-idea
        datagrip
        goland
        pycharm

        # API Testing
        bruno

        # Productivity
        caffeine
        raycast

        # Fonts
        font-jetbrains-mono-nerd-font
    )

    for cask in "${casks[@]}"; do
        if ! brew list --cask "$cask" &>/dev/null; then
            log_info "Installing $cask..."
            brew install --cask "$cask"
        else
            log_info "$cask already installed"
        fi
    done

    log_success "macOS applications installation completed"
}

##############################################################################
# Linux-specific Applications
##############################################################################

install_linux_apps() {
    if [[ "$OS" != "linux" ]]; then
        return
    fi

    log_info "Installing Linux applications..."
    log_warning "Linux GUI application installation is platform-specific."
    log_warning "Please customize this section for your distribution."

    # TODO: Add Linux-specific installation commands below
    # Examples for different package managers:

    # For Debian/Ubuntu (apt):
    # install_linux_vscode() {
    #     if ! command_exists code; then
    #         log_info "Installing Visual Studio Code..."
    #         wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    #         sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    #         sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    #         rm -f packages.microsoft.gpg
    #         sudo apt update
    #         sudo apt install code
    #     fi
    # }

    # For Fedora (dnf):
    # sudo dnf install code

    # For Arch (pacman):
    # sudo pacman -S code

    # JetBrains Toolbox (works across distributions):
    # install_linux_jetbrains() {
    #     if [[ ! -d "$HOME/.local/share/JetBrains/Toolbox" ]]; then
    #         log_info "Installing JetBrains Toolbox..."
    #         curl -fsSL https://raw.githubusercontent.com/nagygergo/jetbrains-toolbox-install/master/jetbrains-toolbox.sh | bash
    #     fi
    # }

    # Font installation (Debian/Ubuntu):
    # install_linux_fonts() {
    #     log_info "Installing JetBrains Mono Nerd Font..."
    #     mkdir -p ~/.local/share/fonts
    #     cd ~/.local/share/fonts
    #     curl -fLo "JetBrains Mono Nerd Font.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    #     unzip -o "JetBrains Mono Nerd Font.zip"
    #     rm "JetBrains Mono Nerd Font.zip"
    #     fc-cache -fv
    # }

    # Uncomment and customize the functions above based on your Linux distribution
    # install_linux_vscode
    # install_linux_jetbrains
    # install_linux_fonts

    log_info "Linux application installation section completed"
    log_info "Add your distribution-specific installation commands in the install_linux_apps() function"
}

##############################################################################
# Dotfiles Management
##############################################################################

handle_zshlocal() {
    # Check if there are any backup files
    local BACKUP_FILES=("$HOME"/.zshrc.backup.*)
    if [[ ! -e "${BACKUP_FILES[0]}" && ! -L "$HOME/.zshbackup" ]]; then
        log_info "No .zshrc backup files found, skipping .zshlocal creation"
        return
    fi

    log_info "Checking for custom additions in .zshrc backups..."

    # Create .zshrc.local if it doesn't exist (matches dotfiles convention)
    if [[ ! -f "$HOME/.zshrc.local" ]]; then
        touch "$HOME/.zshrc.local"
        log_info "Created empty .zshrc.local file"
    fi

    # Interactive section to help identify custom content
    echo ""
    log_warning "=================================================="
    log_warning "MANUAL STEP REQUIRED:"
    log_warning "=================================================="
    echo ""
    echo "Your old .zshrc has been backed up with timestamps:"
    ls -1t "$HOME"/.zshrc.backup.* 2>/dev/null | head -5
    echo ""
    echo "Latest backup symlinked at: ~/.zshbackup"
    echo ""
    echo "If you had any custom configurations (aliases, functions, exports),"
    echo "you should add them to ~/.zshrc.local"
    echo ""
    echo "Your dotfiles .zshrc sources ~/.zshrc.local automatically."
    echo ""
    read -p "Press ENTER to continue..."
}

clone_dotfiles() {
    local DOTFILES_DIR="$HOME/dotfiles"
    local DOTFILES_REPO="https://github.com/aworthin/dotfiles.git"

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_info "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        log_success "Dotfiles cloned to $DOTFILES_DIR"
    else
        log_info "Dotfiles directory already exists, pulling latest changes..."
        cd "$DOTFILES_DIR"
        git pull
        log_success "Dotfiles updated"
    fi
}

install_dotfiles() {
    local DOTFILES_DIR="$HOME/dotfiles"

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found at $DOTFILES_DIR"
        return 1
    fi

    log_info "Installing dotfiles with stow..."
    cd "$DOTFILES_DIR"

    # Remove existing .zshrc if it's not a symlink (oh-my-zsh created it)
    # We already backed it up earlier with timestamp, so it's safe to remove
    if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
        log_info "Removing oh-my-zsh generated .zshrc (already backed up with timestamp)"
        rm "$HOME/.zshrc"
    fi

    # Run stow for zsh, tmux, and nvim (as per install.sh in dotfiles repo)
    stow zsh tmux nvim

    log_success "Dotfiles installed (zsh, tmux, nvim configs symlinked)"
}

##############################################################################
# Post-Install Configuration
##############################################################################

setup_post_install_configs() {
    log_info "Setting up post-install configurations..."

    # These are configurations that need manual setup or are handled by dotfiles
    # We'll just provide information to the user

    local CONFIG_FILE="$HOME/.post-install-setup.txt"

    cat > "$CONFIG_FILE" << 'EOF'
================================================================================
POST-INSTALLATION CONFIGURATION NOTES
================================================================================

CONFIGURATIONS ALREADY IN YOUR DOTFILES (No action needed):
✅ fzf shell integration - configured with eval "$(fzf --zsh)"
✅ fzf-git.sh - sourced from ~/fzf-git.sh/fzf-git.sh
✅ zoxide - initialized with eval "$(zoxide init zsh)"
✅ TPM (Tmux Plugin Manager) - installed to ~/.tmux/plugins/tpm

================================================================================

MANUAL STEPS REQUIRED AFTER INSTALLATION:

1. TMUX PLUGIN INSTALLATION
   After starting tmux for the first time:
   - Press prefix + I (capital i) to fetch and install plugins
   - Default prefix is Ctrl+b
   - This installs all plugins defined in your tmux.conf

2. NEOVIM PLUGIN INSTALLATION
   After installation, run nvim:
   - Open neovim: nvim
   - Plugins will auto-install on first launch (if using lazy.nvim)
   - Or run :Lazy sync to install/update plugins manually

================================================================================

CONFIGURATIONS NEEDED (Add to ~/.zshrc.local):

1. DOCKER CONFIGURATION (Optional - if using Docker)
   Create or update ~/.docker/config.json:
   {
     "cliPluginsExtraDirs": [
       "/opt/homebrew/lib/docker/cli-plugins"
     ]
   }

   To start colima at login: brew services start colima

2. JENV INITIALIZATION (Add to ~/.zshrc.local if using Java)
   export PATH="$HOME/.jenv/bin:$PATH"
   eval "$(jenv init -)"

3. PYENV INITIALIZATION (Add to ~/.zshrc.local if using Python)
   export PYENV_ROOT="$HOME/.pyenv"
   export PATH="$PYENV_ROOT/bin:$PATH"
   eval "$(pyenv init -)"
   eval "$(pyenv virtualenv-init -)"

4. OPENJDK@21 SYSTEM LINK (macOS only - one-time setup)
   To make this the system Java:
   sudo ln -sfn /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk \
     /Library/Java/JavaVirtualMachines/openjdk-21.jdk

5. FONTS (Linux only)
   JetBrains Mono Nerd Font needs manual installation on Linux
   Download from: https://github.com/ryanoasis/nerd-fonts/releases

================================================================================

NOTES:
- Your .zshrc sources ~/.zshrc.local for machine-specific configurations
- Add jenv, pyenv, or other environment-specific configs to ~/.zshrc.local
- Docker config is optional and only needed if you use Docker/Colima

This file will be saved at: ~/.post-install-setup.txt

EOF

    log_success "Post-install notes saved to ~/.post-install-setup.txt"
}

##############################################################################
# Main Installation Flow
##############################################################################

main() {
    log_info "=========================================="
    log_info "Dev Environment Setup Script"
    log_info "=========================================="
    echo ""

    # 1. Detect OS
    detect_os
    echo ""

    # 2. Install and update Homebrew
    install_homebrew
    echo ""

    update_homebrew
    echo ""

    # 3. Backup .zshrc BEFORE oh-my-zsh installation
    backup_zshrc
    echo ""

    # 4. Install oh-my-zsh
    install_ohmyzsh
    echo ""

    # 5. Install zsh plugins and themes
    install_zsh_plugins
    echo ""

    # 6. Install fzf-git integration
    install_fzf_git
    echo ""

    # 7. Install TPM (Tmux Plugin Manager)
    install_tpm
    echo ""

    # 8. Install CLI tools (cross-platform)
    install_cli_tools
    echo ""

    # 9. Install Claude Code (cross-platform)
    install_claude_code
    echo ""

    # 10. Install platform-specific applications
    if [[ "$OS" == "macos" ]]; then
        install_macos_apps
    elif [[ "$OS" == "linux" ]]; then
        install_linux_apps
    fi
    echo ""

    # 11. Handle .zshbackup to .zshrc.local migration
    handle_zshlocal
    echo ""

    # 12. Clone/update dotfiles
    clone_dotfiles
    echo ""

    # 13. Install dotfiles with stow
    install_dotfiles
    echo ""

    # 14. Setup post-install configurations
    setup_post_install_configs
    echo ""

    # 15. Change default shell to zsh (do this last)
    change_default_shell
    echo ""

    # Final message
    log_success "=========================================="
    log_success "Dev Environment Setup Complete!"
    log_success "=========================================="
    echo ""
    log_info "Next steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Review timestamped backups (~/.zshrc.backup.*) and add custom configs to ~/.zshrc.local"
    echo "  3. Review ~/.post-install-setup.txt for additional configuration notes"
    echo "  4. Verify all tools are working correctly"
    echo ""

    if [[ "$OS" == "linux" ]]; then
        log_warning "Linux GUI apps were not installed automatically."
        log_warning "Please customize the install_linux_apps() function for your distribution."
        echo ""
    fi

    log_info "Configuration items to check in your dotfiles:"
    echo "  - fzf shell integration and fzf-git.sh sourcing"
    echo "  - Docker CLI plugins directory (~/.docker/config.json)"
    echo "  - jenv, pyenv, and zoxide initialization"
    echo ""
    log_info "See ~/.post-install-setup.txt for detailed instructions"

    if [[ "$OS" == "macos" ]]; then
        echo ""
        log_warning "Action required: Set your iTerm2 font to a Nerd Font for tmux powerline symbols to render correctly."
        echo "  iTerm2 → Preferences → Profiles → Text → Font → select a Nerd Font (e.g. JetBrainsMono Nerd Font)"
        echo "  Download Nerd Fonts at: https://www.nerdfonts.com/font-downloads"
    fi
}

# Run main function
main
