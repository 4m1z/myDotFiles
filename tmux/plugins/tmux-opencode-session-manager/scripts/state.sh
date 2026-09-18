#!/usr/bin/env bash
# Record an opencode session's state on its tmux session, for the picker and
# the status-line indicators.
#   state.sh <working|waiting|done|error|idle> [detail]
#
# NOTE (opencode v2): plugins run in the background service, outside tmux, so
# the V2 plugin (opencode/plugins/tmux-status.ts) stamps state directly by
# directory hash and no longer calls this. This script stays for manual use
# and backwards compatibility: it stamps the session owning $TMUX_PANE.
set -uo pipefail
[ -z "${TMUX_PANE:-}" ] && exit 0
[ -z "${TMUX:-}" ] && exit 0

case "${1:-idle}" in
  working|waiting|done|error|idle) state="$1" ;;
  *) echo "state.sh: unknown state '${1:-}' (want working|waiting|done|error|idle)" >&2; exit 2 ;;
esac

# $TMUX is "<socket-path>,<pid>,<session-id>"; pass the socket path explicitly so
# we talk to the right server regardless of which socket it is.
socket_path="${TMUX%%,*}"

session=$(tmux -S "$socket_path" display-message -p -t "$TMUX_PANE" '#{session_name}' 2>/dev/null) || exit 0
[ -z "$session" ] && exit 0

tmux -S "$socket_path" set-option -t "$session" @opencode_state "$state"
tmux -S "$socket_path" set-option -t "$session" @opencode_state_at "$(date +%s)"
if [ -n "${2:-}" ]; then
  tmux -S "$socket_path" set-option -t "$session" @opencode_detail "$2"
fi
exit 0
