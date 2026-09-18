#!/usr/bin/env bash
# Focused tests for tmux-opencode-session-manager state + identity handling.
#
#   bash scripts/tests.sh
#
# Covers: effective-state transitions (done/error/waiting vs ack), glyph
# distinctness + spinner animation, label identity (basename collisions,
# truncation), session_hash stability, ack.sh semantics via a stub tmux, and
# statusline.sh rendering (overflow, tombstones, dead server) via a stub.
set -uo pipefail
DIR_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pass=0; fail=0
ok() { pass=$((pass + 1)); printf 'ok   %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL %s\n  %s\n' "$1" "${2:-}"; }
is() { # is <desc> <got> <want>
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "got [$2] want [$3]"; fi
}

# --- pure functions from statusline.sh (sourced, main not executed) ---
# shellcheck source=statusline.sh
. "$DIR_SELF/statusline.sh"

# 1. Effective-state transitions.
is 'working stays working' "$(oc_effective_state working 100 200)" 'working'
is 'waiting never acked away' "$(oc_effective_state waiting 100 200)" 'waiting'
is 'done unacked stays done' "$(oc_effective_state done 100 0)" 'done'
is 'done with older ack stays done' "$(oc_effective_state done 200 100)" 'done'
is 'done with newer ack -> idle' "$(oc_effective_state done 100 200)" 'idle'
is 'done with equal ack -> idle' "$(oc_effective_state done 100 100)" 'idle'
is 'error never acked away' "$(oc_effective_state error 100 999)" 'error'
is 'idle stays idle' "$(oc_effective_state idle 100 0)" 'idle'
is 'empty state -> unknown' "$(oc_effective_state '' 0 0)" 'unknown'
is 'garbage state -> unknown' "$(oc_effective_state exploded 1 2)" 'unknown'

# 2. Glyphs: symbol as well as color; done distinct from idle; spinner moves.
g_work0="$(oc_glyph working 0)"; g_work1="$(oc_glyph working 1)"
g_done="$(oc_glyph done 0)"; g_idle="$(oc_glyph idle 0)"
g_wait="$(oc_glyph waiting 0)"; g_err="$(oc_glyph error 0)"; g_unk="$(oc_glyph bogus 0)"
[ "$g_work0" != "$g_work1" ] && ok 'spinner animates across frames' || bad 'spinner animates across frames' "$g_work0 vs $g_work1"
[ "$g_done" != "$g_idle" ] && ok 'done distinct from idle' || bad 'done distinct from idle' "$g_done vs $g_idle"
[ "$g_wait" != "$g_work0" ] && [ "$g_wait" != "$g_err" ] && ok 'waiting distinct' || bad 'waiting distinct' "$g_wait"
[ "$g_err" != "$g_work0" ] && ok 'error distinct from working' || bad 'error distinct from working' "$g_err vs $g_work0"
case "$g_done" in *✓*) ok 'done glyph is check' ;; *) bad 'done glyph is check' "$g_done" ;; esac
case "$g_err" in *✖*) ok 'error glyph is cross' ;; *) bad 'error glyph is cross' "$g_err" ;; esac
case "$g_wait" in *◉*) ok 'waiting glyph is fisheye' ;; *) bad 'waiting glyph is fisheye' "$g_wait" ;; esac

# 3. Labels: identity without conflation.
is 'label is basename' "$(oc_label /home/u/myDotFiles 0)" 'myDotFiles'
is 'collision uses parent/base' "$(oc_label /home/u/myDotFiles 1)" 'u/myDotFiles'
long="$(oc_label /home/u/a-very-long-directory-name 0)"
(( ${#long} <= 12 )) && ok 'long label truncated' || bad 'long label truncated' "$long"
[ "$(oc_label /a/x/proj 1)" != "$(oc_label /b/y/proj 1)" ] && ok 'same basename disambiguated' \
  || bad 'same basename disambiguated' "$(oc_label /a/x/proj 1) vs $(oc_label /b/y/proj 1)"

# 4. session_hash: stable + matches the launcher contract (cksum of dir).
# shellcheck source=helpers.sh
. "$DIR_SELF/helpers.sh"
h1="$(session_hash /home/amir/Personal/myDotFiles)"
h2="$(session_hash /home/amir/Personal/myDotFiles)"
h3="$(printf '%s' /home/amir/Personal/myDotFiles | cksum | cut -d' ' -f1)"
[ "$h1" = "$h2" ] && [ "$h1" = "$h3" ] && [ -n "$h1" ] && ok 'session_hash stable, matches cksum' || bad 'session_hash' "$h1 $h2 $h3"
[ "$(session_hash /a)" != "$(session_hash /b)" ] && ok 'session_hash differs per dir' || bad 'session_hash differs per dir'

# --- stub-tmux integration tests ---
_mkstub() { # _mkstub <dir> : writes $dir/tmux, sets STUBLOG; behavior via env
  local d="$1"
  export STUBLOG="$d/calls.log"
  export STUB_FIXTURE="${STUB_FIXTURE:-}"
  export STUB_STATE="${STUB_STATE:-}"
  : >"$STUBLOG"
  cat >"$d/tmux" <<'STUB'
#!/usr/bin/env bash
# Test stub for tmux. Env: STUB_FIXTURE (list-sessions output), STUB_STATE
# (answer for show-options -qv ... @opencode_state), STUBLOG (append calls).
log() { printf '%s\n' "$*" >>"$STUBLOG"; }
args="$*"
case "$args" in
  *list-sessions*)
    printf '%s' "${STUB_FIXTURE:-}"
    ;;
  *has-session*) exit 0 ;;
  *show-options*-qv*)
    case "$args" in
      *@opencode_state*) printf '%s' "${STUB_STATE:-}" ;;
      *) printf '' ;;
    esac
    ;;
  *set-option*) log "SET $args" ;;
  *) log "CALL $args" ;;
