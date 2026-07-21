#!/usr/bin/env bash
# Launch (or re-attach to) an opencode session for a directory, in a popup.
# Backed by a persistent detached session on a DEDICATED tmux server socket,
# so state survives closing the popup, scoped per directory.
#
# Args (expanded by run-shell in the binding):
#   $1  pane PID        (#{pane_pid})   - used to resolve the real cwd
#   $2  origin window   (#{window_id})  - recorded so the picker can jump back
set -uo pipefail
DIR_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
. "$DIR_SELF/helpers.sh"

PANE_PID="${1:-}"
ORIGIN_WINDOW="${2:-}"

prefix="$(get_tmux_option @opencode_session_prefix 'oc_')"
cmd="$(get_tmux_option @opencode_command 'opencode')"
w="$(get_tmux_option @opencode_popup_width '90%')"
h="$(get_tmux_option @opencode_popup_height '90%')"

# Resolve the directory to scope opencode to. Prefer the cwd of an nvim process
# under the pane's shell; fall back to the pane PID's own cwd. (Mirrors the
# standalone launcher so both share sessions.)
resolve_dir() {
  local root_pid="$1"
  local pids=("$root_pid")
  local found="" i=0
  while ((i < ${#pids[@]})); do
    local pid="${pids[$i]}"
    i=$((i + 1))
    local comm
    comm="$(cat "/proc/$pid/comm" 2>/dev/null || true)"
    if [[ "$comm" == "nvim" || "$comm" == "neovim" ]]; then
      local d
      d="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
      if [[ -n "$d" ]]; then found="$d"; break; fi
    fi
    local children
    children="$(pgrep -P "$pid" 2>/dev/null || true)"
    for c in $children; do pids+=("$c"); done
  done
  if [[ -n "$found" ]]; then printf '%s' "$found"; return; fi
  readlink "/proc/$root_pid/cwd" 2>/dev/null || printf '%s' "$HOME"
}

if [[ -n "$PANE_PID" && -d "/proc/$PANE_PID" ]]; then
  path="$(resolve_dir "$PANE_PID")"
else
  path="$PWD"
fi

session="${prefix}$(session_hash "$path")"

# Don't open a popup-in-popup: bail if we're already inside an opencode session.
# NOTE: this must query the CURRENT server (plain tmux), not the dedicated
# opencode-popup server (octmux). The popup sessions persist on the dedicated
# server by design, so using octmux here always matches and falsely reports
# "already open" even from your normal session.
if tmux display-message -p '#S' 2>/dev/null | grep -q "^${prefix}"; then
  tmux display-message 'opencode popup already open'
  exit 0
fi

# Create the detached opencode session on the dedicated server if absent, and
# configure the nested server to behave like "just opencode in a frame".
if ! octmux has-session -t "=${session}" 2>/dev/null; then
  octmux new-session -d -s "$session" -c "$path" "$cmd"

  octmux set-option -g status off
  octmux set-option -g prefix C-a
  octmux set-option -g detach-on-destroy on

  # Prefixed window/session nav keys detach the popup so the keystroke falls
  # through to your main session on the next press.
  for k in 0 1 2 3 4 5 6 7 8 9 n p w c '&'; do
    octmux bind-key "$k" detach-client
  done
  octmux bind-key d detach-client

  # From inside the y-popup, prefix+u jumps straight to the session picker.
  # Bind it explicitly on the nested server (don't rely on inheriting the main
  # config) so switching y -> u works without first closing the popup.
  list_key="$(get_tmux_option @opencode_list_key 'u')"
  octmux bind-key "$list_key" run-shell "$DIR_SELF/list.sh"
fi

# Record the directory and origin window so the picker can show the path and
# jump back to the launching window on the MAIN server.
octmux set-option -t "$session" @opencode_dir "$path"
[ -n "$ORIGIN_WINDOW" ] && octmux set-option -t "$session" @opencode_origin "$ORIGIN_WINDOW"

# Attach inside the popup. Detaching leaves the session alive on the dedicated
# server, preserving opencode state per directory.
tmux display-popup -w "$w" -h "$h" -E "tmux -L $(oc_socket) attach-session -t '=${session}'"
