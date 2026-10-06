#!/usr/bin/env bash
# Sandbox clean-room test for non-CachyOS dev machines and CI without Docker.
# Builds a fake HOME, seeds a minimal official-style Hyprland config
# (binds.lua wallpaper line + hyprland.lua), runs the bootstrap TWICE
# (idempotency), then runs --verify-only inside the sandbox.
#
# Usage: ./cachyos/tests/sandbox-test.sh
#
# Nothing outside $SANDBOX and the repo is touched. The pacman phase is
# skipped (--no-packages): package installation is covered by the Docker
# test on real CachyOS.
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/mydotfiles-sandbox-XXXXXX")

cleanup() { rm -rf -- "$SANDBOX"; }
trap cleanup EXIT

export HOME="$SANDBOX/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_DATA_HOME="$HOME/.local/share"
export MYDOTFILES_FORCE_CACHYOS=1
export MYDOTFILES_TEST_MODE=1
mkdir -p -- "$HOME"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Minimal official-style Hyprland tree: the exact wallpaper binding line
# from cachyos-hypr-noctalia binds.lua plus a hyprland.lua entry point.
mkdir -p -- "$XDG_CONFIG_HOME/hypr/config"
cat >"$XDG_CONFIG_HOME/hypr/config/binds.lua" <<'LUA'
local mainMod = "SUPER"
local noctCall = "noctalia msg "
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(noctCall .. "panel-toggle wallpaper"))
LUA
cat >"$XDG_CONFIG_HOME/hypr/hyprland.lua" <<'LUA'
require("config.binds")
LUA

# Keep the sandbox PATH isolated from the host user's ~/.local/bin,
# ~/.cargo/bin, ~/.opencode/bin, mise shims, etc. Only the ordinary system
# binaries plus the sandbox HOME bins will resolve below.

# The host may already run an opencode service on the default port
# (127.0.0.1:49374). Pre-install the sandbox binary and pin it to a free
# port so `opencode plugin update` inside the bootstrap never collides.
FREEPORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])')
curl --retry 5 --retry-all-errors --retry-delay 2 -fsSL \
  https://opencode.ai/v2/install | bash -s -- --no-modify-path
"$HOME/.opencode/bin/opencode" service set port "$FREEPORT" \
  || printf '[sandbox] warning: could not pin opencode service port\n'
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

printf '[sandbox] HOME=%s\n' "$HOME"
printf '[sandbox] bootstrap run #1...\n'
(cd "$REPO_DIR" && ./cachyos/install.sh --no-packages --no-verify)
printf '[sandbox] bootstrap run #2 (idempotency)...\n'
(cd "$REPO_DIR" && ./cachyos/install.sh --no-packages --no-verify)

printf '[sandbox] binds.lua after patch:\n'
cat "$XDG_CONFIG_HOME/hypr/config/binds.lua"
printf '[sandbox] hyprland.lua after hook:\n'
cat "$XDG_CONFIG_HOME/hypr/hyprland.lua"
printf '[sandbox] noctalia hand layer:\n'
cat "$XDG_CONFIG_HOME/noctalia/50-mydotfiles.toml"

# Exercise the manual theme helper against a deterministic Noctalia IPC stub
# (the real shell is not installed in this non-GUI sandbox).
mkdir -p -- "$SANDBOX/stubbin"
cat >"$SANDBOX/stubbin/noctalia" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
state=${SANDBOX_NOCTALIA_MODE:?}
case "${2:-}" in
  theme-mode-set) printf '%s\n' "${3:?}" >"$state" ;;
  theme-mode-toggle)
    if [[ -f "$state" && $(<"$state") == dark ]]; then
      printf 'light\n' >"$state"
    else
      printf 'dark\n' >"$state"
    fi
    ;;
  theme-mode-get) [[ -f "$state" ]] && cat "$state" || printf 'light\n' ;;
  *) printf 'unexpected Noctalia IPC: %s\n' "$*" >&2; exit 2 ;;
esac
SH
chmod +x "$SANDBOX/stubbin/noctalia"
export SANDBOX_NOCTALIA_MODE="$SANDBOX/noctalia.mode"
export PATH="$SANDBOX/stubbin:$PATH"
"$HOME/.local/bin/mydotfiles-theme-toggle" dark
grep -Fxq 'mode=dark' "$XDG_STATE_HOME/mydotfiles/theme"
"$HOME/.local/bin/mydotfiles-theme-toggle" toggle
grep -Fxq 'mode=light' "$XDG_STATE_HOME/mydotfiles/theme"
NOCTALIA_THEME_MODE=dark "$HOME/.local/bin/mydotfiles-sync-theme-mode"
grep -Fxq 'mode=dark' "$XDG_STATE_HOME/mydotfiles/theme"
printf '[sandbox] PASS: theme helper persists manual dark/light mode\n'
# The integration stub exists only for the helper test; do not let the
# general bootstrap verifier mistake it for a real Noctalia installation.
export PATH="${PATH#"$SANDBOX/stubbin:"}"

printf '[sandbox] verification...\n'
(cd "$REPO_DIR" && ./cachyos/tests/test-bootstrap.sh --verify-only)
printf '[sandbox] ALL GREEN\n'