esac
exit 0
STUB
  chmod +x "$d/tmux"
}

T="$(mktemp -d /tmp/oc-tests.XXXXXX)"
trap 'rm -rf "$T"' EXIT
_mkstub "$T"
export PATH="$T:$PATH"

# 5. ack.sh semantics.
export STUB_STATE='done'
rm -f "$STUBLOG"; : >"$STUBLOG"
STUB_STATE='done' "$DIR_SELF/ack.sh" oc_123 >/dev/null 2>&1
grep -q '@opencode_acked_at' "$STUBLOG" && ok 'ack stamps visit' || bad 'ack stamps visit' "$(cat "$STUBLOG")"
grep -q '@opencode_state done' "$STUBLOG" || grep -q '@opencode_state idle' "$STUBLOG" && ok 'ack demotes done->idle' || bad 'ack demotes done->idle' "$(cat "$STUBLOG")"

STUB_STATE='waiting'
rm -f "$STUBLOG"; : >"$STUBLOG"
STUB_STATE='waiting' "$DIR_SELF/ack.sh" oc_123 >/dev/null 2>&1
if grep -q '@opencode_state ' "$STUBLOG"; then bad 'ack never clears waiting' "$(cat "$STUBLOG")"; else ok 'ack never clears waiting'; fi

STUB_STATE='error'
rm -f "$STUBLOG"; : >"$STUBLOG"
STUB_STATE='error' "$DIR_SELF/ack.sh" oc_123 >/dev/null 2>&1
if grep -q '@opencode_state ' "$STUBLOG"; then bad 'ack never clears error' "$(cat "$STUBLOG")"; else ok 'ack never clears error'; fi

# 6. statusline rendering against fixture sessions.
US=$'\x1f'
export STUB_FIXTURE="oc_111${US}working${US}100${US}0${US}/home/u/alpha${US}tool shell
oc_222${US}done${US}200${US}0${US}/home/u/beta${US}finished thing"
out="$(oc_statusline_main 2>/dev/null)"
case "$out" in *alpha*) ok 'renders indicator for agent alpha' ;; *) bad 'renders indicator for agent alpha' "$out" ;; esac
case "$out" in *beta*) ok 'renders indicator for agent beta' ;; *) bad 'renders indicator for agent beta' "$out" ;; esac
case "$out" in *✓*) ok 'done check rendered' ;; *) bad 'done check rendered' "$out" ;; esac

# Overflow: max 1 with 2 agents -> "+1".
tmux() { # shadow stub: force @opencode_indicators_max=1 via get_tmux_option? use option file instead
  command -v tmux >/dev/null; "$T/tmux" "$@"
}
# get_tmux_option reads real tmux; override via function for this test.
get_tmux_option() {
  case "$1" in
    @opencode_indicators_max) printf '1' ;;
    @opencode_indicator_idle) printf 'on' ;;
    @opencode_session_prefix) printf 'oc_' ;;
    @opencode_socket) printf 'opencode-popup' ;;
    *) printf '%s' "$2" ;;
  esac
}
out="$(oc_statusline_main 2>/dev/null)"
case "$out" in *+1*) ok 'overflow count rendered' ;; *) bad 'overflow count rendered' "$out" ;; esac
unset -f get_tmux_option 2>/dev/null
# shellcheck source=helpers.sh
. "$DIR_SELF/helpers.sh" # restore real get_tmux_option

# Tombstones render with ~ suffix and survive dead sessions.
export TMPDIR="$T/tmp"
mkdir -p "$TMPDIR/opencode-picker-$USER/tombs"
printf 'oc_999|done|300|/home/u/gamma|finished' >"$TMPDIR/opencode-picker-$USER/tombs/oc_999.tomb"
export STUB_FIXTURE="oc_111${US}working${US}100${US}0${US}/home/u/alpha${US}tool shell"
out="$(oc_statusline_main 2>/dev/null)"
case "$out" in *gamma\~*) ok 'tombstone retained with marker' ;; *) bad 'tombstone retained with marker' "$out" ;; esac
export TMPDIR="${TMPDIR:-/tmp}"

# Dead server -> silent, never fake completion. (Clear tombs first: they are
# MEANT to survive outages; here we assert no live-session output.)
rm -rf "$TMPDIR/opencode-picker-$USER/tombs"
cat >"$T/tmux" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
chmod +x "$T/tmux"
out="$(oc_statusline_main 2>/dev/null)"
[ -z "$out" ] && ok 'dead server renders nothing' || bad 'dead server renders nothing' "$out"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
