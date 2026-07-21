#!/usr/bin/env bash
# Open the opencode session picker in a popup.
#
# Pressed from a normal pane: opens the picker over the current client.
# Pressed from inside an opencode popup: closes that popup first, then opens the
# picker full-size on the outer (main-server) client, avoiding popup-in-popup.
set -uo pipefail
DIR_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
. "$DIR_SELF/helpers.sh"

w="$(get_tmux_option @opencode_popup_width '90%')"
h="$(get_tmux_option @opencode_popup_height '90%')"

# Name of the currently attached client on the dedicated opencode socket, if any.
# Non-empty means we're being invoked from inside a y-popup.
ncli="$(octmux list-clients -F '#{client_name}' 2>/dev/null | head -n1)"

# Remember the main-server client that should host the picker, so picker.sh can
# switch it to a chosen session's origin window before resuming.
host="$(tmux display-message -p '#{client_name}' 2>/dev/null)"
# When invoked from inside the y-popup, the "current" main-server client may not
# resolve; fall back to the sole attached main-server client.
if [ -z "$host" ]; then
  host="$(tmux list-clients -F '#{client_name}' 2>/dev/null | head -n1)"
fi
tmux set-option -g @opencode_parent "$host"

# Build the picker popup command for the resolved host.
if [ -n "$host" ]; then
  open_cmd="tmux display-popup -c '$host' -w '$w' -h '$h' -E '$DIR_SELF/picker.sh'"
else
  open_cmd="tmux display-popup -w '$w' -h '$h' -E '$DIR_SELF/picker.sh'"
fi

# If an opencode popup is currently attached on the dedicated socket, we're
# switching FROM the y-popup TO the picker. Detaching that popup and opening the
# picker inline races (popup closing while a new popup opens), so tmux drops the
# picker. Instead: detach, then defer the picker via a backgrounded run-shell
# that waits for the nested client to fully leave before opening. This makes
# u <-> y switching seamless without manually closing the popup first.
if [ -n "$ncli" ]; then
  octmux detach-client -t "$ncli" 2>/dev/null
  tmux run-shell -b "
    for _ in \$(seq 1 100); do
      [ -z \"\$(tmux -L '$(oc_socket)' list-clients -F '#{client_name}' 2>/dev/null | head -n1)\" ] && break
      sleep 0.02
    done
    $open_cmd
  "
  exit 0
fi

# Normal path: not inside an opencode popup, open the picker directly.
eval "$open_cmd"
