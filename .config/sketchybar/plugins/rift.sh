#!/bin/sh

# Rift -> SketchyBar integration.
# Queries rift once and updates all workspace items (rift.0 .. rift.9).
# Runs on startup, every $update_freq seconds, and on every rift event.

# Make sure rift forwards its events to sketchybar. Subscriptions are stored
# inside the rift process, so re-register if rift was restarted.
rift-cli subscribe unsub-cli workspace_changed &>/dev/null
rift-cli subscribe unsub-cli windows_changed &>/dev/null
rift-cli subscribe cli --event workspace_changed --command sh \
  --args=-c --args='sketchybar --trigger rift_update' &>/dev/null
rift-cli subscribe cli --event windows_changed --command sh \
  --args=-c --args='sketchybar --trigger rift_update' &>/dev/null

# Colors live in the Forest Flower repo. This script only places the pills.
# shellcheck disable=SC1091
. "$HOME/.config/sketchybar/forestflower.sh"
export ACTIVE_BG="$FF_ACTIVE_BG" ACTIVE_FG="$FF_ACTIVE_FG" OCC_FG="$FF_OCC_FG"

rift-cli query workspaces 2>/dev/null | python3 -c '
import json, os, subprocess, sys

try:
    workspaces = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)

active_bg, active_fg = os.environ["ACTIVE_BG"], os.environ["ACTIVE_FG"]
occ_fg = os.environ["OCC_FG"]

cmds = []
for i in range(10):
    ws = next((w for w in workspaces if w["index"] == i), None)
    item = f"rift.{i}"
    if ws is None or (ws["window_count"] == 0 and not ws["is_active"]):
        cmds += ["--set", item, "drawing=off"]
    elif ws["is_active"]:
        cmds += ["--set", item, "drawing=on", "background.drawing=on",
                 f"background.color={active_bg}", f"icon.color={active_fg}"]
    else:
        # omarchy-style: occupied workspaces are plain text, no pill
        cmds += ["--set", item, "drawing=on", "background.drawing=off",
                 f"icon.color={occ_fg}"]

if cmds:
    subprocess.run(["sketchybar", *cmds])
'
