# Minimal Nushell config.
# Essential environment variables, PATH, zoxide, prompt, dotfiles, and a few abbreviations.
$env.PATH = ($env.PATH | prepend "/opt/homebrew/bin")

$env.config.buffer_editor = 'nvim'
$env.config.render_right_prompt_on_last_line = true
$env.config.edit_mode = 'vi'

use ($nu.default-config-dir | path join "modules/core.nu")
use ($nu.default-config-dir | path join "modules/zoxide.nu") *
use ($nu.default-config-dir | path join "modules/prompt.nu")
use ($nu.default-config-dir | path join "modules/aliases.nu")
use ($nu.default-config-dir | path join "modules/dotfiles.nu") *

# Forest Flower color theme (night variant).
use ($nu.default-config-dir | path join "forestflower.nu") *
$env.config.color_config = (forestflower-night)
