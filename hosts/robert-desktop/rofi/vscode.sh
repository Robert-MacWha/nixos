#!/usr/bin/env bash

VSCDB="$HOME/.config/Code/User/globalStorage/state.vscdb"

if [[ -z "$@" ]]; then
  sqlite3 "$VSCDB" "SELECT value FROM ItemTable WHERE key='history.recentlyOpenedPathsList'" \
    | jq -r '.entries[]? | .folderUri // .workspace // empty' \
    | sed 's|^file://||' \
    | sort -u
else
  code "$@"
fi