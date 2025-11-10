# Dotfiles ☕️

My personal dotfiles managed as a bare Git repository.

## Features

- **Bare Git Repository**: Clean home directory without nested `.git` folders
- **Fish Shell**: Modern shell with custom aliases and utilities
- **Ghostty**: GPU-accelerated terminal emulator
- **Aerospace**: Tiling window manager for macOS
- **Neovim**: Custom configuration as a Git submodule
- **OpenCode**: AI coding assistant configuration
- **Security-First**: `.gitignore` excludes sensitive directories (ssh, tokens, credentials)

## What's Included

```
~/.gitignore                          # Global ignore rules
~/.gitconfig                          # Shared Git configuration
~/.gitconfig.local.example            # Template for machine-specific settings
~/.config/fish/                       # Fish shell configuration
  ├── config.fish                     # Main configuration
  ├── alias.fish                      # Command aliases
  ├── utils.fish                      # Utility functions
  └── dotfiles.fish                   # Dotfiles management abbreviations
~/.config/ghostty/config              # Terminal emulator settings
~/.config/aerospace/aerospace.toml    # Window manager configuration
~/.config/opencode/                   # OpenCode AI assistant
  ├── AGENTS.md                       # Agent instructions
  ├── .opencode.json                  # Configuration
  └── themes/                         # Custom themes
~/.config/nvim/                       # Neovim (submodule)
```

## Prerequisites

- Git
- Fish shell (`brew install fish`)
- Ghostty (`brew install --cask ghostty`)
- Aerospace (`brew install --cask nikitabobko/tap/aerospace`)
- Neovim (`brew install neovim`)

## Installation

### Fresh Install (New Machine)

1. **Clone the dotfiles repository as a bare repo:**
   ```bash
   git clone --bare https://github.com/YajanaRao/dots.git $HOME/.dots
   ```

2. **Define a temporary alias:**
   ```bash
   alias dots='git --git-dir=$HOME/.dots/ --work-tree=$HOME'
   ```

3. **Checkout the dotfiles:**
   ```bash
   dots checkout main
   ```
   
   If you get errors about existing files, backup or remove them:
   ```bash
   mkdir -p ~/.dotfiles-backup
   dots checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | xargs -I{} mv {} ~/.dotfiles-backup/{}
   dots checkout main
   ```

4. **Configure the repository to not show untracked files:**
   ```bash
   dots config --local status.showUntrackedFiles no
   ```

5. **Initialize the Neovim submodule:**
   ```bash
   dots submodule update --init --recursive
   ```

6. **Set up machine-specific Git configuration:**
   ```bash
   cp ~/.gitconfig.local.example ~/.gitconfig.local
   ```
   
   Edit `~/.gitconfig.local` and add your email:
   ```ini
   [user]
       email = your.email@example.com
   ```

7. **Set up OpenCode configuration (optional):**
   ```bash
   cp ~/.config/opencode/.opencode.json.example ~/.config/opencode/.opencode.json
   ```
   
   Edit `~/.config/opencode/.opencode.json` and add your API keys for the providers you use.

8. **Set Fish as your default shell:**
   ```bash
   echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
   chsh -s /opt/homebrew/bin/fish
   ```

9. **Reload Fish configuration:**
   ```fish
   source ~/.config/fish/config.fish
   ```

### Using the Install Script

Alternatively, use the automated install script:

```bash
curl -fsSL https://raw.githubusercontent.com/YajanaRao/dots/main/install.sh | bash
```

## Usage

After installation, Fish shell will have these abbreviations available:

- `dots` - Main dotfiles command (equivalent to `git --git-dir=$HOME/.dots/ --work-tree=$HOME`)
- `dotss` - Check dotfiles status
- `dotsa` - Add files to dotfiles
- `dotsc` - Commit dotfiles changes
- `dotsp` - Push dotfiles to remote
- `dotspl` - Pull dotfiles from remote
- `dotsd` - Show dotfiles diff
- `dotsl` - Show dotfiles log

### Adding New Dotfiles

1. Make changes to your config files
2. Check what changed:
   ```fish
   dotss
   ```
3. Add files you want to track:
   ```fish
   dotsa ~/.config/some-app/config.yml
   ```
4. Commit your changes:
   ```fish
   dotsc "Add some-app configuration"
   ```
5. Push to GitHub:
   ```fish
   dotsp
   ```

### Updating Dotfiles on Another Machine

```fish
dotspl  # Pull latest changes
dots submodule update --recursive  # Update submodules if needed
```

## Security

The following directories and files are **never** tracked:

- `~/.ssh/` - SSH keys
- `~/.config/gh/` - GitHub CLI credentials
- `~/.config/github-copilot/` - GitHub Copilot tokens
- `~/.gnupg/` - GPG keys
- `~/.config/configstore/` - Various API tokens
- `~/.config/opencode/.opencode.json` - OpenCode API keys
- `node_modules/` - Dependencies

**Machine-specific secrets:**
- Your email is stored in `~/.gitconfig.local` (not tracked)
- API keys are stored in `~/.config/opencode/.opencode.json` (not tracked)

## Neovim Configuration

Neovim is managed as a separate Git submodule from [YajanaRao/nvim](https://github.com/YajanaRao/nvim).

To update Neovim configuration:

```fish
cd ~/.config/nvim
git pull origin main
cd ~
dotsa ~/.config/nvim
dotsc "Update nvim submodule"
dotsp
```

## Troubleshooting

### Fish abbreviations not working

Reload the Fish configuration:
```fish
source ~/.config/fish/config.fish
```

### Submodule is empty

Initialize and update submodules:
```fish
dots submodule update --init --recursive
```

### Files showing as modified

Make sure untracked files are hidden:
```fish
dots config --local status.showUntrackedFiles no
```

## License

MIT

## References

- [Atlassian Bare Repository Tutorial](https://www.atlassian.com/git/tutorials/dotfiles)
- [Fish Shell Documentation](https://fishshell.com/docs/current/)
- [Ghostty Documentation](https://ghostty.org/)
- [Aerospace Documentation](https://nikitabobko.github.io/AeroSpace/)
