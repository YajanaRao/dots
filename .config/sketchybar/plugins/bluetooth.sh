#!/bin/sh

# Bluetooth item. Icon shows power/connection state, label shows the first
# connected device. Click toggles a popup listing paired devices; clicking a
# device connects/disconnects it. The popup also has a power row: "Turn
# Bluetooth Off" at the bottom when on, "Turn Bluetooth On" alone when off. While blueutil works, a spinner animates at
# the end of the clicked row's label (appended after the name so the name
# doesn't shift as frames change width); a failed connect/disconnect keeps
# the popup open and flashes the row red instead of failing silently.
# Requires blueutil.
#
# Also callable directly: bluetooth.sh device <address> <connect|disconnect> [row] [name]
# (used as click_script of the popup rows, where $NAME/$SENDER are unset).

# shellcheck disable=SC1091
. "$HOME/.config/sketchybar/forestflower.sh"

# sketchybar runs plugins with launchd's minimal PATH (/usr/bin:/bin:…), which
# does not include homebrew — without this, blueutil/jq/sketchybar itself are
# "command not found" here and the item shows the OFF state regardless.
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

ICON_ON="󰂯"
ICON_OFF="󰂲"
ICON_CONNECTED="󰂱"
SELF="$HOME/.config/sketchybar/plugins/bluetooth.sh"

