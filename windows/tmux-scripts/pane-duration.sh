#!/usr/bin/env bash
# Called by tmux status bar to show duration for a window.
# Shows wait duration (red state) OR idle duration (grey state).
# Usage: pane-duration.sh <window_id>
WINDOW="$1"
[ -z "$WINDOW" ] && exit 0

format_duration() {
  local elapsed=$1
  if [ "$elapsed" -lt 60 ]; then
    printf "%ds" "$elapsed"
  elif [ "$elapsed" -lt 3600 ]; then
    printf "%dm%ds" $((elapsed / 60)) $((elapsed % 60))
  else
    printf "%dh%dm" $((elapsed / 3600)) $(((elapsed % 3600) / 60))
  fi
}

# Check if waiting (red state)
WAITING=$(tmux show-option -wv -t "$WINDOW" @waiting 2>/dev/null)
if [ "$WAITING" = "1" ]; then
  SINCE=$(tmux show-option -wv -t "$WINDOW" @wait_since 2>/dev/null)
  [ -z "$SINCE" ] && exit 0
  NOW=$(date +%s)
  format_duration $((NOW - SINCE))
  exit 0
fi

# Check if idle (shell prompt, not running claude)
CMD=$(tmux display-message -t "$WINDOW" -p '#{pane_current_command}' 2>/dev/null)
if [ "$CMD" = "bash" ] || [ "$CMD" = "zsh" ]; then
  # Get the last agent action time for this window from apm.log
  PANE_ID=$(tmux display-message -t "$WINDOW" -p '#{pane_id}' 2>/dev/null)
  HOME_DIR="${HOME:-/c/Users/$USER}"
  LOG="$HOME_DIR/.tmux/apm.log"
  [ -f "$LOG" ] || exit 0

  # Find the most recent event for this pane
  LAST=$(grep "$PANE_ID" "$LOG" 2>/dev/null | tail -1 | awk '{print $1}')
  [ -z "$LAST" ] && exit 0

  NOW=$(date +%s)
  ELAPSED=$((NOW - LAST))
  # Only show if idle for more than 30 seconds
  [ "$ELAPSED" -lt 30 ] && exit 0
  format_duration "$ELAPSED"
fi
