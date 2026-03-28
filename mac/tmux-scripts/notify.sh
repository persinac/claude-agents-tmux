#!/usr/bin/env bash
# Sends a macOS notification via osascript.
# Falls back to terminal bell if osascript isn't available.
TITLE="${1:-Claude Code}"
MSG="${2:-Agent waiting for input}"

if command -v osascript &>/dev/null; then
  osascript -e "display notification \"$MSG\" with title \"$TITLE\" sound name \"Glass\"" 2>/dev/null &
else
  printf '\007' > /dev/tty 2>/dev/null
fi
