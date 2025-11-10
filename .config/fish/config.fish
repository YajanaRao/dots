source ~/.config/fish/alias.fish
source ~/.config/fish/utils.fish
source ~/.config/fish/dotfiles.fish

if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Cursor styles
set -gx fish_vi_force_cursor 1
set -gx fish_cursor_default block
set -gx fish_cursor_insert line blink
set -gx fish_cursor_visual block
set -gx fish_cursor_replace_one underscore

starship init fish | source
zoxide init fish | source

