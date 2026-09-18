#!/usr/bin/env bash
# Acknowledge an agent: the user has returned to it.
#
#   ack.sh <tmux-session-name>
#
# Called by launch.sh (prefix+y opens the agent) and picker.sh (jump to an
# agent). Semantics:
#   - ALWAYS stamps @opencode_acked_at=now (proof of visit).
#   - done -> idle ("seen"): completion is acknowledged by returning.
#   - waiting / error are NEVER cleared here: an unresolved input request or
#     failure must keep its attention indicator until the task resumes
#     (fresh `working` stamp) or is explicitly resolved.
#   - working / idle only record the visit timestamp.
#
# Tombstones for this session are removed: the agent is live again.
set -uo pipefail
DIR_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
. "$DIR_SELF/helpers.sh"
# shellcheck source=api.sh
. "$DIR_SELF/api.sh"

session="${1:-}"
[ -n "$session" ] || exit 0
octmux has-session -t "=$session" 2>/dev/null || exit 0

now="$(date +%s)"
state="$(octmux show-options -qv -t "$session" @opencode_state 2>/dev/null)"
octmux set-option -t "$session" @opencode_acked_at "$now" 2>/dev/null
if [ "$state" = 'done' ]; then
  octmux set-option -t "$session" @opencode_state 'idle' 2>/dev/null
  octmux set-option -t "$session" @opencode_state_at "$now" 2>/dev/null
  octmux set-option -t "$session" @opencode_detail 'seen' 2>/dev/null
fi
# Live again: any tombstone for this session is stale.
rm -f "$_oc_tomb_dir/$session.tomb" 2>/dev/null
exit 0
