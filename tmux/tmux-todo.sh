#!/usr/bin/env bash
# Shared todo popup: ONE nvim instance on ONE file, attached from everywhere.
#
# A single detached session on a DEDICATED tmux server socket ("todo-popup")
# runs nvim on TODO_FILE. Every prefix+T popup - from any session/window -
# attaches to that same session, so the content (including unsaved changes)
# is identical everywhere. Closing the popup only detaches; nvim keeps
# running in the background.
#
# This script runs INSIDE the popup (it is the popup's command).
set -uo pipefail

SOCKET="todo-popup"
SESSION="todo"
TODO_FILE="$HOME/Personal/todos.md"

# Create the persistent session once (fails with "duplicate session" on later
# runs, which is fine). The nested server starts WITHOUT the user config
# (-f /dev/null) so no plugins/status bar are loaded inside the popup.
tmux -L "$SOCKET" -f /dev/null new-session -d -s "$SESSION" "nvim '$TODO_FILE'" 2>/dev/null || true

# Idempotent nested-server setup (applied on every open, so tweaks here take
# effect even for an already-running session).
tmux -L "$SOCKET" set-option -g status off            # popup is just a frame around nvim
tmux -L "$SOCKET" set-option -sg escape-time 0        # no Esc lag in nvim
tmux -L "$SOCKET" set-option -g prefix C-a            # match the main config's prefix
tmux -L "$SOCKET" set-option -g detach-on-destroy on
tmux -L "$SOCKET" bind-key d detach-client
tmux -L "$SOCKET" bind-key T detach-client            # prefix+T again closes the popup

# Attach. Detaching (prefix+d / prefix+T) exits this script, which closes the
# popup, leaving the session (and nvim) alive for next time.
exec tmux -L "$SOCKET" attach-session -t "=$SESSION"
