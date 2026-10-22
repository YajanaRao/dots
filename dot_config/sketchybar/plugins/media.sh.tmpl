#!/bin/sh

# Now-playing item (polling edition). media_change is deprecated on
# macOS 26 and unreliable since 15.4 (SketchyBar issue #708), so the item
# polls nowplaying-cli instead (update_freq in sketchybarrc).
#
# Shown as a purple pill while playing (same "active = pill" language as
# the bluetooth item); hidden otherwise. Sources other than Spotify/Music
# (e.g. Brave) must report an artist, so random browser videos don't show.
#
# Click toggles a card popup: artwork, title, artist/album and
# previous/play-pause/next (controls also via nowplaying-cli).

# shellcheck disable=SC1091
. "$HOME/.config/sketchybar/forestflower.sh"

collect() {
  INFO="$(nowplaying-cli get title artist album playbackRate 2>/dev/null)"
  TITLE="$(printf '%s\n' "$INFO" | sed -n 1p)"
  ARTIST="$(printf '%s\n' "$INFO" | sed -n 2p)"
  ALBUM="$(printf '%s\n' "$INFO" | sed -n 3p)"
  RATE="$(printf '%s\n' "$INFO" | sed -n 4p)"
  # 'get elapsedTime' is always 0 for Chromium; the raw dict has the real
  # values (last reported by the browser, good enough for a 5s poll).
  RAW="$(nowplaying-cli get-raw 2>/dev/null)"
  APP="$(printf '%s\n' "$RAW" \
       | sed -n 's/.*kMRMediaRemoteNowPlayingInfoClientBundleIdentifier" : "\([^"]*\)".*/\1/p')"
  ELAPSED="$(printf '%s\n' "$RAW" | sed -n 's/.*kMRMediaRemoteNowPlayingInfoElapsedTime" : \([0-9.]*\).*/\1/p')"
  DURATION="$(printf '%s\n' "$RAW" | sed -n 's/.*kMRMediaRemoteNowPlayingInfoDuration" : \([0-9.]*\).*/\1/p')"
  [ "$TITLE" = "null" ] && TITLE=""
  [ "$ARTIST" = "null" ] && ARTIST=""
  [ "$ALBUM" = "null" ] && ALBUM=""
}

# Card rows are 178pt wide with centered text; label.width hard-clips
# overflows (cutting both ends), so truncate to 24 chars ourselves first
# (Iosevka is monospaced: 24 chars ~ 175pt at the bar's font size).
fit() {
  LC_ALL=en_US.UTF-8 awk -v s="$1" 'BEGIN{
    if (length(s) > 24) printf "%s…", substr(s, 1, 23); else printf "%s", s
  }'
}

# Progress bar in the card popup (slider component, display only).
set_progress() {
  [ -n "$ELAPSED" ] && [ -n "$DURATION" ] || return 0
  PCT="$(awk -v e="$ELAPSED" -v d="$DURATION" 'BEGIN{ printf "%d", (d > 0) ? e / d * 100 : 0 }')"
  sketchybar --set media.progress "slider.percentage=$PCT"
}

STOPPED_FILE="/tmp/sketchybar_media_stopped"

update() {
  collect
  # Hide when: not playing, no title, or a non-music app without artist.
  # Debounced: two consecutive stopped polls are required, so the brief
  # playbackRate=0 flicker between tracks doesn't hide the pill / close
  # the card. A real pause hides within ~10s (two 5s polls).
  if [ "$RATE" != "1" ] || [ -z "$TITLE" ] || { [ "$APP" != "com.spotify.client" ] \
       && [ "$APP" != "com.apple.Music" ] && [ -z "$ARTIST" ]; }; then
    if [ -f "$STOPPED_FILE" ]; then
      rm -f "$STOPPED_FILE"
      sketchybar --set "$NAME" drawing=off popup.drawing=off background.drawing=off
    else
      : > "$STOPPED_FILE"
    fi
    return
  fi
  rm -f "$STOPPED_FILE"
  sketchybar --set "$NAME" drawing=on label="$ARTIST – $TITLE" \
             icon.color="$FF_ON_ACCENT" label.color="$FF_ON_ACCENT" \
             background.drawing=on background.color="$FF_MEDIA" \
             background.height=22 background.corner_radius=11
  set_progress
}

