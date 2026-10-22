eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/Users/yajanarao/.bun/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# git / gh / lazygit aliases
[ -f "$HOME/.zsh_aliases" ] && source "$HOME/.zsh_aliases"
