# Core environment variables and PATH.

use std/util "path add"

export-env {
    $env.EDITOR = "nvim"
    $env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")
    $env.config.edit_mode = 'vi'
    $env.config.table.mode = 'rounded'
    $env.config.show_banner = false

    path add ($env.HOME | path join "Library/pnpm/bin")
}
