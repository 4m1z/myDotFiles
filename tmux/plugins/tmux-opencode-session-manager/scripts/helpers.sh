#!/usr/bin/env bash
# Shared helpers for tmux-opencode-session-manager.
#
# This manager works against a DEDICATED tmux server socket (default
# "opencode-popup") so opencode popup sessions stay isolated from your main
# tmux server, exactly like the standalone launch script. All session/option
# lookups for opencode sessions therefore go through `tmux -L "$OC_SOCKET"`.

# get_tmux_option <option-name> <default>
# Reads a GLOBAL option from the MAIN tmux server (your normal config), used
# only for user-facing settings like keybinds and popup size.
get_tmux_option() {
  local value
  value="$(tmux show-option -gqv "$1" 2>/dev/null)"
  if [ -n "$value" ]; then
    printf '%s' "$value"
  else
    printf '%s' "$2"
  fi
}

# The dedicated socket name for opencode popup sessions. Keep in sync with the
# launcher. Overridable via @opencode_socket on the main server.
oc_socket() {
  get_tmux_option @opencode_socket 'opencode-popup'
}

# octmux <args...>
# Run a tmux command against the opencode popup server socket.
octmux() {
  tmux -L "$(oc_socket)" "$@"
}

# session_hash <string>
# Stable session name suffix from a directory path. Uses cksum to match the
# existing standalone launcher (oc_<cksum>), so this manager and that script
# share the same sessions.
session_hash() {
  printf '%s' "$1" | cksum | cut -d' ' -f1
}
