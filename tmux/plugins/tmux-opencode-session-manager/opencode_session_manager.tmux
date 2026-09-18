#!/usr/bin/env bash
# tmux-opencode-session-manager
#
# List, monitor status, and jump across opencode popup sessions from a single
# picker — plus persistent per-agent indicators in every tmux status line.
# Source this file from your tmux config:
#
#   run-shell ~/.config/tmux/plugins/tmux-opencode-session-manager/opencode_session_manager.tmux
#
# It reads user options (with sensible defaults) and installs the key bindings.
#
# Floating vertical indicator stacks are impractical in tmux: the only overlay
# primitives are popups and menus, which cover terminal content and vanish on
# dismissal. The persistent per-agent indicators therefore live as a compact
# right-aligned group in status-right (bottom-right, just left of the
# hostname) — the only native always-visible UI. One indicator per tracked
# agent: a state glyph plus a short directory label.

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

# --- Persistent status-line indicators ---------------------------------------
# Prepend the statusline segment to status-right, preserving the user's
# existing content and styling. The segment hides itself while the picker
# popup is open (picker.sh sets @opencode_picker_open for exactly that
# span): the picker already shows every agent's state, so the indicators
# would only duplicate it. Idempotent and self-healing across reloads: the
# previously installed segment (remembered verbatim, so glob metacharacters
# in styles can't misfire) is stripped by length before the current one is
# prepended, so re-sourcing never duplicates and upgrades apply.
_oc_seg="#{?@opencode_picker_open,,#[fg=default]#($CURRENT_DIR/scripts/statusline.sh)#[fg=default]} "
_oc_bare_old="#[fg=default]#($CURRENT_DIR/scripts/statusline.sh)#[fg=default] "
_current_right="$(tmux show-option -gqv status-right 2>/dev/null)"
_prev_seg="$(get_tmux_option @opencode_status_seg '')"
if [ -n "$_prev_seg" ] && [ "${_current_right:0:${#_prev_seg}}" = "$_prev_seg" ]; then
  _current_right="${_current_right:${#_prev_seg}}"
fi
if [ "${_current_right:0:${#_oc_bare_old}}" = "$_oc_bare_old" ]; then
  _current_right="${_current_right:${#_oc_bare_old}}"
fi
tmux set-option -g status-right "${_oc_seg}${_current_right}" 2>/dev/null
tmux set-option -g @opencode_status_seg "$_oc_seg" 2>/dev/null

# Room for up to @opencode_indicators_max indicators plus existing content.
# Only ever grows the allowance, never shrinks a larger user value.
_current_rlen="$(tmux show-option -gqv status-right-length 2>/dev/null)"
if [[ ! "$_current_rlen" =~ ^[0-9]+$ ]] || (( _current_rlen < 150 )); then
  tmux set-option -g status-right-length 150 2>/dev/null
fi

# The spinner animates on status-interval ticks. Lower a slow interval so
# working indicators visibly animate, but never raise a faster user value,
# and never go below 1s (statusline.sh is one cheap tmux call per tick).
_interval="$(tmux show-option -gqv status-interval 2>/dev/null)"
_want="$(get_tmux_option @opencode_status_interval '2')"
[[ "$_want" =~ ^[0-9]+$ ]] || _want=2
(( _want < 1 )) && _want=1
if [[ ! "$_interval" =~ ^[0-9]+$ ]] || (( _interval > _want )); then
  tmux set-option -g status-interval "$_want" 2>/dev/null
fi

# Background reconciler (API polling -> truthful stamps). Daemonizes once;
# the PID lockfile in reconcile.sh makes reloads no-ops, never duplicates.
tmux run-shell -b "$CURRENT_DIR/scripts/reconcile.sh daemon" 2>/dev/null
