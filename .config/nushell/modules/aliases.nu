# Minimal abbreviations for common tools and git.

export-env {
    $env.config.abbreviations = {
        # Opencode
        oc: opencode

        # Lazygit
        lg: lazygit

        # Git
        gs: "git status -sb"
        ga: "git add"
        gc: "git commit"
        gcm: "git commit -m"
        gco: "git checkout"
        gp: "git push"
        gpl: "git pull"
        gd: "git diff"
        gds: "git diff --staged"

        # Job control
        fg: "job unfreeze"

        # Dotfiles (bare repo at ~/.dots tracking $HOME)
        dotss: "dots status -sb"
        dotsa: "dots add"
        dotsc: "dots commit"
        dotscm: "dots commit -m"
        dotsp: "dots push"
        dotspl: "dots pull"
        dotsd: "dots diff"
        dotsdc: "dots diff --cached"
        dotsl: "dots log --oneline --graph --decorate --all"
        dotsls: "dots ls-tree --full-tree -r --name-only HEAD"
    }
}
