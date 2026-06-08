source ~/.config/fish/alias.fish
source ~/.config/fish/utils.fish
source ~/.config/fish/dotfiles.fish

set -x EDITOR nvim
set -gx COLORTERM truecolor


# Cursor styles
set -gx fish_vi_force_cursor 1
set -gx fish_cursor_default block
set -gx fish_cursor_insert line 
set -gx fish_cursor_visual block
set -gx fish_cursor_replace_one underscore

set -gx FZF_DEFAULT_OPTS "--color=hl:11,hl+:11,prompt:11,pointer:11,marker:2,info:8,header:8,spinner:11"

starship init fish | source
zoxide init fish | source

