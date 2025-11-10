#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_REPO="https://github.com/YajanaRao/dots.git"
DOTFILES_DIR="$HOME/.dots"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

echo_info() {
    echo -e "${GREEN}==>${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

echo_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo_error "$1 is not installed. Please install it first."
        return 1
    fi
    return 0
}

# Check prerequisites
echo_info "Checking prerequisites..."

if ! check_command git; then
    echo_error "Git is required but not installed."
    exit 1
fi

# Check if dotfiles repository already exists
if [ -d "$DOTFILES_DIR" ]; then
    echo_warn "Dotfiles repository already exists at $DOTFILES_DIR"
    read -p "Do you want to remove it and reinstall? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo_info "Removing existing dotfiles repository..."
        rm -rf "$DOTFILES_DIR"
    else
        echo_info "Installation cancelled."
        exit 0
    fi
fi

# Clone dotfiles repository as bare repo
echo_info "Cloning dotfiles repository..."
git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"

# Define temporary alias
dots() {
    git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

# Configure repository
echo_info "Configuring dotfiles repository..."
dots config --local status.showUntrackedFiles no

# Backup existing files
echo_info "Checking for conflicting files..."
mkdir -p "$BACKUP_DIR"

if dots checkout main 2>&1 | grep -q "Please move or remove them before you switch branches"; then
    echo_warn "Found conflicting files. Backing them up to $BACKUP_DIR"
    
    dots checkout main 2>&1 | grep -E "\s+\." | awk '{print $1}' | while read -r file; do
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        mv "$HOME/$file" "$BACKUP_DIR/$file" 2>/dev/null || true
    done
fi

# Checkout dotfiles
echo_info "Checking out dotfiles to home directory..."
dots checkout main

if [ $? -ne 0 ]; then
    echo_error "Failed to checkout dotfiles. Please check the errors above."
    exit 1
fi

# Initialize submodules
echo_info "Initializing submodules..."
dots submodule update --init --recursive

# Set up .gitconfig.local if it doesn't exist
if [ ! -f "$HOME/.gitconfig.local" ]; then
    echo_info "Setting up machine-specific Git configuration..."
    cp "$HOME/.gitconfig.local.example" "$HOME/.gitconfig.local"
    
    echo
    echo_warn "Please edit ~/.gitconfig.local and add your email address:"
    echo "  [user]"
    echo "      email = your.email@example.com"
    echo
fi

# Check optional dependencies
echo
echo_info "Checking optional dependencies..."

optional_deps=(
    "fish:Fish shell (brew install fish)"
    "ghostty:Ghostty terminal (brew install --cask ghostty)"
    "aerospace:Aerospace window manager (brew install --cask nikitabobko/tap/aerospace)"
    "nvim:Neovim (brew install neovim)"
)

for dep in "${optional_deps[@]}"; do
    cmd="${dep%%:*}"
    desc="${dep#*:}"
    
    if command -v "$cmd" &> /dev/null; then
        echo_info "✓ $desc - installed"
    else
        echo_warn "✗ $desc - not installed"
    fi
done

# Fish shell setup
if command -v fish &> /dev/null; then
    echo
    read -p "Do you want to set Fish as your default shell? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        FISH_PATH=$(which fish)
        
        # Add fish to /etc/shells if not already there
        if ! grep -q "$FISH_PATH" /etc/shells; then
            echo_info "Adding Fish to /etc/shells (requires sudo)..."
            echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
        fi
        
        # Change default shell
        echo_info "Changing default shell to Fish..."
        chsh -s "$FISH_PATH"
        
        echo_info "Fish shell is now your default shell. Please restart your terminal."
    fi
fi

echo
echo_info "Installation complete! 🎉"
echo
echo "Next steps:"
echo "  1. Edit ~/.gitconfig.local and add your email"
echo "  2. Restart your terminal or run: source ~/.config/fish/config.fish"
echo "  3. Use 'dots' command to manage your dotfiles"
echo
echo "Useful commands:"
echo "  dotss  - Check status"
echo "  dotsa  - Add files"
echo "  dotsc  - Commit changes"
echo "  dotsp  - Push to remote"
echo "  dotspl - Pull from remote"
echo

if [ -d "$BACKUP_DIR" ] && [ -n "$(ls -A "$BACKUP_DIR")" ]; then
    echo_warn "Your original dotfiles have been backed up to:"
    echo "  $BACKUP_DIR"
    echo
fi
