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

cleanup() {
  if [[ -n "${SANDBOX_SERVER_PID:-}" ]]; then
    kill "$SANDBOX_SERVER_PID" 2>/dev/null || true
  fi
  rm -rf -- "$SANDBOX"
}
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
# (127.0.0.1:49374). Give the sandbox its own port AND its own config dir
# so that nothing the sandbox does can reach (or reconfigure) the host's
# service.
#
# NOTE: `opencode service set port` talks to the RUNNING service, which on
# a real desktop is the host's, so it must not be used here. The port is
# written straight into the sandbox's service.json instead.
FREEPORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])')
export OPENCODE_CONFIG_DIR="$XDG_CONFIG_HOME/opencode"
mkdir -p -- "$OPENCODE_CONFIG_DIR"
printf '{"port": %s}\n' "$FREEPORT" >"$OPENCODE_CONFIG_DIR/service.json"
# Never restart a service from inside the sandbox.
export OPENCODE_SKIP_SERVICE_RESTART=1
# The sandbox must not change the host's group memberships either.
# (install.sh now gates those behind --allow-groups, which is off here.)
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

# Hermetic Node toolchain. The sandbox must not depend on a Node install on
# the host (this repo manages Node through mise, which is deliberately not
# on the sandbox PATH). These stubs implement exactly the interfaces
# skills.sh uses: the `skills` CLI, the ui-ux-pro-max CLI and the
# @playwright/cli package. The real skill ecosystem is covered by
# opencode/tests/test_setup.py and by the live host bootstrap.
mkdir -p -- "$SANDBOX/nodebin"
export SANDBOX_DESIGN_SKILLS
SANDBOX_DESIGN_SKILLS=$(awk '$2 == "ui-ux-pro-max" { print $1 }' "$REPO_DIR/skills/manifest.txt" | tr '\n' ' ')
cat >"$SANDBOX/nodebin/npx" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
make_skill() {
  local root="$HOME/.agents/skills/$1"
  mkdir -p -- "$root"
  printf -- '---\nname: %s\ndescription: sandbox fixture\n---\nFixture\n' "$1" >"$root/SKILL.md"
}
case "$*" in
  *skills@latest*)
    names=()
    while [ $# -gt 0 ]; do
      if [ "$1" = "-s" ]; then
        shift
        while [ $# -gt 0 ] && [ "${1#-}" = "$1" ]; do names+=("$1"); shift; done
        continue
      fi
      shift
    done
    for n in ${names[@]+"${names[@]}"}; do [ -n "$n" ] && make_skill "$n"; done
    ;;
  *ui-ux-pro-max-cli*)
    for n in ${SANDBOX_DESIGN_SKILLS:-}; do make_skill "$n"; done
    ;;
  *)
    printf 'unexpected npx invocation: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
cat >"$SANDBOX/nodebin/npm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
prefix=""
args=("$@")
for i in "${!args[@]}"; do
  if [ "${args[$i]}" = "--prefix" ]; then prefix="${args[$((i + 1))]:-}"; fi
done
case "$*" in
  *"@playwright/cli"*)
    [ -n "$prefix" ] || { echo "npm stub: missing --prefix" >&2; exit 2; }
    mkdir -p "$prefix/bin"
    cat >"$prefix/bin/playwright-cli" <<'JS'
#!/usr/bin/env node
console.log('  snapshot  capture page');
console.log('  goto <url>  navigate');
JS
    chmod +x "$prefix/bin/playwright-cli"
    ;;
  *)
    printf 'unexpected npm invocation: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
cat >"$SANDBOX/nodebin/node" <<'SH'
#!/usr/bin/env bash
# Stub node: only the fake playwright CLI helper is ever executed here.
for arg in "$@"; do
  if [ -f "$arg" ] && grep -q 'snapshot' "$arg" 2>/dev/null; then
    printf '  snapshot  capture page\n  goto <url>  navigate\n'
    exit 0
  fi
done
exit 0
SH
chmod +x "$SANDBOX/nodebin/npx" "$SANDBOX/nodebin/npm" "$SANDBOX/nodebin/node"
export PATH="$SANDBOX/nodebin:$PATH"

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
cat "$XDG_CONFIG_HOME/noctalia/zz-mydotfiles.toml"

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
# The plugin check needs a running opencode server that uses the SANDBOX
# config (the repo's opencode.json, linked above). Start a private one on
# the sandbox port so the host's service is never contacted, and stop it
# again when the sandbox goes away.
if [[ -x "$HOME/.opencode/bin/opencode" ]]; then
  "$HOME/.opencode/bin/opencode" serve --port "$FREEPORT" --hostname 127.0.0.1 \
    >"$SANDBOX/opencode-serve.log" 2>&1 &
  SANDBOX_SERVER_PID=$!
  printf '[sandbox] sandbox opencode server pid=%s port=%s\n' \
    "$SANDBOX_SERVER_PID" "$FREEPORT"
  for _ in $(seq 1 60); do
    # The probe runs in a subshell, so the socket is closed again when it
    # exits. (Never `exec 3<&- 2>/dev/null` here: `exec` would apply the
    # stderr redirect to the whole script and swallow the check output.)
    if (exec 3<>"/dev/tcp/127.0.0.1/$FREEPORT") 2>/dev/null; then
      break
    fi
    sleep 1
  done
fi
if ! (cd "$REPO_DIR" && ./cachyos/tests/test-bootstrap.sh --verify-only); then
  printf '[sandbox] verification FAILED; last 40 lines of the sandbox server log:\n'
  tail -40 "$SANDBOX/opencode-serve.log" 2>/dev/null || true
  exit 1
fi
printf '[sandbox] ALL GREEN\n'
