abbr vi nvim
abbr vim nvim
abbr mvim NVIM_APPNAME=nvim-minimax nvim
abbr lvim NVIM_APPNAME=lazyvim nvim



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

#opencode
abbr -a oc opencode

# Lazygit
abbr -a lg lazygit
alias lzd 'lazygit --git-dir=$HOME/.dots --work-tree=$HOME'

# File and Directories
alias ls "eza --color=auto --icons=auto --group-directories-first"
alias la 'eza --color=auto --icons=auto --group-directories-first --all --git'
alias ll 'eza --color=auto --icons=auto --group-directories-first --all --git --long'

# Dots
alias dots='git --git-dir=$HOME/.dots/ --work-tree=$HOME'
