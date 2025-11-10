alias vim=nvim

# git
abbr -a gs  git status -sb
abbr -a ga  git add
abbr -a gc  git commit
abbr -a gcm git commit -m
abbr -a gca git commit --amend
abbr -a gcl git clone
abbr -a gco git checkout
abbr -a gp  git push
abbr -a gpl git pull
abbr -a gl  git l
abbr -a gd  git diff
abbr -a gds git diff --staged
abbr -a gr  git rebase -i HEAD~15
abbr -a gf  git fetch
abbr -a gfc git findcommit
abbr -a gfm git findmessage

# lazygit
abbr -a lg lazygit

# File and Directories
alias ls="eza --color=auto --icons=auto --group-directories-first"
alias la 'eza --color=auto --icons=auto --group-directories-first --all --git'
alias ll 'eza --color=auto --icons=auto --group-directories-first --all --git --long'
