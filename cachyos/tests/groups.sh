#!/usr/bin/env bash
# Self-check for ensure_group (cachyos/lib/common.sh): the opt-in group
# handling must print the exact usermod command whenever it skips a change.
# Stubs id/getent/as_root so it runs as any user on any machine.
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
export REPO_DIR
# shellcheck disable=SC1091
source "$REPO_DIR/cachyos/lib/common.sh"

failures=0
ok() { printf 'ok   %s\n' "$1"; }
bad() {
  printf 'FAIL %s\n' "$1" >&2
  shift
  printf '     %s\n' "$@" >&2
  failures=$((failures + 1))
}
contains() {
  local what="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    ok "$what"
  else
    bad "$what" "missing: $needle" "in: $haystack"
  fi
}
lacks() {
  local what="$1" haystack="$2" needle="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    ok "$what"
  else
    bad "$what" "unexpectedly present: $needle" "in: $haystack"
  fi
}
silent() {
  local what="$1" haystack="$2"
  if [[ -z "$haystack" ]]; then
    ok "$what"
  else
    bad "$what" "expected no output, got: $haystack"
  fi
}

# Stubs, defined after the source so they win.
MY_GROUPS="tester wheel"
MY_EXISTING_GROUP="docker"
id() {
  case "$1" in
    -un) printf 'tester' ;;
    -nG) printf '%s' "$MY_GROUPS" ;;
    *) command id "$@" ;;
  esac
}
getent() { [[ "$2" == "$MY_EXISTING_GROUP" ]]; }
as_root() { printf 'as_root %s\n' "$*"; }

# 1. no flag: prints the exact command (for the account from `id -un`, not
#    $USER) and changes nothing.
ALLOW_GROUPS=false
out=$(ensure_group docker "privilege escalation")
contains "hint prints the exact usermod command" "$out" 'sudo usermod -aG docker "tester"'
contains "hint names the reason" "$out" "privilege escalation"
lacks "hint changes no groups" "$out" "as_root"

# 2. --allow-groups: joins the group, prints no hint.
ALLOW_GROUPS=true
out=$(ensure_group docker "privilege escalation")
contains "flag joins the group" "$out" "as_root usermod -aG docker tester"
lacks "flag prints no hint" "$out" "sudo usermod"

# 3. group missing on this machine: silence, never a command that cannot run.
ALLOW_GROUPS=false
out=$(ensure_group input "raw keyboard access")
silent "missing group stays silent" "$out"

# 4. already a member: nothing to do, no hint, no change.
MY_GROUPS="tester wheel docker"
out=$(ensure_group docker "privilege escalation")
silent "member is left alone" "$out"
MY_GROUPS="tester wheel"

if [[ "$failures" -eq 0 ]]; then
  printf 'all checks passed\n'
else
  printf '%s check(s) failed\n' "$failures" >&2
  exit 1
fi
