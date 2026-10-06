#!/usr/bin/env bash
# Verification suite for the CachyOS bootstrap.
#   ./cachyos/tests/test-bootstrap.sh --verify-only   run checks on this machine
#   ./cachyos/tests/test-bootstrap.sh --docker        full clean-room test:
#       build cachyos/cachyos image, run install.sh TWICE as a non-root
#       user (idempotency), then run the checks inside the container.
#
# Needs no API credentials. Desktop-compositor behavior (Hyprland/Noctalia
# rendering, dock visuals, portals, hardware) CANNOT be validated here;
# see cachyos/framework/CHECKLIST.md and docs/limitations.
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
MODE=${1:---verify-only}
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$*"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$*" >&2; }

check() { # check <description> <command...>
  local desc=$1
  shift
  if "$@" >/dev/null 2>&1; then
    pass "$desc"
  else
    fail "$desc"
  fi
}

check_output() { # check_output <description> <expected> <command...>
  local desc=$1 expected=$2
  shift 2
  local out
  if out=$("$@" 2>/dev/null) && [[ "$out" == *"$expected"* ]]; then
    pass "$desc"
  else
    fail "$desc (expected '$expected', got '${out:-<empty>}')"
  fi
}

verify_machine() {
  # --- expected binaries
  for bin in git zsh tmux nvim mise opencode gh rg fzf jq; do
    check "binary: $bin" command -v "$bin"
  done

  # --- symlinks resolve and point into the repo (XDG homes honored)
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  for target in "$HOME/.zshrc" "$HOME/.zsh_profile" \
    "$config_home/nvim" \
    "$config_home/tmux/tmux.conf" \
    "$config_home/tmux/plugins/tmux-opencode-session-manager" \
    "$config_home/alacritty/alacritty.toml" \
    "$HOME/.local/bin/mydotfiles-speedy" \
    "$HOME/.local/bin/mydotfiles-notes" \
    "$HOME/.local/bin/mydotfiles-theme-toggle" \
    "$HOME/.local/bin/mydotfiles-sync-theme-mode"; do
    if [[ -L "$target" || -e "$target" ]] && [[ "$(readlink -f -- "$target")" == "$REPO_DIR"* ]]; then
      pass "linked into repo: $target"
    else
      fail "linked into repo: $target"
    fi
  done

  # --- no broken symlinks in the managed trees
  local broken=0
  for root in "$config_home/nvim" "$config_home/tmux" "$config_home/alacritty" \
    "$config_home/opencode"; do
    [[ -e "$root" || -L "$root" ]] || continue
    while IFS= read -r link; do
      if [[ ! -e "$link" ]]; then
        fail "broken symlink: $link"
        broken=1
      fi
    done < <(find -L "$root" -xtype l 2>/dev/null)
  done
  [[ "$broken" -eq 0 ]] && pass "no broken symlinks"

  # --- shell starts non-interactively
  check "zsh startup" zsh -ic 'echo shell-ok'

  # --- tmux config parses
  check "tmux config" tmux -L mydotfiles-test -f "$config_home/tmux/tmux.conf" start-server ';' kill-server
  check "tmux/OpenCode session manager tests" bash \
    "$config_home/tmux/plugins/tmux-opencode-session-manager/scripts/tests.sh"

  # --- neovim starts headless (no desktop theme state required)
  check "nvim headless" nvim --headless '+qa'
  check "packer installed" test -d "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/packer/start/packer.nvim"
  check "nvim system_theme loads" nvim --headless \
    +'lua ok,_ = pcall(require, "system_theme"); assert(ok, "system_theme failed to load")' +qa
  check "nvim colorscheme applies" nvim --headless \
    +'lua assert(vim.g.active_colorscheme, "no colorscheme applied")' +qa

  # --- opencode v2 + plugins (no auth needed for these read-only commands)
  check_output "opencode v2" "opencode v2." bash -c 'cd "$HOME" && opencode --version'
  check "opencode plugin list" bash -c 'cd "$HOME" && opencode plugin list'
  check "OpenCode graph-live configured" python3 -c \
    'import json; p=json.load(open("'"$REPO_DIR"'/opencode/opencode.json"))["plugin"]; assert "opencode-graph-live@latest" in p'
  check "OpenCode tmux-status configured" python3 -c \
    'import json; p=json.load(open("'"$REPO_DIR"'/opencode/opencode.json"))["plugin"]; assert "opencode-tmux-session-status@latest" in p'

  # --- mise works
  check "mise" mise --version

  # --- speedy installed (binary present; recorder may not run headless)
  check "speedy binary" command -v speedy

  # --- helpers are executable scripts
  for helper in mydotfiles-speedy mydotfiles-notes mydotfiles-theme-toggle mydotfiles-sync-theme-mode; do
    check "helper executable: $helper" test -x "$HOME/.local/bin/$helper"
  done
  check "notes helper usage-free probe" bash -n "$HOME/.local/bin/mydotfiles-notes"

  # --- CachyOS-only file checks (run when present, never fail elsewhere)
  if [[ -f "$config_home/noctalia/50-mydotfiles.toml" ]]; then
    check "noctalia: dock disabled" grep -q 'enabled = false' "$config_home/noctalia/50-mydotfiles.toml"
    if grep -Eq 'waybar|swaync|quickshell|cairo-dock|nwg-dock|latte-dock|\brofi\b|\bwofi\b|\bmako\b|\bags\b|\bplank\b' \
      "$config_home/noctalia/50-mydotfiles.toml"; then
      fail "noctalia config references a foreign shell stack"
    else
      pass "noctalia config has no foreign shell stack"
    fi
    if command -v noctalia >/dev/null 2>&1; then
      check "noctalia config validates" noctalia config validate
    fi
  fi
  if [[ -f "$config_home/hypr/config/personal.lua" ]]; then
    if grep -Eq 'o\.bind|o\.window|omarchy-launch|omarchy' "$config_home/hypr/config/personal.lua"; then
      fail "personal.lua still references Omarchy helpers"
    else
      pass "personal.lua has no Omarchy references"
    fi
  fi
}

docker_test() {
  command -v docker >/dev/null 2>&1 || { fail "docker not available"; exit 1; }
  local tag="mydotfiles-cachyos-test"
  log() { printf '[docker-test] %s\n' "$*"; }
  log "Building $tag from cachyos/cachyos..."
  docker build -t "$tag" -f "$REPO_DIR/cachyos/tests/Dockerfile" "$REPO_DIR"
  for run in 1 2; do
    log "Bootstrap run #$run (idempotency check)..."
    docker run --rm -v "$REPO_DIR:/home/tester/myDotFiles:ro" "$tag" \
      bash -lc 'cd ~/myDotFiles && ./cachyos/install.sh --no-verify'
  done
  log "Running verification inside a fresh container..."
  docker run --rm -v "$REPO_DIR:/home/tester/myDotFiles:ro" "$tag" \
    bash -lc 'cd ~/myDotFiles && ./cachyos/tests/test-bootstrap.sh --verify-only'
}

case "$MODE" in
  --verify-only) verify_machine ;;
  --docker) docker_test ;;
  *)
    printf 'Usage: %s [--verify-only|--docker]\n' "$0" >&2
    exit 1
    ;;
esac

printf 'Result: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
