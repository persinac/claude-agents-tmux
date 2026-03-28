#!/usr/bin/env bash
# Symlinks config files from this repo into their expected locations.
# Run from the repo root: ./mac/install.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ln -sf "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"

mkdir -p "$HOME/.tmux"
for script in "$SCRIPT_DIR"/tmux-scripts/*.sh; do
  ln -sf "$script" "$HOME/.tmux/$(basename "$script")"
done

mkdir -p "$HOME/.claude"
if [ -f "$HOME/.claude/settings.json" ]; then
  echo "~/.claude/settings.json already exists — compare with claude-settings.json manually"
else
  ln -sf "$SCRIPT_DIR/claude-settings.json" "$HOME/.claude/settings.json"
fi

# Append zshrc sourcing if not already present
MARKER="# agent-orchestration"
if ! grep -qF "$MARKER" "$HOME/.zshrc" 2>/dev/null; then
  echo "" >> "$HOME/.zshrc"
  echo "$MARKER" >> "$HOME/.zshrc"
  echo "source \"$SCRIPT_DIR/zshrc\"" >> "$HOME/.zshrc"
  echo "Added source line to ~/.zshrc"
else
  echo "~/.zshrc already sources agent-orchestration"
fi

echo "Done. Reload with: tmux source ~/.tmux.conf"
