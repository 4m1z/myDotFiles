#!/usr/bin/env bash
# Record an opencode session's state on its tmux session, for the picker.
# Called by the opencode status plugin:  state.sh <working|waiting|idle>
#
# opencode runs inside a popup on the dedicated socket, so $TMUX / $TMUX_PANE
# point at that server. We resolve the socket from $TMUX and stamp the session
# that owns $TMUX_PANE. Outside tmux this is a no-op.
[ -z "${TMUX_PANE:-}" ] && exit 0
[ -z "${TMUX:-}" ] && exit 0

# $TMUX is "<socket-path>,<pid>,<session-id>"; pass the socket path explicitly so
# we talk to the right server regardless of which socket it is.
socket_path="${TMUX%%,*}"

session=$(tmux -S "$socket_path" display-message -p -t "$TMUX_PANE" '#{session_name}' 2>/dev/null) || exit 0
[ -z "$session" ] && exit 0

tmux -S "$socket_path" set-option -t "$session" @opencode_state "${1:-idle}"
tmux -S "$socket_path" set-option -t "$session" @opencode_state_at "$(date +%s)"
exit 0
