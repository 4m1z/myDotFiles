#!/usr/bin/env bash
# tmux-opencode-session-manager
#
# List, monitor status, and jump across opencode popup sessions from a single
# picker. Source this file from your tmux config:
#
#   run-shell ~/.config/tmux/plugins/tmux-opencode-session-manager/opencode_session_manager.tmux
#
# It reads user options (with sensible defaults) and installs the key bindings.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/helpers.sh
. "$CURRENT_DIR/scripts/helpers.sh"

launch_key="$(get_tmux_option @opencode_launch_key 'y')"
list_key="$(get_tmux_option @opencode_list_key 'u')"

# Launch / re-attach an opencode session for the current pane's directory.
# #{pane_pid} resolves the real cwd (incl. nvim); #{window_id} is recorded as
# the origin so the picker can jump back here.
tmux bind-key "$launch_key" \
  run-shell "$CURRENT_DIR/scripts/launch.sh '#{pane_pid}' '#{window_id}'"

# Open the session picker. From inside an opencode popup, list.sh closes it
# first so the picker opens full-size on the outer client.
tmux bind-key "$list_key" \
  run-shell "$CURRENT_DIR/scripts/list.sh"
