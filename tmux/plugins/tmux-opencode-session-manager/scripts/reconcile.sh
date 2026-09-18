#!/usr/bin/env bash
# Background reconciler: keeps @opencode_state stamps truthful without any
# popup open, so the status-line indicators (statusline.sh) stay correct.
#
#   reconcile.sh once    single pass (used by tests and manual runs)
#   reconcile.sh daemon  loop forever, one pass per @opencode_reconcile_every
#                        seconds (default 15). Started idempotently from
#                        opencode_session_manager.tmux; a PID lockfile prevents
#                        duplicate watchers after config reloads.
#
# Each pass:
#   1. Snapshots the opencode API once (active map, session list with
#      outcomes, permission requests, question forms) — same precedence as
#      the picker (see api.sh).
#   2. Per tracked tmux session, derives the correct state and writes it
#      back ONLY on change (no churn, no timestamp flapping):
#        waiting  pending permission/question here (outranks running)
#        working  an opencode session here is active
#        done     newest opencode session completed (outcome set, not active)
#                 AND its update is newer than the current stamp — history
#                 never re-fires, and acked completions stay acknowledged.
#        error    newest outcome is failed/interrupted (same newness guard)
#        idle     only written for brand-new sessions with no signal at all;
#                 existing stamps are otherwise left alone. Silence, a dead
#                 server, or a closed popup NEVER becomes completion.
#   3. Tombstones: live sessions remembered in $_oc_known_file; a vanished
#      session whose last state was unacknowledged done/waiting/error keeps a
#      tomb file (TTL 30 min) so its indicator outlives session removal.
#      Ack (ack.sh) or reappearance removes the tomb.
# Never switches clients, never steals focus, never kills sessions.
set -uo pipefail
DIR_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
. "$DIR_SELF/helpers.sh"
# shellcheck source=api.sh
. "$DIR_SELF/api.sh"

_reconcile_every() { get_tmux_option @opencode_reconcile_every '15'; }
_reconcile_lock() { printf '%s/reconcile.pid' "$_oc_cache_dir"; }

# _oc_stamp <session> <state> <detail> — write only on change.
_oc_stamp() {
  local s="$1" want="$2" detail="${3:-}" cur
  cur="$(octmux show-options -qv -t "$s" @opencode_state 2>/dev/null)"
  if [ "$cur" != "$want" ]; then
    octmux set-option -t "$s" @opencode_state "$want" 2>/dev/null
    octmux set-option -t "$s" @opencode_state_at "$(date +%s)" 2>/dev/null
    [ -n "$detail" ] && octmux set-option -t "$s" @opencode_detail "$detail" 2>/dev/null
  elif [ -n "$detail" ]; then
    local curd
    curd="$(octmux show-options -qv -t "$s" @opencode_detail 2>/dev/null)"
    [ "$curd" != "$detail" ] && octmux set-option -t "$s" @opencode_detail "$detail" 2>/dev/null
  fi
}

