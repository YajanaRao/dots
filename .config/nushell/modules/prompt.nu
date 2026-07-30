# Starship-inspired native prompt: dir + git status, two-line, Nerd Font icons.
# Colors from the Forest Flower night palette (see forestflower.nu).

def ff-git []: nothing -> string {
    let raw = (do -i { ^git --no-optional-locks status --porcelain=v2 --branch } | complete)
    if $raw.exit_code != 0 { return "" }
    let lines = ($raw.stdout | lines)
    let branch = ($lines
        | where { |l| $l | str starts-with "# branch.head " }
        | get 0? | default "" | str replace "# branch.head " "")
    if ($branch | is-empty) or ($branch == "(detached)") { return "" }
    let ab = ($lines | where { |l| $l | str starts-with "# branch.ab " } | get 0? | default "")
    let dirty = ($lines | any { |l| not ($l | str starts-with "#") })

    let green = (ansi --escape { fg: '#A0AF54' })
    let red   = (ansi --escape { fg: '#F89A8A' })
    let reset = (ansi reset)

    mut out = $"($green) ($branch)"
    if $dirty { $out = $"($out)($red) ✗" }
    if ($ab | is-not-empty) {
        let parts = ($ab | str replace "# branch.ab " "" | split row " ")
        let ahead  = ($parts | get 0? | default "+0" | str replace "+" "" | into int)
        let behind = ($parts | get 1? | default "-0" | str replace "-" "" | into int)
        if $ahead > 0  { $out = $"($out)($red) ↑($ahead)" }
        if $behind > 0 { $out = $"($out)($red) ↓($behind)" }
    }
    $"($out)($reset)"
}

def ff-duration []: nothing -> string {
    let ms = ($env.CMD_DURATION_MS? | default "0" | into int)
    # Nushell initializes CMD_DURATION_MS to "0823" on startup (known quirk).
    if ($ms < 2000) or ($ms == 823) { return "" }
    let subtle = (ansi --escape { fg: '#969E95' })
    let reset = (ansi reset)
    let text = if $ms < 60000 {
        $"(($ms / 1000) | math round --precision 1)s"
    } else {
        let secs = ($ms / 1000 | into int)
        $"(($secs / 60) | into int)m(($secs mod 60))s"
    }
    $"($subtle)⏱ ($text)($reset)"
}

# Mimics Starship's default directory behavior: inside a git repo, show the path
# relative to the repo root and truncate to at most 3 parent folders.
def ff-dir []: nothing -> string {
    let home = $env.HOME
    let pwd = $env.PWD

    let git_toplevel = (do -i { ^git rev-parse --show-toplevel } | complete)
    if ($git_toplevel.exit_code == 0) and ($git_toplevel.stdout | str trim | is-not-empty) {
        let root = ($git_toplevel.stdout | str trim)
        let repo_name = ($root | path parse | get stem)
        # --show-prefix gives the current directory relative to the repo root and avoids
        # path mismatch issues (e.g., macOS /private/var vs /var symlinks).
        let prefix = (do -i { ^git rev-parse --show-prefix } | complete)
        let relative = ($prefix.stdout | str trim | str replace -r '/$' '')

        let full_path = if ($relative | is-empty) {
            $repo_name
        } else {
            $"($repo_name)/($relative)"
        }

        # Starship default truncation_length = 3 parent folders (3 parents + current dir = 4 segments).
        let parts = ($full_path | split row '/')
        let max_segments = 4
        if ($parts | length) > $max_segments {
            return ($parts | last $max_segments | str join '/')
        }
        return $full_path
    }

    # Not in a repo: show the full path with ~ for home.
    $pwd | str replace $home '~'
}

# Shared indicator renderer: green on success, red on failure.
def ff-indicator [symbol: string]: nothing -> string {
    let ok = ($env.LAST_EXIT_CODE? | default 0) == 0
    let color = if $ok { (ansi --escape { fg: '#BEC97E' }) } else { (ansi --escape { fg: '#F89A8A' }) }
    $"\n($color)($symbol)(ansi reset) "
}

export-env {
    $env.PROMPT_COMMAND = { ||
        let dir = (ff-dir)
        let blue = (ansi --escape { fg: '#92BFDB' attr: b })
        let orange = (ansi --escape { fg: '#EC8B49' })
        let reset = (ansi reset)

        let jobs = if (which "job list" | where type == built-in | is-not-empty) {
            try { job list | length } catch { 0 }
        } else {
            0
        }
        let job_seg = if $jobs > 0 { $"($orange) ✦($jobs)($reset)" } else { "" }

        $"($blue)($dir)($reset)(ff-git)($job_seg)"
    }

    $env.PROMPT_COMMAND_RIGHT = { ||
        let subtle = (ansi --escape { fg: '#969E95' })
        let reset = (ansi reset)
        let time = (date now | format date '%H:%M:%S')
        $"(ff-duration)  ($subtle)($time)($reset)"
    }

    $env.PROMPT_INDICATOR = { || ff-indicator "❯" }
    $env.PROMPT_INDICATOR_VI_INSERT = { || ff-indicator "❯" }
    $env.PROMPT_INDICATOR_VI_NORMAL = { || ff-indicator "❮" }

    # Collapse previously submitted prompts to a compact single line.
    $env.TRANSIENT_PROMPT_COMMAND = { ||
        let dir = (ff-dir)
        let blue = (ansi --escape { fg: '#92BFDB' })
        $"($blue)($dir)(ansi reset)"
    }
    $env.TRANSIENT_PROMPT_INDICATOR = { || $"❯ " }
    $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = { || $"❯ " }
    $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = { || $"❮ " }
    $env.TRANSIENT_PROMPT_COMMAND_RIGHT = { || "" }
}
