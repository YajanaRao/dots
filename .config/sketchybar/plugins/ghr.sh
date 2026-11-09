#!/bin/sh

# ghr item — status display for the GitHub Actions run triggered by
# ~/.local/bin/ghr (herdr: prefix+alt+r).
#
# Bar display, battery-menu style:
#   ○ queued (grey)   ▓▓▓░░ 67% running (gold)   ✓ success / ✗ failure (icon)
# Left-click opens a detail card (workflow, repo · branch, progress, and an
# open-in-browser action). Right-click dismisses. Polling is event-driven:
# ghr pokes ghr_update on dispatch, we poll every 15s while active and drop
# to update_freq=0 when done. ghr-status (herdr) owns the state file and its
# 30-min expiry — this plugin only reads it, plus a small display cache so
# the card renders without an API call.

# shellcheck disable=SC1091
. "$HOME/.config/sketchybar/forestflower.sh"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ghr"
STATE="$STATE_DIR/run"
CACHE="$STATE_DIR/bar-cache"

# Glyphs via printf escapes — a literal ▓ once lost its lead byte in an
# edit and sketchybar showed its "Malformed UTF-8" warning instead.
I_QUEUED=$(printf '\342\227\213')   # ○
I_Q1=$(printf '\342\227\224')       # ◔
I_Q2=$(printf '\342\227\221')       # ◑
I_Q3=$(printf '\342\227\225')       # ◕
I_RUNNING=$(printf '\342\227\217')  # ●
I_SUCCESS=$(printf '\342\234\223')  # ✓
I_FAILURE=$(printf '\342\234\227')  # ✗
I_CANCEL=$(printf '\342\212\230')   # ⊘
BAR_FULL=$(printf '\342\226\223')   # ▓
BAR_EMPTY=$(printf '\342\226\221')  # ░

hide() { sketchybar --set ghr drawing=off update_freq=0; }

show() { # $1 icon, $2 color — bar stays icon-only
  sketchybar --set ghr drawing=on icon="$1" icon.color="$2" label.drawing=off
}

save_cache() { # $1 icon $2 color $3 branch $4 status_text $5 progress_text
  printf '%s\n%s\n%s\n%s\n%s\n' "$1" "$2" "$3" "$4" "$5" > "$CACHE"
}

dur() {
  s=$1
  if [ "$s" -ge 3600 ]; then printf '%dh%02dm' $((s/3600)) $((s%3600/60))
  elif [ "$s" -ge 60 ]; then printf '%dm' $((s/60))
  else printf '%ds' "$s"; fi
}

bar() { # $1 pct -> 5-cell block bar (same vocabulary as ghr-status in herdr)
  f=$(($1 / 20)); e=$((5 - f)); b=""
  while [ "$f" -gt 0 ]; do b="$b$BAR_FULL"; f=$((f - 1)); done
  while [ "$e" -gt 0 ]; do b="$b$BAR_EMPTY"; e=$((e - 1)); done
  printf '%s' "$b"
}

level_glyph() { # $1 pct -> fill-level circle, waybar format-icons style
  if   [ "$1" -ge 80 ]; then printf '%s' "$I_RUNNING"
  elif [ "$1" -ge 60 ]; then printf '%s' "$I_Q3"
  elif [ "$1" -ge 40 ]; then printf '%s' "$I_Q2"
  elif [ "$1" -ge 20 ]; then printf '%s' "$I_Q1"
  else printf '%s' "$I_QUEUED"; fi
}

final_icon() { # $1 conclusion -> "<icon> <color>"
  case "$1" in
    success) printf '%s %s\n' "$I_SUCCESS" "$FF_ACTIVE_BG" ;;
    failure) printf '%s %s\n' "$I_FAILURE" "$FF_DANGER" ;;
    *)       printf '%s %s\n' "$I_CANCEL" "$FF_CHEVRON" ;;
  esac
}

cap() { case "$1" in success) echo Success;; failure) echo Failed;; cancelled) echo Cancelled;; *) echo "${1:-Unknown}";; esac }

show_final() { # $1 conclusion, $2 extra progress text (duration)
  pair=$(final_icon "$1")
  show "${pair%% *}" "${pair##* }"
  save_cache "${pair%% *}" "${pair##* }" "$branch" "$(cap "$1")" "$2"
}

# ---- detail card ----------------------------------------------------------

