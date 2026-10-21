#!/usr/bin/env bash
# Persistent OpenClaw popup, shared across outer tmux sessions.
set -euo pipefail

SOCKET="openclaw-popup"
SESSION="openclaw"

# `openclaw tui` talks to a Gateway and needs an auth token. Until one is
# configured (openclaw onboard --install-daemon), run the local embedded
# agent runtime instead, which needs no credentials.
gateway_credential() {
  [[ -n "${OPENCLAW_GATEWAY_TOKEN:-}" || -n "${OPENCLAW_GATEWAY_PASSWORD:-}" ]] && return 0
  local conf="${OPENCLAW_CONFIG:-$HOME/.openclaw}/openclaw.json"
  [[ -f "$conf" ]] || return 1
  grep -qE '"(token|password)"[[:space:]]*:[[:space:]]*"[^"]+"' "$conf"
}

tui_args=(--session main)
if gateway_credential; then
  tui_args=(--session agent:main:main)
else
  tui_args+=(--local)
fi

# Clear the outer tmux environment when creating/attaching the nested server.
unset TMUX
if ! tmux -L "$SOCKET" has-session -t "=$SESSION" 2>/dev/null; then
  if ! tmux -L "$SOCKET" -f /dev/null new-session -d -s "$SESSION" \
    "openclaw tui ${tui_args[*]}"; then
    printf 'Could not start the OpenClaw session.\n'
    exit 1
  fi
  # Give the TUI a moment to fail loudly (bad credentials, missing runtime).
  sleep 1
  if ! tmux -L "$SOCKET" has-session -t "=$SESSION" 2>/dev/null; then
    printf 'OpenClaw exited immediately. Try: openclaw tui %s\n' "${tui_args[*]}"
    printf 'Press Enter to close.\n'
    read -r _
    exit 1
  fi
fi

tmux -L "$SOCKET" set-option -g status off
tmux -L "$SOCKET" set-option -sg escape-time 0
tmux -L "$SOCKET" set-option -g prefix C-a
tmux -L "$SOCKET" set-option -g detach-on-destroy on
tmux -L "$SOCKET" bind-key d detach-client
tmux -L "$SOCKET" bind-key b detach-client

exec tmux -L "$SOCKET" attach-session -t "=$SESSION"
