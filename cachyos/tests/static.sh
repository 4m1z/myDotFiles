#!/usr/bin/env bash
# Static validation: shell syntax, Lua syntax, and Omarchy-coupling audit.
# Fast, no network, no credentials. Run before pushing.
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$REPO_DIR"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$*"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$*" >&2; }

# --- bash syntax for every shell script
while IFS= read -r f; do
  if bash -n "$f"; then
    pass "bash -n: $f"
  else
    fail "bash -n: $f"
  fi
done < <(find cachyos opencode tmux zsh mise -name '*.sh' -o -name 'install.sh' \
  -o -name 'test-bootstrap.sh' -o -name 'static.sh' \
  -o -name 'tmux-sessionizer' -o -name 'tmux-todo.sh' -o -name 'mydotfiles-*' | sort -u)

# --- shellcheck when available (optional locally, informational)
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S warning cachyos/install.sh cachyos/packages.sh cachyos/lib/common.sh \
    cachyos/bin/* cachyos/tests/test-bootstrap.sh cachyos/tests/static.sh \
    opencode/install.sh; then
    pass "shellcheck"
  else
    fail "shellcheck"
  fi
else
  printf 'SKIP: shellcheck not installed\n'
fi

# --- Lua syntax (parse only, never execute: personal.lua needs Hyprland's
# --- `hl` global, so execution is expected to fail outside Hyprland)
check_lua() {
  local f=$1
  if command -v luac >/dev/null 2>&1; then
    luac -p "$f"
  elif command -v luajit >/dev/null 2>&1; then
    luajit -bl "$f" >/dev/null
  else
    local out
    out=$(nvim --headless --noplugin -c "lua assert(loadfile('$f')); print('PARSE-OK')" -c 'qa!' 2>&1)
    [[ "$out" == *"PARSE-OK"* ]]
  fi
}
while IFS= read -r f; do
  if check_lua "$f"; then
    pass "lua syntax: $f"
  else
    fail "lua syntax: $f"
  fi
done < <(find cachyos/hypr nvim/lua -name '*.lua' | sort)

# --- TOML sanity (python stdlib)
if python3 -c "import tomllib" 2>/dev/null; then
  if python3 - <<'PY'; then
import tomllib
for p in ["cachyos/noctalia/50-mydotfiles.toml", "alacritty/alacritty.toml", "mise/config.toml"]:
    with open(p, "rb") as f:
        tomllib.load(f)
    print("toml ok:", p)
PY
    pass "toml parses"
  else
    fail "toml parses"
  fi
else
  printf 'SKIP: python tomllib unavailable\n'
fi

# --- Omarchy coupling audit: all app configs must be clean.
# The audit scripts match their own patterns, so they are excluded.
if grep -rEin 'omarchy|o\.bind|o\.window' \
  cachyos/hypr cachyos/noctalia cachyos/bin cachyos/install.sh cachyos/packages.sh \
  cachyos/lib cachyos/framework \
  nvim tmux zsh alacritty mise opencode README.md .dockerignore 2>/dev/null; then
  fail "omarchy coupling in runtime paths (see matches above)"
else
  pass "no omarchy coupling in runtime paths"
fi

# --- Dock audit: disabled, and no replacement dock may be referenced.
if grep -q 'enabled = false' cachyos/noctalia/50-mydotfiles.toml; then
  pass "noctalia dock disabled"
else
  fail "noctalia dock disabled"
fi
if grep -rEin 'waybar|swaync|quickshell|cairo-dock|nwg-dock|latte-dock|\brofi\b|\bwofi\b|\bmako\b|\bags\b|\bplank\b' \
  cachyos/hypr cachyos/noctalia cachyos/bin cachyos/install.sh cachyos/packages.sh \
  cachyos/lib cachyos/framework \
  nvim tmux zsh alacritty mise 2>/dev/null; then
  fail "replacement dock / foreign shell stack referenced (see matches above)"
else
  pass "no replacement dock"
fi

printf 'Result: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
