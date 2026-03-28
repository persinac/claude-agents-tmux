#!/usr/bin/env bash
# Returns the color code for a tmux window based on its state.
# Usage: pane-color.sh <window_id> [current]
# Output: tmux color format string
WINDOW="$1"
IS_CURRENT="$2"
[ -z "$WINDOW" ] && exit 0

WAITING=$(tmux show-option -wv -t "$WINDOW" @waiting 2>/dev/null)
if [ "$WAITING" = "1" ]; then
  echo "red bold"
  exit 0
fi

CMD=$(tmux display-message -t "$WINDOW" -p '#{pane_current_command}' 2>/dev/null)

# Check if claude is running (full path on Windows, just "claude" on unix)
if echo "$CMD" | grep -qi 'claude'; then
  echo "#a6e3a1"  # green — claude is active
else
  # Shell prompt — idle
  if [ "$IS_CURRENT" = "current" ]; then
    echo "white bold"
  else
    echo "#585b70"  # grey
  fi
fi
