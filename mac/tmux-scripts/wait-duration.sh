#!/usr/bin/env bash
WINDOW="$1"
[ -z "$WINDOW" ] && exit 0

WAITING=$(tmux show-option -wv -t "$WINDOW" @waiting 2>/dev/null)
[ "$WAITING" != "1" ] && exit 0

SINCE=$(tmux show-option -wv -t "$WINDOW" @wait_since 2>/dev/null)
[ -z "$SINCE" ] && exit 0

NOW=$(date +%s)
ELAPSED=$((NOW - SINCE))

if [ "$ELAPSED" -lt 60 ]; then
  printf "%ds" "$ELAPSED"
elif [ "$ELAPSED" -lt 3600 ]; then
  printf "%dm%ds" $((ELAPSED / 60)) $((ELAPSED % 60))
else
  printf "%dh%dm" $((ELAPSED / 3600)) $(((ELAPSED % 3600) / 60))
fi
