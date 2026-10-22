#!/bin/sh

# Repaint SketchyBar when macOS switches between light and dark.
# sketchybarrc subscribes this script to AppleInterfaceThemeChangedNotification.
# Workspace pills are repainted by rift.sh via rift_update.
#
# Palette: ~/.config/sketchybar/forestflower.sh (chezmoi-generated from the
# dots forestflower.toml palette). Television themes likewise.

# shellcheck disable=SC1091
. "$HOME/.config/sketchybar/forestflower.sh"

sketchybar --bar color="$FF_BAR" \
           --set chevron icon.color="$FF_CHEVRON" \
           --set front_app label.color="$FF_FG" \
           --set clock icon.color="$FF_CLOCK" label.color="$FF_FG" \
           --set volume icon.color="$FF_VOLUME" label.color="$FF_FG" \
           --set battery icon.color="$FF_BATTERY" label.color="$FF_FG" \
           --set media icon.color="$FF_MEDIA" label.color="$FF_FG" \
                 popup.background.color="$FF_SELECTION" \
                 popup.background.border_color="$FF_CHEVRON" \
           --set bluetooth label.color="$FF_FG" \
                 popup.background.color="$FF_SELECTION" \
                 popup.background.border_color="$FF_CHEVRON" \
           --set ghr popup.background.color="$FF_SELECTION" \
                 popup.background.border_color="$FF_CHEVRON" \
           --trigger bluetooth_update \
           --trigger ghr_update \
           --trigger rift_update

# television: point the forestflower theme symlink at this mode's hex variant
ln -sfh "$HOME/.config/television/themes/forestflower-$FF_MODE.toml" \
  "$HOME/.config/television/themes/forestflower.toml" 2>/dev/null || :
