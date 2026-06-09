#!/usr/bin/env bash
# scripts/rofi-watson.sh

get_combinations() {
  watson log --json -a 2>/dev/null \
    | jq -r '
        reverse
        | map(.project + (if .tags | length > 0 then " " + (.tags | map("+" + .) | join(" ")) else "" end))
        | unique
        | .[]
      '
}

get_status() {
  watson status 2>/dev/null | grep -v "No project started" || true
}

if [[ -z "$@" ]]; then
  # Show stop option if running
  STATUS=$(get_status)
  if [[ -n "$STATUS" ]]; then
    echo "stop | $STATUS"
  fi

  get_combinations
else
  if [[ "$@" == stop* ]]; then
    watson stop
  else
    watson start $@
  fi
fi