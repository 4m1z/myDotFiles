#!/usr/bin/env bash
# Interactive picker for running opencode sessions (on the dedicated socket).
#
#   picker.sh           fzf picker; on enter, switches the parent client to the
#                       chosen session's origin window and resumes it in a popup.
#   picker.sh --list    print the rows only (used by fzf's ctrl-x reload).
set -uo pipefail
DIR_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
. "$DIR_SELF/helpers.sh"

prefix="$(get_tmux_option @opencode_session_prefix 'oc_')"
socket="$(oc_socket)"

emit_rows() {
  local now s state at path icon rank ago
  now=$(date +%s)
  octmux list-sessions -F '#{session_name}' 2>/dev/null | grep "^${prefix}" | while IFS= read -r s; do
    state=$(octmux show-options -qv -t "$s" @opencode_state 2>/dev/null)
    at=$(octmux show-options -qv -t "$s" @opencode_state_at 2>/dev/null)
    path=$(octmux show-options -qv -t "$s" @opencode_dir 2>/dev/null)
    [ -z "$path" ] && path=$(octmux display-message -p -t "$s" '#{pane_current_path}' 2>/dev/null)
    case "$state" in
    waiting) icon=$'\033[33m\u25cf\033[0m waiting' rank=0 ;; # yellow - needs input
    idle)    icon=$'\033[32m\u25cf\033[0m idle   ' rank=1 ;; # green  - done, your turn
    working) icon=$'\033[31m\u25cf\033[0m working' rank=3 ;; # red    - busy, leave it
    *)       icon=$'\033[90m\u25cf\033[0m   ?    ' rank=2 ;; # grey   - unknown
    esac
    if [ -n "$at" ]; then ago="$(((now - at) / 60))m"; else ago='-'; fi
    # rank \t session \t icon \t age \t path   (rank/session hidden via --with-nth)
    printf '%s\t%s\t%s\t%5s\t%s\n' "$rank" "$s" "$icon" "$ago" "${path#"$HOME"/}"
  done | sort -t$'\t' -k1,1n -k4,4n
}

[ "${1:-}" = '--list' ] && { emit_rows; exit 0; }

if ! command -v fzf >/dev/null 2>&1; then
  tmux display-message "tmux-opencode-session-manager: fzf is required for the picker"
  exit 0
fi

self="${BASH_SOURCE[0]}"
export FZF_DEFAULT_OPTS=''

# The opencode TUI renders a right-hand sidebar (Context/MCP/LSP) at absolute
# columns near the pane's full width (~161 cols). A raw capture jammed into the
# narrow preview window overlaps that sidebar onto the chat text. To keep the
# preview readable we capture with wrapped lines joined (-J) and then trim each
# line to the left chat column, preserving ANSI colour codes.
[ "${1:-}" = '--preview' ] && {
  tmux -L "$socket" capture-pane -epJt "$2" 2>/dev/null |
    perl -pe '
      my $limit = 112; my $vis = 0; my $out = ""; my $i = 0;
      while ($i < length) {
        my $c = substr($_, $i, 1);
        if ($c eq "\033") {                       # copy full ANSI escape
          my $j = $i + 1;
          $j++ while $j < length && substr($_, $j, 1) !~ /[A-Za-z]/;
          $out .= substr($_, $i, $j - $i + 1); $i = $j + 1; next;
        }
        last if $vis >= $limit;                    # stop at column limit
        $out .= $c; $vis++; $i++;
      }
      $_ = $out . "\033[0m\n";
    '
  exit 0
}

sel=$(emit_rows | fzf --ansi --delimiter='\t' --with-nth=3,4,5 \
  --reverse --cycle --header='opencode sessions · enter: jump · ctrl-x: kill' \
  --preview="$self --preview {2}" --preview-window='right,62%,nowrap' \
  --bind="ctrl-x:execute-silent(tmux -L $socket kill-session -t {2})+reload($self --list)")

[ -z "$sel" ] && exit 0
target=$(printf '%s' "$sel" | cut -f2)

# Move the underlying parent (main-server) client to the session's origin window
# (best-effort), then resume the session in a popup over it.
origin=$(octmux show-options -qv -t "$target" @opencode_origin 2>/dev/null)
parent=$(tmux show-options -gqv @opencode_parent 2>/dev/null)
[ -n "$origin" ] && [ -n "$parent" ] &&
  tmux switch-client -c "$parent" -t "$origin" 2>/dev/null

w="$(get_tmux_option @opencode_popup_width '90%')"
h="$(get_tmux_option @opencode_popup_height '90%')"

# We're running INSIDE the picker's own display-popup. Opening another
# display-popup synchronously here races with this popup closing, so tmux
# silently drops it (the client jumps to the origin window but no popup shows).
# Instead, defer: schedule a detached run-shell that waits for this picker popup
# to disappear, then opens the opencode popup cleanly on the parent client.
attach_cmd="tmux -L $socket attach-session -t '=${target}'"
if [ -n "$parent" ]; then
  popup_cmd="tmux display-popup -c '$parent' -w '$w' -h '$h' -E \"$attach_cmd\""
  wait_cmd="tmux display-message -p -t '$parent' '#{client_flags}' 2>/dev/null | grep -q popup"
else
  popup_cmd="tmux display-popup -w '$w' -h '$h' -E \"$attach_cmd\""
  wait_cmd="false"
fi

tmux run-shell -b "
  for _ in \$(seq 1 100); do
    $wait_cmd || break
    sleep 0.02
  done
  $popup_cmd
"