toggle_card() {
  { [ -n "$repo" ] && [ -n "$id" ]; } || return 0
  if [ "$(sketchybar --query ghr | jq -r '.popup.drawing // "off"')" = "on" ]; then
    sketchybar --set ghr popup.drawing=off
    return 0
  fi

  icon="$I_QUEUED"; color="$FF_CHEVRON"; branch=""; status_text=""; progress_text=""
  if [ -f "$CACHE" ]; then
    icon=$(sed -n '1p' "$CACHE")
    color=$(sed -n '2p' "$CACHE")
    branch=$(sed -n '3p' "$CACHE")
    status_text=$(sed -n '4p' "$CACHE")
    progress_text=$(sed -n '5p' "$CACHE")
  fi
  [ -n "$branch" ] && branch=" · $branch"
  [ -n "$progress_text" ] && progress_text=" — $progress_text"

  sketchybar --remove '/ghr\.card\..*/' >/dev/null 2>&1
  sketchybar --add item ghr.card.title popup.ghr \
             --set ghr.card.title icon="$icon" icon.color="$color" \
                   label="$name" label.color="$FF_FG" \
             --add item ghr.card.repo popup.ghr \
             --set ghr.card.repo icon.drawing=off \
                   label="$repo$branch" label.color="$FF_CHEVRON" \
             --add item ghr.card.progress popup.ghr \
             --set ghr.card.progress icon.drawing=off \
                   label="$status_text$progress_text" label.color="$FF_FG" \
             --add item ghr.card.open popup.ghr \
             --set ghr.card.open icon.drawing=off \
                   label="Open run in browser" label.color="$FF_VOLUME" \
                   click_script="open 'https://github.com/$repo/actions/runs/$id'; sketchybar --set ghr popup.drawing=off"
  sketchybar --set ghr popup.drawing=on
}

# ---- state ----------------------------------------------------------------

repo=""; id=""; name=""
if [ -f "$STATE" ]; then
  repo=$(sed -n '1p' "$STATE")
  id=$(sed -n '2p' "$STATE")
  name=$(sed -n '3p' "$STATE")
fi

case "$SENDER" in
  mouse.clicked)
    case "$BUTTON" in
      right) rm -f "$STATE" "$CACHE"; hide ;;
      *) toggle_card ;;
    esac
    exit 0
    ;;
esac

{ [ -n "$repo" ] && [ -n "$id" ]; } || { hide; exit 0; }

# Cached final state ("concl epoch dur" on line 5): render without API call.
# Omarchy-style quick hide: the result icon lingers ~2 min, then the bar
# returns to neutral. ghr-status owns the state file's 30-min expiry.
final=$(sed -n '5p' "$STATE")
if [ -n "$final" ]; then
  set -- $final
  [ $(( $(date +%s) - $2 )) -gt 120 ] && { hide; exit 0; }
  branch=""; [ -f "$CACHE" ] && branch=$(sed -n '3p' "$CACHE")
  show_final "$1" "$3"
  sketchybar --set ghr update_freq=120
  exit 0
fi

json=$(gh run view "$id" --repo "$repo" \
       --json status,conclusion,createdAt,updatedAt,headBranch,jobs 2>/dev/null) || exit 0
# Progress = completed-or-skipped steps / total steps, like ghr-status.
row=$(printf '%s' "$json" | jq -r '
  ([.jobs[]?.steps[]?]) as $s
  | ($s | length) as $t
  | ([$s[] | select(.status == "completed" or .conclusion == "skipped")] | length) as $c
  | [.status, (.conclusion // ""),
     (.createdAt | fromdateiso8601 | floor | tostring),
     (.updatedAt | fromdateiso8601 | floor | tostring),
     (if $t > 0 then ($c * 100 / $t | floor | tostring) else "-1" end),
     (.headBranch // "")] | @tsv') || exit 0

status=$(printf '%s' "$row" | cut -f1)
concl=$(printf '%s' "$row" | cut -f2)
created=$(printf '%s' "$row" | cut -f3)
updated=$(printf '%s' "$row" | cut -f4)
pct=$(printf '%s' "$row" | cut -f5)
branch=$(printf '%s' "$row" | cut -f6)

if [ "$status" = "completed" ]; then
  # Quick hide: remember when it finished (cache line 6 survives reloads and
  # covers the window before ghr-status writes the final line) and linger
  # only ~2 min.
  done_epoch=$(sed -n '6p' "$CACHE" 2>/dev/null)
  [ -z "$done_epoch" ] && done_epoch=$updated
  [ $(( $(date +%s) - done_epoch )) -gt 120 ] && { hide; exit 0; }
  show_final "$concl" "$(dur $((updated - created)))"
  printf '%s\n' "$done_epoch" >> "$CACHE"
  sketchybar --set ghr update_freq=120
elif [ "$pct" -ge 0 ]; then
  # Running: fill-level glyph + pct (waybar format-icons style); the block
  # bar stays in the click card's detail row.
  sketchybar --set ghr drawing=on icon="$(level_glyph "$pct")" icon.color="$FF_BATTERY" \
                 label="$pct%" label.drawing=on label.color="$FF_FG"
  save_cache "$I_RUNNING" "$FF_BATTERY" "$branch" "Running" \
    "$(bar "$pct") $pct% · $(dur $(( $(date +%s) - created )))"
  sketchybar --set ghr update_freq=15
else
  show "$I_QUEUED" "$FF_CHEVRON"
  save_cache "$I_QUEUED" "$FF_CHEVRON" "$branch" "Queued" ""
  sketchybar --set ghr update_freq=15
fi
