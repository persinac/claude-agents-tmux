#!/usr/bin/env bash
REPO_DIR="${REPO_DIR:-$HOME/garner/repos}"

selected=$(
  find "$REPO_DIR" -maxdepth 4 \( -name '.git' -type d -o -name '.git' -type f \) \
    | sed "s|${REPO_DIR}/||; s|/.git$||" \
    | sort \
    | fzf --prompt='repo> ' \
        --height=100% \
        --border=rounded \
        --preview="ls ${REPO_DIR}/{}" \
        --preview-window=right:40%
)

[ -z "$selected" ] && exit 0
tmux new-window -d -n "$selected" -c "${REPO_DIR}/${selected}" "claude"
