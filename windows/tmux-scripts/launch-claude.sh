#!/usr/bin/env bash
REPO_DIR="${REPO_DIR:-/c/projects}"

selected=$(
  find "$REPO_DIR" -maxdepth 4 \( -name '.git' -type d -o -name '.git' -type f \) 2>/dev/null \
    | sed "s|${REPO_DIR}/||; s|/.git$||" \
    | sort \
    | fzf --prompt='repo> ' \
        --border=rounded \
        --preview="ls ${REPO_DIR}/{}" \
        --preview-window=right:40%
)

[ -z "$selected" ] && exit 0
tmux new-window -d -n "$selected" -c "${REPO_DIR}/${selected}" "claude"
