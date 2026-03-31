#!/usr/bin/env bash
# Launch claude with recent checkpoint context injected as the opening message.
# Reads checkpoint notes from $NOTES_DIR for the current repo (past 3 days).
# Falls back to plain `claude` if no notes found.

[ -f "$HOME/.tmux/env.sh" ] && source "$HOME/.tmux/env.sh"

NOTES_DIR="${NOTES_DIR:-$HOME/garner/notes}"
REPO_PATH="${PWD}"
project_slug=$(basename "$REPO_PATH")

# BSD date (Mac): -v-3d; GNU date (Linux): -d '3 days ago'
cutoff=$(date -v-3d +%Y-%m-%d 2>/dev/null || date -d '3 days ago' +%Y-%m-%d)

# Collect matching checkpoint files from the past 3 days, sorted oldest→newest
context=""
while IFS= read -r f; do
  date_part=$(basename "$f" | cut -c1-10)
  if [[ "$date_part" > "$cutoff" || "$date_part" = "$cutoff" ]]; then
    context+="$(cat "$f")"$'\n\n'
  fi
done < <(ls -1 "$NOTES_DIR"/*-${project_slug}-checkpoint.md 2>/dev/null | sort)

if [ -n "$context" ]; then
  prompt="Here are recent checkpoint notes for this project (past 3 days). Please review them to get up to speed before we begin:"$'\n\n'"$context"
  exec claude "$prompt"
else
  exec claude
fi
