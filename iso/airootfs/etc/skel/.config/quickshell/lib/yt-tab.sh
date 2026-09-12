#!/bin/bash
# yt-tab -- find a YouTube Music tab in any browser window and focus it.
# Nothing found? Open music.youtube.com in a fresh tab instead.
set -euo pipefail

addr=$(hyprctl -j clients 2>/dev/null | jq -r '
  [ .[]
    | select((.title // "" | test("YouTube Music"; "i"))
        or (.initialTitle // "" | test("music\\.youtube\\.com"; "i")))
  ] | .[0].address // empty')

if [[ -n $addr ]]; then
  ws=$(hyprctl -j clients 2>/dev/null | jq -r --arg a "$addr" '.[] | select(.address == $a) | .workspace.name')
  if [[ -n $ws ]]; then
    hyprctl dispatch movetoworkspace "$ws,address:$addr" >/dev/null
  fi
  hyprctl dispatch focuswindow "address:$addr" >/dev/null
else
  xdg-open "https://music.youtube.com" >/dev/null 2>&1 &
fi
