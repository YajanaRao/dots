# Dotfiles management using a bare git repository.
# Repository: https://github.com/YajanaRao/dots.git
# Setup: Bare git repo at ~/.dots tracking $HOME.

export def --wrapped dots [...rest] {
    let dots_git_dir = $env.HOME | path join ".dots"
    git $"--git-dir=($dots_git_dir)" $"--work-tree=($env.HOME)" ...$rest
}

export def lzd [] {
    lazygit $"--git-dir=($env.HOME | path join '.dots')" $"--work-tree=($env.HOME)"
}