_oc_reconcile_once() {
  local prefix now every
  prefix="$(get_tmux_option @opencode_session_prefix 'oc_')"
  now="$(date +%s)"
  every="$(_reconcile_every)"

  _oc_fetch_cache

  local live_list
  live_list="$(octmux list-sessions -F '#{session_name}' 2>/dev/null | grep "^${prefix}" || true)"

  local s state at ack dir detail
  local has_active active_title active_ago newest_id newest_title newest_age active_ok newest_outcome newest_upd
  local cblock kids hdr wcount wait_detail wait_age
  local _wsid wstate wage wtitle

  while IFS= read -r s; do
    [ -n "$s" ] || continue
    state="$(octmux show-options -qv -t "$s" @opencode_state 2>/dev/null)"
    at="$(octmux show-options -qv -t "$s" @opencode_state_at 2>/dev/null)"
    ack="$(octmux show-options -qv -t "$s" @opencode_acked_at 2>/dev/null)"
    dir="$(octmux show-options -qv -t "$s" @opencode_dir 2>/dev/null)"
    detail="$(octmux show-options -qv -t "$s" @opencode_detail 2>/dev/null)"
    [ -z "$dir" ] && dir="$(octmux display-message -p -t "$s" '#{pane_current_path}' 2>/dev/null)"
    [ -n "$dir" ] || continue
    [[ "$at" =~ ^[0-9]+$ ]] || at=0

    IFS=$'\x1f' read -r has_active active_title active_ago newest_id newest_title newest_age active_ok newest_outcome newest_upd \
      <<<"$(_oc_api_lookup "$dir")"
    [[ "$newest_upd" =~ ^[0-9]+$ ]] || newest_upd=0

    cblock="$(_oc_dir_sessions "$dir")"
    kids="$(printf '%s' "$cblock" | tail -n +2)"
    hdr="$(printf '%s' "$cblock" | head -n 1)"
    wcount="${hdr##*waiting=}"; wcount="${wcount%%[^0-9]*}"; [ -n "$wcount" ] || wcount=0
    wait_detail=""
    if [ "$wcount" -gt 0 ]; then
      IFS=$'\x1f' read -r _wsid wstate wage wtitle <<<"$(printf '%s' "$kids" | head -n 1)"
      if [ "$wstate" = 'waiting' ]; then
        wait_detail="$wtitle"
        if [ "$wcount" -gt 1 ]; then wait_detail="$wait_detail (+$((wcount - 1)) more)"; fi
      fi
    fi

    if [ -n "$wait_detail" ]; then
      # 1. Input request outranks running (blocked runs stay "active").
      _oc_stamp "$s" 'waiting' "$wait_detail"
    elif [ "$has_active" = '1' ]; then
      # 2. Server says something here runs — authoritative working.
      # Combine both sources: API title says WHAT runs, plugin detail says
      # what it is doing RIGHT NOW. Never stack the title twice.
      combined="$active_title"
      if [ -z "$active_title" ]; then combined="${detail:-working}"
      elif [ -n "$detail" ] && [ "$detail" != "$active_title" ] \
        && [[ "$detail" != "$active_title | "* ]]; then
        combined="$active_title | $detail"
      elif [ -n "$detail" ]; then
        combined="$detail"
      fi
      [ -n "$combined" ] || combined='working'
      _oc_stamp "$s" 'working' "$combined"
    elif [ "${active_ok:-0}" = '1' ] && [ -n "$newest_id" ] && [ -n "$newest_outcome" ] \
      && (( newest_upd > at * 1000 )); then
      # 3. A completion NEWER than the current stamp. Terminal outcomes only;
      #    sessions without an outcome are still mid-turn -> leave the stamp.
      if [ "$newest_outcome" = 'failed' ]; then
        _oc_stamp "$s" 'error' "${newest_title:0:60} -- run failed"
      elif [ "$newest_outcome" = 'interrupted' ]; then
        _oc_stamp "$s" 'error' "${newest_title:0:60} -- interrupted"
      else
        _oc_stamp "$s" 'done' "${newest_title:0:60}"
      fi
    elif [ -z "$state" ]; then
      # 4. No stamp at all: seed idle (server reachable) so fresh sessions
      #    never show unknown when the plugin hasn't fired yet. When the
      #    server is unreachable (active_ok=0) leave empty -> unknown.
      if [ "${active_ok:-0}" = '1' ]; then
        if [ -n "$newest_id" ]; then _oc_stamp "$s" 'idle' "${newest_title:0:60}"
        else _oc_stamp "$s" 'idle' 'ready'; fi
      fi
    fi
    # Otherwise: keep the last-known stamp. In particular a former `waiting`
    # with no active run and no newer outcome keeps waiting (its request may
    # simply be invisible to this poll); done/error persist until ack or a
    # new working stamp. Nothing here invents completion.
  done <<<"$live_list"

  # Sidecar: remember last stamp per session so removal can tombstone it.
  # Snapshot the PREVIOUS sidecar first: it holds sessions (and stamps) from
  # the last pass, including ones that vanished since.
  mkdir -p "$_oc_tomb_dir" 2>/dev/null
  local sidecar="$_oc_cache_dir/known_stamps" tmp_sidecar="" old_sidecar=""
  [ -f "$sidecar" ] && old_sidecar="$(cat "$sidecar" 2>/dev/null)"
  tmp_sidecar="$(mktemp "$_oc_cache_dir/known_stamps.XXXXXX" 2>/dev/null)" || tmp_sidecar=""
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    state="$(octmux show-options -qv -t "$s" @opencode_state 2>/dev/null)"
    at="$(octmux show-options -qv -t "$s" @opencode_state_at 2>/dev/null)"
    ack="$(octmux show-options -qv -t "$s" @opencode_acked_at 2>/dev/null)"
    dir="$(octmux show-options -qv -t "$s" @opencode_dir 2>/dev/null)"
    detail="$(octmux show-options -qv -t "$s" @opencode_detail 2>/dev/null)"
    [ -n "$tmp_sidecar" ] && printf '%s|%s|%s|%s|%s|%s\n' "$s" "$state" "$at" "$ack" "${dir:-$s}" "${detail:-}" >>"$tmp_sidecar"
  done <<<"$live_list"
  if [ -n "$tmp_sidecar" ]; then
    mv "$tmp_sidecar" "$sidecar" 2>/dev/null
  fi
  # Vanished sessions (in the previous sidecar, gone from live now):
  # tombstone unacknowledged done/waiting/error so the indicator outlives
  # session removal. Live sessions clear any stale tomb.
  local row eff
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    IFS='|' read -r s state at ack dir detail <<<"$row"
    case "$s" in "$prefix"*) ;;
      *) continue ;;
    esac
    if printf '%s\n' "$live_list" | grep -qxF "$s"; then
      rm -f "$_oc_tomb_dir/$s.tomb" 2>/dev/null
    else
      eff="$state"
      if [ "$state" = 'done' ] && [[ "$ack" =~ ^[0-9]+$ ]] && [[ "$at" =~ ^[0-9]+$ ]] \
        && (( ack > 0 )) && (( ack >= at )); then eff='idle'; fi
      case "$eff" in
        done|waiting|error)
          printf '%s|%s|%s|%s|%s\n' "$s" "$state" "$at" "${dir:-$s}" "${detail:-gone}" >"$_oc_tomb_dir/$s.tomb" 2>/dev/null
          ;;
      esac
    fi
  done <<<"$old_sidecar"

  # Sweep expired tombs.
  find "$_oc_tomb_dir" -maxdepth 1 -name '*.tomb' -mmin +30 -delete 2>/dev/null
  return 0
}

_oc_daemon_lock() {
  local lock pid
  lock="$(_reconcile_lock)"
  mkdir -p "$_oc_cache_dir" 2>/dev/null
  if [ -f "$lock" ]; then
    pid="$(cat "$lock" 2>/dev/null)"
    if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
      return 1 # already running
    fi
  fi
  printf '%s' "$$" >"$lock" 2>/dev/null
  return 0
}

case "${1:-once}" in
  daemon)
    _oc_daemon_lock || exit 0
    every="$(_reconcile_every)"
    [[ "$every" =~ ^[0-9]+$ ]] || every=15
    (( every >= 5 )) || every=5
    while true; do
      _oc_reconcile_once
      sleep "$every"
    done
    ;;
  once|'')
    _oc_reconcile_once
    ;;
  *)
    printf 'usage: %s [once|daemon]\n' "$0" >&2
    exit 2
    ;;
esac