ART_RAW="/tmp/sketchybar_media_artwork.jpg"
ART_PNG="/tmp/sketchybar_media_artwork.png"

# Built-in background.image=media.artwork is broken on macOS 26 (same
# MediaRemote deprecation as media_change) — extract the artwork ourselves.
fetch_artwork() {
  nowplaying-cli get-raw 2>/dev/null \
    | sed -n 's/.*kMRMediaRemoteNowPlayingInfoArtworkData" : "\([^"]*\)".*/\1/p' \
    | tr -d '\\' | base64 --decode > "$ART_RAW" 2>/dev/null
  rm -f "$ART_PNG"
  [ -s "$ART_RAW" ] && sips -s format png -Z 178 "$ART_RAW" --out "$ART_PNG.tmp" >/dev/null 2>&1 \
    && mv "$ART_PNG.tmp" "$ART_PNG"
  [ -s "$ART_PNG" ]
}

open_card() {
  collect
  [ -z "$TITLE" ] && exit 0
  echo 1 > "$HOVER_FILE"  # mouse is over the pill when clicked

  if fetch_artwork; then
    sketchybar --set media.artwork drawing=on background.image="$ART_PNG" \
               background.image.drawing=on
  else
    sketchybar --set media.artwork drawing=off
  fi

  if [ -n "$ALBUM" ]; then
    sketchybar --set media.album drawing=on label="$ALBUM"
  else
    sketchybar --set media.album drawing=off
  fi

  PP=󰏤; [ "$RATE" = "1" ] || PP=󰐊
  sketchybar --set media.title label="$(fit "$TITLE")" \
             --set media.artist label="$(fit "$ARTIST")" \
             --set media.album label="$(fit "$ALBUM")" \
             --set media.controls slider.knob="󰒮      $PP      󰒭" \
             --set "$NAME" popup.drawing=on
  set_progress
}

# The horizontal controls row is a slider whose knob text is the three
# glyphs (track hidden): a slider natively reports the click's horizontal
# position as $PERCENTAGE, giving three click zones in a single popup row
# (SketchyBar popups are single-direction, no horizontal sub-layouts).
# Only clicks are intercepted here — enter/exit fall through to hover tracking.
if [ "$NAME" = "media.controls" ] && [ "$SENDER" = "mouse.clicked" ]; then
  PCT=${PERCENTAGE%%.*}
  if [ "$PCT" -lt 33 ]; then
    nowplaying-cli previous
  elif [ "$PCT" -lt 66 ]; then
    nowplaying-cli togglePlayPause
  else
    nowplaying-cli next
  fi
  # A click moves the slider knob to the click position; snap the icon row
  # back to the center.
  sketchybar --set media.controls slider.percentage=50
  exit 0
fi

# No click-outside-to-close exists in SketchyBar (no global click event), so
# the card auto-closes when the mouse leaves the pill and card for ~1s.
# A counter tracks hovering over the pill and every card row; the grace
# delay covers moving between rows.
HOVER_FILE="/tmp/sketchybar_media_hover"

hover_delta() {
  N="$(cat "$HOVER_FILE" 2>/dev/null)"; N=${N:-0}
  N=$((N + $1)); [ "$N" -lt 0 ] && N=0
  printf '%s' "$N" > "$HOVER_FILE"
  if [ "$N" -eq 0 ]; then
    sleep 1
    N="$(cat "$HOVER_FILE" 2>/dev/null)"; N=${N:-0}
    if [ "$N" -eq 0 ] && [ "$(sketchybar --query media | jq -r '.popup.drawing')" = "on" ]; then
      sketchybar --set media popup.drawing=off
    fi
  fi
}

case "$SENDER" in
  routine|forced)
    # All media.* popup items share this script (hover tracking); a forced
    # run (--update / config reload) executes it for every one of them.
    # Only the pill itself may be styled as the now-playing pill.
    [ "$NAME" = "media" ] || exit 0
    update ;;
  mouse.entered) hover_delta 1 ;;
  mouse.exited) hover_delta -1 ;;
  mouse.clicked)
    # Populate only when opening — same flicker reasoning as bluetooth.sh.
    if [ "$(sketchybar --query "$NAME" | jq -r '.popup.drawing // "off"')" = "on" ]; then
      echo 0 > "$HOVER_FILE"
      sketchybar --set "$NAME" popup.drawing=off
    else
      open_card
    fi
    ;;
esac
