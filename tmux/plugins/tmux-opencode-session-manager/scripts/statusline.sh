#!/usr/bin/env bash
# Persistent per-agent status indicators for the tmux status line.
#
# Rendered via `#(statusline.sh)` in status-right on the MAIN tmux server, so
# indicators stay visible in every session even when all popups are closed.
# One compact indicator per tracked agent (one `oc_<hash>` tmux session on the
# dedicated socket): a short directory label plus a state glyph.
#
# Tradeoff note: tmux offers no floating/persistent overlay besides popups and
# menus, both of which cover terminal content and vanish on dismissal. A
# right-aligned status-line group is the only native persistent UI, so the
# indicators live there (just left of the hostname = bottom-right).
#
# Performance: this script runs on EVERY status-interval tick, so it must stay
# cheap — exactly ONE `tmux -L <socket> list-sessions` call plus tombstone
# file reads. No `opencode api` calls, no python, no capture-pane here. The
# background reconcile.sh daemon does the expensive API polling and writes
# its conclusions into @opencode_state/@opencode_detail stamps this reads.
#
# States (symbol + color, never color alone):
#   working  animated spinner (frame from epoch)  red      ⠋ label
#   waiting  attention, needs input/permission     yellow   ◉ label!
#   done     finished, unacknowledged              green    ✓ label
#   error    failed/interrupted                    red      ✖ label
#   idle     acknowledged, nothing pending         dim grey ○ label
#   unknown  no stamp and no other signal          dim grey ? label
# Silence / dead server / closed popup NEVER render as done: unknown stamps
# stay unknown, and last-known working/waiting/done/error stamps persist.
#
# Sourced by tests (tests.sh) to exercise the pure functions; executed
# directly by tmux `#()`. Sourcing must not emit output or run main:
#   [[ "${BASH_SOURCE[0]}" != "$0" ]] || oc_statusline_main

_oc_statusline_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
. "$_oc_statusline_dir/helpers.sh"

# Options (set on the MAIN server; all optional).
#   @opencode_indicators_max   max indicators before "+N" overflow (default 4)
#   @opencode_indicator_idle   show dim idle agents too? (default on)
_oc_indicators_max() { get_tmux_option @opencode_indicators_max '4'; }
_oc_show_idle() { get_tmux_option @opencode_indicator_idle 'on'; }

_oc_spinner_frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

# oc_effective_state <state> <state_at> <acked_at> -> effective state.
# Returning to an agent acknowledges *completion* only: done + ack newer than
# the stamp collapses to idle. Waiting and error are NEVER cleared by ack —
# only a new task (fresh working stamp) or explicit resolution moves them.
oc_effective_state() {
  local state="${1:-}" at="${2:-0}" ack="${3:-0}"
  case "$state" in
    working|waiting|error|idle) printf '%s' "$state" ;;
    done)
      if [[ "$ack" =~ ^[0-9]+$ ]] && [[ "$at" =~ ^[0-9]+$ ]] \
        && (( ack > 0 )) && (( ack >= at )); then
        printf 'idle'
      else
        printf 'done'
      fi
      ;;
    *) printf 'unknown' ;;
  esac
}

# oc_label <dir> <collision:0|1> -> short identifying label (max 12 chars).
# Stable per directory; when two tracked dirs share a basename, use
# parent/base so indicators never conflate agents.
oc_label() {
  local dir="${1:-?}" collision="${2:-0}" base parent
  base="$(basename "$dir")"
  if [ "$collision" = '1' ]; then
    parent="$(basename "$(dirname "$dir")")"
    base="$parent/$base"
  fi
  if (( ${#base} > 12 )); then base="${base:0:11}…"; fi
  printf '%s' "$base"
}

# oc_glyph <effective-state> <frame-idx> -> "fg-color|glyph|s-rank"
# s-rank sorts attention first for display order.
oc_glyph() {
  case "$1" in
    waiting) printf 'yellow|◉|0' ;;
    error)   printf 'red|✖|1' ;;
    done)    printf 'green|✓|2' ;;
    working) printf 'red|%s|3' "${_oc_spinner_frames[$((${2:-0} % 10))]}" ;;
    idle)    printf 'brightblack|○|4' ;;
    *)       printf 'brightblack|?|5' ;;
  esac
}