update_icon() {
  if [ "$(blueutil --power)" != "1" ]; then
    sketchybar --set bluetooth icon="$ICON_OFF" icon.color="$FF_CHEVRON" label="" \
                   background.drawing=off
    return
  fi

  FIRST="$(blueutil --connected | head -1 | sed -E 's/.*name: "([^"]*)".*/\1/')"
  if [ -n "$FIRST" ]; then
    # Connected: forestflower accent pill ("act here / you are here").
    sketchybar --set bluetooth icon="$ICON_CONNECTED" icon.color="$FF_ON_ACCENT" \
                   label="$FIRST" label.color="$FF_ON_ACCENT" \
                   background.drawing=on background.color="$FF_ACCENT" \
                   background.height=22 background.corner_radius=11
  else
    sketchybar --set bluetooth icon="$ICON_ON" icon.color="$FF_CHEVRON" label="" \
                   background.drawing=off
  fi
}

spin_row() {
  # Braille spinner appended after the device name in the row's label, run in
  # the background while blueutil blocks. Appending (instead of swapping the
  # icon) keeps the name from shifting as frame widths change. Self-terminates
  # after ~15s or when the row goes away (popup rebuild/close).
  row="$1"
  name="$2"
  if [ -z "$name" ]; then
    name="$(sketchybar --query "$row" | jq -r '.label.value')"
  fi
  set -- ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
  n=0
  while [ "$n" -lt 150 ]; do
    sketchybar --set "$row" label="$name $1" 2>/dev/null || exit 0
    frame="$1"
    shift
    set -- "$@" "$frame"
    n=$((n+1))
    sleep 0.1
  done
}

toggle_device() {
  # Busy feedback before the blocking call: a connect can take up to the
  # --wait-connect timeout, and without it the popup looks dead after a click.
  spinner_pid=""
  if [ -n "$3" ]; then
    sketchybar --set "$3" label.color="$FF_CHEVRON"
    spin_row "$3" "$4" &
    spinner_pid=$!
  fi

  if [ "$2" = "connect" ]; then
    # Bound the attempt: connecting to an unreachable device otherwise makes
    # blueutil block for minutes, leaving the popup looking dead.
    blueutil --connect "$1" --wait-connect "$1" 10
  else
    blueutil --disconnect "$1"
  fi

  [ -n "$spinner_pid" ] && kill "$spinner_pid" 2>/dev/null

  # blueutil exits 0 even when the action did nothing ("Device not
  # connected"), so judge success by the resulting state, not the exit code.
  connected="$(blueutil --is-connected "$1" 2>/dev/null)"
  if [ "$2" = "connect" ]; then
    [ "$connected" = "1" ] && ok=0 || ok=1
  else
    [ "$connected" = "1" ] && ok=1 || ok=0
  fi

  if [ "$ok" -eq 0 ]; then
    sleep 1
    sketchybar --set bluetooth popup.drawing=off --trigger bluetooth_update
    return
  fi

  # Failed: keep the popup open and flash the clicked row red as feedback,
  # then rebuild the rows from live state to restore the correct colors.
  # Also restores the clean name — the label may still hold a spinner frame.
  if [ -n "$3" ]; then
    sketchybar --set "$3" label="$4" label.color="$FF_DANGER" icon.color="$FF_DANGER"
    sleep 2
    populate_popup
  fi
  sketchybar --trigger bluetooth_update
}

populate_popup() {
  sketchybar --remove '/bluetooth\.device\..*/' >/dev/null 2>&1

  if [ "$(blueutil --power)" != "1" ]; then
    sketchybar --add item bluetooth.device.power popup.bluetooth \
               --set bluetooth.device.power icon="$ICON_OFF" icon.color="$FF_CHEVRON" \
                     label="Turn Bluetooth On" label.color="$FF_FG" \
                     click_script="sketchybar --set bluetooth.device.power label='Turning On…' label.color='$FF_CHEVRON'; blueutil --power 1; sleep 1; sketchybar --set bluetooth popup.drawing=off --trigger bluetooth_update"
    return
  fi

  i=0
  blueutil --paired | while IFS= read -r dev; do
    addr="$(echo "$dev" | sed -E 's/^address: ([^,]+),.*/\1/')"
    name="$(echo "$dev" | sed -E 's/.*name: "([^"]*)".*/\1/')"
    # Connected rows read ", connected," — ", not connected," does not match.
    if echo "$dev" | grep -q ', connected,'; then
      icon="$ICON_CONNECTED"; color="$FF_VOLUME"; action="disconnect"
    else
      icon="$ICON_ON"; color="$FF_CHEVRON"; action="connect"
    fi
    # Escape ' for the single-quoted click_script (names like "Yajana's …").
    safe_name="$(printf '%s' "$name" | sed "s/'/'\\\\''/g")"
    sketchybar --add item "bluetooth.device.$i" popup.bluetooth \
               --set "bluetooth.device.$i" icon="$icon" icon.color="$color" \
                     label="$name" label.color="$FF_FG" \
                     click_script="'$SELF' device '$addr' '$action' 'bluetooth.device.$i' '$safe_name'"
    i=$((i+1))
  done

  # Power-off row at the bottom, mirroring "Turn Bluetooth On" above — without
  # it there is no way to switch Bluetooth off from the popup.
  sketchybar --add item bluetooth.device.poweroff popup.bluetooth \
             --set bluetooth.device.poweroff icon="$ICON_OFF" icon.color="$FF_CHEVRON" \
                   label="Turn Bluetooth Off" label.color="$FF_FG" \
                   click_script="sketchybar --set bluetooth.device.poweroff label='Turning Off…' label.color='$FF_CHEVRON'; blueutil --power 0; sleep 1; sketchybar --set bluetooth popup.drawing=off --trigger bluetooth_update"
}

if [ "$1" = "device" ]; then
  toggle_device "$2" "$3" "$4" "$5"
  exit 0
fi

case "$SENDER" in
  routine|forced|bluetooth_update) update_icon ;;
  mouse.clicked)
    # Repopulate only when opening — rebuilding the list while closing
    # causes a visible flicker.
    if [ "$(sketchybar --query bluetooth | jq -r '.popup.drawing // "off"')" = "on" ]; then
      sketchybar --set bluetooth popup.drawing=off
    else
      populate_popup
      sketchybar --set bluetooth popup.drawing=on
    fi
    ;;
esac
