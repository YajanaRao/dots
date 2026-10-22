# dots — chezmoi source

This branch is the [chezmoi](https://chezmoi.io) source state for the dots
repo. One palette, every tool.

## The single source of truth

`.chezmoidata/forestflower.toml` — every Forest Flower hex, `[forestflower.day]`
and `[forestflower.night]`. **This is the only file a color is ever edited in.**

## Workflow

```sh
$EDITOR ~/.local/share/chezmoi/.chezmoidata/forestflower.toml
chezmoi diff     # every tool the change touches, before anything is written
chezmoi apply
chezmoi verify   # exits non-zero if live files drift from source
```

## What renders from the palette

| target | notes |
|---|---|
| `.config/ghostty/themes/forestflower-{day,night}` + `config` | themes by name, no absolute paths |
| `.config/opencode/themes/forestflower{,-day,-night}.json` | defs from palette; rules reference defs by name |
| `.config/herdr/config.toml` | `[theme.custom.*]` + `[ui].accent` (herdr has no include — whole-file template) |
| `.config/starship-forestflower-{day,night}.toml` | |
| `.config/delta/forestflower.gitconfig` | enable with `[delta] features = forestflower-night` |
| `.config/lazygit/forestflower-{day,night}.yml` | compose via `lazygit -ucf` |
| `.config/television/themes/forestflower-{day,night}.toml` | `forestflower.toml` stays a symlink the appearance watcher re-points |
| `.config/sketchybar/{forestflower.sh,theme.sh,sketchybarrc,plugins/*}` | 0xAARRGGBB via `trimPrefix`/lower filters |
| `.local/bin/ghr` | hex → `r;g;b` at runtime via `hx()` |
| `Developer/forestflower/lua/forestflower/themes/{day,night}.lua` | the nvim colorscheme itself renders from the same palette |

## Bootstrap a machine

```sh
brew install chezmoi
chezmoi init --branch chezmoi https://github.com/YajanaRao/dots.git
chezmoi diff   # review
chezmoi apply
```

## House rules

- Never edit a rendered file under `~/` — edit the palette or the template.
- New tool? Add `dot_config/<path>.tmpl`, wire hexes to tokens, `chezmoi diff` to review.
- Palette token missing? Add it to `forestflower.toml` (both variants), then use it.
- **Scripts need the `executable_` name prefix** (`executable_foo.sh.tmpl`).
  chezmoi sets modes by name, NOT from the source file's mode — a 644 plugin
  fails sketchybar/herdr *silently*. (Learned the hard way: rift workspace
  pills vanished because plugins lost +x.)