oc_statusline_main() {
  local socket max show_idle now frame
  socket="$(oc_socket)"
  max="$(_oc_indicators_max)"
  [[ "$max" =~ ^[0-9]+$ ]] || max=4
  show_idle="$(_oc_show_idle)"
  now="$(date +%s)"
  frame=$((now % 10))

  # Single tmux call: session | state | state_at | acked_at | dir | detail.
  # Unset options expand empty — never an error, never completion.
  local rows
  rows="$(tmux -L "$socket" list-sessions -F '#{session_name}'$'\x1f''#{@opencode_state}'$'\x1f''#{@opencode_state_at}'$'\x1f''#{@opencode_acked_at}'$'\x1f''#{@opencode_dir}'$'\x1f''#{@opencode_detail}' 2>/dev/null)" || rows=""

  local prefix
  prefix="$(get_tmux_option @opencode_session_prefix 'oc_')"

  # Collect live rows for label-collision detection + tombstone sweep below.
  local -a names=() states=() dirs=()
  local line s state at ack dir detail eff
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    IFS=$'\x1f' read -r s state at ack dir detail <<<"$line"
    case "$s" in "$prefix"*) ;;
      *) continue ;;
    esac
    [ -n "$dir" ] || dir="$s"
    eff="$(oc_effective_state "$state" "$at" "$ack")"
    if [ "$eff" = 'idle' ] && [ "$show_idle" != 'on' ]; then continue; fi
    names+=("$s"); states+=("$eff"); dirs+=("$dir")
  done <<<"$rows"

  # Tombstones: vanished sessions whose unacknowledged done/waiting/error
  # must stay visible. Written by reconcile.sh; rendered dim with same glyphs.
  local -a tnames=() tstates=() tdirs=()
  local tombdir="${TMPDIR:-/tmp}/opencode-picker-$USER/tombs" tf
  if [ -d "$tombdir" ]; then
    for tf in "$tombdir"/*.tomb; do
      [ -f "$tf" ] || continue
      s=""; IFS='|' read -r s state at dir detail <"$tf" 2>/dev/null || [ -n "$s" ]
      [ -n "$s" ] || continue
      # Skip tombs for sessions that are live again (reconcile removes them,
      # but stay correct if it hasn't run yet).
      local live=0 n
      for n in ${names[@]+"${names[@]}"}; do [ "$n" = "$s" ] && live=1; done
      [ "$live" = '1' ] && continue
      eff="$(oc_effective_state "$state" "$at" "")"
      case "$eff" in done|waiting|error) ;; *) continue ;; esac
      tnames+=("$s"); tstates+=("$eff"); tdirs+=("${dir:-$s}")
    done
  fi

  local total=$((${#names[@]} + ${#tnames[@]}))
  [ "$total" -gt 0 ] || exit 0

  # Basename collisions across live + tomb rows -> parent/base labels.
  local -a all_dirs=()
  for d in ${dirs[@]+"${dirs[@]}"}; do all_dirs+=("$d"); done
  for d in ${tdirs[@]+"${tdirs[@]}"}; do all_dirs+=("$d"); done
  local i out="" shown=0
  local order
  order="$( {
    for i in "${!names[@]}"; do
      IFS='|' read -r _ _ rank <<<"$(oc_glyph "${states[$i]}" "$frame")"
      printf '%s %s %s\n' "$rank" "${dirs[$i]}" "L$i"
    done
    for i in "${!tnames[@]}"; do
      IFS='|' read -r _ _ rank <<<"$(oc_glyph "${tstates[$i]}" "$frame")"
      printf '%s %s %s\n' "$rank" "${tdirs[$i]}" "T$i"
    done
  } | sort -k1,1n -k2,2 | cut -d' ' -f3-)" || order=""

  local kind idx st d base collision glyph color _rank suffix j
  while IFS= read -r kind; do
    [ -n "$kind" ] || continue
    if (( shown >= max )); then break; fi
    case "$kind" in
      L*) idx="${kind#L}"; st="${states[$idx]}"; d="${dirs[$idx]}"; suffix="" ;;
      T*) idx="${kind#T}"; st="${tstates[$idx]}"; d="${tdirs[$idx]}"; suffix="~" ;;
      *) continue ;;
    esac
    base="$(basename "$d")"
    collision=0
    for j in "${!all_dirs[@]}"; do
      [ "${all_dirs[$j]}" = "$d" ] && continue
      if [ "$(basename "${all_dirs[$j]}")" = "$base" ]; then collision=1; break; fi
    done
    base="$(oc_label "$d" "$collision")$suffix"
    IFS='|' read -r color glyph _rank <<<"$(oc_glyph "$st" "$frame")"
    # Waiting gets a trailing "!" so attention survives color-stripped copies.
    if [ "$st" = 'waiting' ]; then base="$base!"; fi
    out="$out#[fg=$color]$glyph $base#[fg=default] "
    shown=$((shown + 1))
  done <<<"$order"

  if (( total > shown )); then
    out="$out#[fg=brightblack]+$((total - shown))#[fg=default] "
  fi
  printf '%s' "$out"
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || oc_statusline_main
