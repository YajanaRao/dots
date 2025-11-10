# Dotfiles management using bare git repository
# Repository: https://github.com/YajanaRao/dots.git
# Setup: Bare git repo at ~/.dots tracking $HOME

# Core dotfiles command
abbr -a dots 'git --git-dir=$HOME/.dots/ --work-tree=$HOME'

# Common operations
abbr -a dotss 'dots status -sb'
abbr -a dotsa 'dots add'
abbr -a dotsc 'dots commit'
abbr -a dotscm 'dots commit -m'
abbr -a dotsp 'dots push'
abbr -a dotspl 'dots pull'
abbr -a dotsd 'dots diff'
abbr -a dotsdc 'dots diff --cached'
abbr -a dotsl 'dots log --oneline --graph --decorate --all'
abbr -a dotsls 'dots ls-tree --full-tree -r --name-only HEAD'

# Helper function to safely add files (shows what will be added)
function dots-add-safe
    set -l files $argv
    if test (count $files) -eq 0
        echo "Usage: dots-add-safe <file1> [file2...]"
        return 1
    end
    
    echo "📋 Files to be added:"
    for file in $files
        echo "  - $file"
    end
    
    echo ""
    read -l -P "Add these files? [y/N] " confirm
    if test "$confirm" = "y" -o "$confirm" = "Y"
        dots add $files
        echo "✅ Files staged. Use 'dotsd --cached' to review changes."
    else
        echo "❌ Cancelled"
    end
end

# Helper to list all tracked dotfiles
function dots-list
    echo "📁 Tracked dotfiles:"
    dots ls-tree --full-tree -r --name-only HEAD
end

# Helper to show untracked files that might be dotfiles
function dots-find
    echo "🔍 Potential dotfiles in ~/.config:"
    ls -la ~/.config/ | awk 'NR>1 && !/^d/ {print "  " $9}'
end
