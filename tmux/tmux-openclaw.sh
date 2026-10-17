#!/usr/bin/env bash
# Persistent OpenClaw popup, shared across outer tmux sessions.
set -euo pipefail

SOCKET="openclaw-popup"
SESSION="openclaw"

# Clear the outer tmux environment when creating/attaching to the nested server.
unset TMUX
if ! tmux -L "$SOCKET" has-session -t "=$SESSION" 2>/dev/null; then
  tmux -L "$SOCKET" -f /dev/null new-session -d -s "$SESSION" \
    "openclaw tui --session agent:main:main" || \
    tmux -L "$SOCKET" has-session -t "=$SESSION"
fi

tmux -L "$SOCKET" set-option -g status off
tmux -L "$SOCKET" set-option -sg escape-time 0
tmux -L "$SOCKET" set-option -g prefix C-a
tmux -L "$SOCKET" set-option -g detach-on-destroy on
tmux -L "$SOCKET" bind-key d detach-client
tmux -L "$SOCKET" bind-key b detach-client

exec tmux -L "$SOCKET" attach-session -t "=$SESSION"
