#!/usr/bin/env bash
# Interactive picker for running opencode sessions (on the dedicated socket).
#
#   picker.sh           fzf picker; on enter, switches the parent client to the
#                       chosen session's origin window and resumes it in a popup.
#   picker.sh --list    print the rows only (used by fzf's ctrl-x reload).
set -uo pipefail
DIR_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
. "$DIR_SELF/helpers.sh"

prefix="$(get_tmux_option @opencode_session_prefix 'oc_')"
socket="$(oc_socket)"

# --- Status resolution -------------------------------------------------------
# The picker used to trust only the tmux-status plugin (@opencode_state),
# which left every session stuck at "?" when the plugin was missing (or, with
# opencode v2, when the old V1 plugin stopped running: V1 hooks don't execute
# in V2, and the service-side plugin can't see $TMUX anyway).
#
# Resolution order per tmux session directory (first hit wins):
#   1. waiting — a child with a pending permission or open question form.
#        Must come first: a blocked session stays "running" server-side, so
#        liveness alone would hide question mode behind "working".
#   2. opencode API active map  -> working (+ newest running session title)
#   3. plugin state, when fresh -> as stamped (+ plugin detail)
#        (stale "working" with nothing active is ignored, not stuck)
#   4. opencode API: newest session in that directory -> idle (+ its title)
#   5. local plugin stamp (server unreachable) -> as stamped
#   6. live pane heuristic ("esc interrupt" footer) -> working/waiting
#   7. "?" only when nothing at all is known.
_oc_cache_dir="${TMPDIR:-/tmp}/opencode-picker-$USER"
_oc_active_file="$_oc_cache_dir/active.json"
_oc_sess_file="$_oc_cache_dir/sessions.json"
_oc_perms_file="$_oc_cache_dir/perms.json"
_oc_forms_file="$_oc_cache_dir/forms.json"
# Expansion state: one tmux session name per line (stable `oc_<hash>` ids).
_oc_expanded_file="$_oc_cache_dir/expanded"

_oc_fetch_cache() {
  mkdir -p "$_oc_cache_dir" 2>/dev/null
  # Drop row workdirs orphaned by killed runs (concurrent runs use unique
  # names, so only reap dirs idle for over an hour).
  find "$_oc_cache_dir" -maxdepth 1 -name 'rows.*' -mmin +60 -exec rm -rf {} + 2>/dev/null
  # `timeout` is GNU-only; run bare where it is missing.
  if command -v timeout >/dev/null 2>&1; then
    _oc_to() { timeout "$@"; }
  else
    _oc_to() { shift; "$@"; }
  fi
  if command -v opencode >/dev/null 2>&1; then
    _oc_to 5 opencode api get /api/session/active >"$_oc_active_file" 2>/dev/null || : >"$_oc_active_file"
    _oc_to 8 opencode api get /api/session --param limit=200 >"$_oc_sess_file" 2>/dev/null || : >"$_oc_sess_file"
    _oc_to 5 opencode api get /api/permission/request >"$_oc_perms_file" 2>/dev/null || : >"$_oc_perms_file"
    _oc_to 5 opencode api get /api/form >"$_oc_forms_file" 2>/dev/null || : >"$_oc_forms_file"
  else
    : >"$_oc_active_file"
    : >"$_oc_sess_file"
    : >"$_oc_perms_file"
    : >"$_oc_forms_file"
  fi
}

# _oc_api_lookup <dir> — one \x1f-separated line:
# has_active | active_title | active_age_m | newest_id | newest_title | newest_age_m | active_ok
# (\x1f, not tab: bash read collapses empty tab-separated fields.
# active_ok=0 means liveness is unknown: callers must not report idle.)
_oc_api_lookup() {
  python3 - "$1" "$_oc_active_file" "$_oc_sess_file" <<'EOF' 2>/dev/null
import json, sys, time
d, active_f, sess_f = sys.argv[1], sys.argv[2], sys.argv[3]
now = time.time() * 1000
active = None
try:
    raw = json.load(open(active_f)).get("data", {})
    if isinstance(raw, dict):
        active = set(raw.keys())
except Exception:
    pass
cands = []
try:
    for s in json.load(open(sess_f)).get("data", []):
        loc = (s.get("location") or {}).get("directory", "")
        if loc == d:
            cands.append(s)
except Exception:
    pass
cands.sort(key=lambda s: s.get("time", {}).get("updated", 0), reverse=True)
at, aa = "", "-"
if active:
    for s in cands:
        if s.get("id") in active:
            at = str(s.get("title") or "").replace("\t", " ").replace("\n", " ")[:60]
            aa = "%dm" % max(0, int((now - s.get("time", {}).get("updated", now)) / 60000))
            break
nid, nt, na = "", "", "-"
if cands:
    n = cands[0]
    nid = n.get("id", "")
    nt = str(n.get("title") or "").replace("\t", " ").replace("\n", " ")[:60]
    na = "%dm" % max(0, int((now - n.get("time", {}).get("updated", now)) / 60000))
print("%d\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%d" % (1 if at else 0, at, aa, nid, nt, na, 1 if active is not None else 0))
EOF
}

# _oc_dir_sessions <dir> — every opencode session in one tmux session's
# directory (exact match on the tmux session's own @opencode_dir, never fuzzy
# path/title grouping; every session ID is its own entry even when titles
# repeat). Prints a header line `active_ok=<0|1> waiting=<n>` then one
# \x1f-separated line per child: ses_id | status | age_m | display_title.
# Status precedence: waiting (pending permission OR open question form)
# outranks working — a blocked session stays "running" server-side, so
# liveness alone would hide question mode. Prints nothing at all when the
# session list is unavailable — unknown children are omitted, never faked.
_oc_dir_sessions() {
  python3 - "$1" "$_oc_active_file" "$_oc_sess_file" "$_oc_perms_file" "$_oc_forms_file" <<'EOF' 2>/dev/null
import json, sys, time
d, active_f, sess_f, perms_f, forms_f = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
now = time.time() * 1000
def load(f):
    try:
        return json.load(open(f))
    except Exception:
        return None
active_raw, sess_raw = load(active_f), load(sess_f)
perms_raw, forms_raw = load(perms_f), load(forms_f)
if isinstance(sess_raw, dict) and isinstance(sess_raw.get("data"), list):
    sess_list = sess_raw["data"]
else:
    sess_list = None
active = None
if isinstance(active_raw, dict) and isinstance(active_raw.get("data"), dict):
    active = set(active_raw["data"].keys())
perm_action = {}
if isinstance(perms_raw, dict) and isinstance(perms_raw.get("data"), list):
    for r in perms_raw["data"]:
        if isinstance(r, dict) and r.get("sessionID") and r["sessionID"] not in perm_action:
            perm_action[r["sessionID"]] = str(r.get("action") or r.get("type") or "approval")
form_title = {}
if isinstance(forms_raw, dict) and isinstance(forms_raw.get("data"), list):
    for f in forms_raw["data"]:
        if isinstance(f, dict) and f.get("sessionID") and f["sessionID"] not in form_title:
            form_title[f["sessionID"]] = str(f.get("title") or "question")[:40]
if sess_list is None:
    sys.exit(0)
cands = [s for s in sess_list
         if isinstance(s, dict) and (s.get("location") or {}).get("directory") == d]
order = {"waiting": 0, "working": 1, "idle": 2, "?": 3}
rows = []
for s in cands:
    sid = s.get("id", "")
    if active is None:
        st, reason = "?", ""
    elif sid in perm_action:
        st, reason = "waiting", perm_action[sid]
    elif sid in form_title:
        st, reason = "waiting", form_title[sid]
    elif sid in active:
        st, reason = "working", ""
    else:
        st, reason = "idle", ""
    upd = (s.get("time", {}) or {}).get("updated", now)
    age = "%dm" % max(0, int((now - upd) / 60000))
    title = str(s.get("title") or "(untitled)").replace("\x1f", " ").replace("\t", " ").replace("\n", " ")
    if reason:
        title = "%s -- %s" % (title, reason)
    rows.append((order[st], -upd, sid, st, age, title[:60]))
nwaiting = sum(1 for r in rows if r[3] == "waiting")
print("active_ok=%d waiting=%d" % (1 if active is not None else 0, nwaiting))
for _, _, sid, st, age, title in sorted(rows):
    print("%s\x1f%s\x1f%s\x1f%s" % (sid, st, age, title))
EOF
}

# _oc_pane_guess <tmux-session> — live-screen fallback. Prints working|waiting|""
_oc_pane_guess() {
  local tail
  tail="$(tmux -L "$socket" capture-pane -p -t "$1" 2>/dev/null | tail -n 8)" || return 0
  case "$tail" in
  *[Pp]ermission*|*[Aa]pprove*|*allow*deny*|*Would\ you\ like*) printf 'waiting' ;;
  *esc\ interrupt*|*interrupt*) printf 'working' ;;
  esac
}

_ago_m() { # _ago_m <now_s> <at_s> -> "Nm" or "-"
  if [ -n "${2:-}" ] && [ "$2" -gt 0 ] 2>/dev/null; then printf '%dm' "$((($1 - $2) / 60))"; else printf '-'; fi
}

# _oc_icon <state> — sets $icon (shared by parent and child rows).
_oc_icon() {
  case "$1" in
  waiting) icon=$'\033[33m\u25cf\033[0m waiting' ;; # yellow - needs input
  idle)    icon=$'\033[32m\u25cf\033[0m idle   ' ;; # green  - done, your turn
  working) icon=$'\033[31m\u25cf\033[0m working' ;; # red    - busy, leave it
  *)       icon=$'\033[90m\u25cf\033[0m   ?    ' ;; # grey   - unknown
  esac
}

# _oc_is_expanded <tmux-session> — true when its children are toggled visible.
_oc_is_expanded() {
  [ -f "$_oc_expanded_file" ] && grep -qxF "$1" "$_oc_expanded_file" 2>/dev/null
}

# _oc_toggle <tmux-session> — flip one parent's expansion state. No-op for
# unknown sessions and sessions without children. Uses the last refresh's
# cache (no refetch), so toggling stays instant and consistent with display.
_oc_toggle() {
  local s dir cblock kids
  s="${1:-}"
  [ -n "$s" ] || exit 0
  octmux has-session -t "=$s" 2>/dev/null || exit 0
  mkdir -p "$_oc_cache_dir" 2>/dev/null
  touch "$_oc_expanded_file" 2>/dev/null
  if grep -qxF "$s" "$_oc_expanded_file" 2>/dev/null; then
    grep -vxF "$s" "$_oc_expanded_file" >"$_oc_expanded_file.tmp" 2>/dev/null || true
    mv "$_oc_expanded_file.tmp" "$_oc_expanded_file" 2>/dev/null
  else
    dir=$(octmux show-options -qv -t "$s" @opencode_dir 2>/dev/null)
    [ -z "$dir" ] && dir=$(octmux display-message -p -t "$s" '#{pane_current_path}' 2>/dev/null)
    cblock=$(_oc_dir_sessions "$dir")
    kids=$(printf '%s' "$cblock" | tail -n +2)
    if [ -n "$kids" ]; then printf '%s\n' "$s" >>"$_oc_expanded_file"; fi
  fi
  exit 0
}

emit_rows() {
  local now s state at path icon rank ago detail
  local has_active active_title active_ago newest_id newest_title newest_age active_ok
  local guess pstate indpfx cblock kids hdr wcount
  local _wsid wstate wage wtitle wait_detail wait_age
  local tmpd row crank krow sid cstate cage ctitle br total i
  now=$(date +%s)
  _oc_fetch_cache
  tmpd=$(mktemp -d "${_oc_cache_dir}/rows.XXXXXX" 2>/dev/null) || return 0

  # Phase 1: one row per tmux session (resolution order unchanged), plus an
  # expand/collapse indicator and a stashed block of that session's children.
  octmux list-sessions -F '#{session_name}' 2>/dev/null | grep "^${prefix}" | while IFS= read -r s; do
    state=$(octmux show-options -qv -t "$s" @opencode_state 2>/dev/null)
    at=$(octmux show-options -qv -t "$s" @opencode_state_at 2>/dev/null)
    detail=$(octmux show-options -qv -t "$s" @opencode_detail 2>/dev/null)
    path=$(octmux show-options -qv -t "$s" @opencode_dir 2>/dev/null)
    [ -z "$path" ] && path=$(octmux display-message -p -t "$s" '#{pane_current_path}' 2>/dev/null)

    IFS=$'\x1f' read -r has_active active_title active_ago newest_id newest_title newest_age active_ok \
      <<<"$(_oc_api_lookup "$path")"

    # Children drive both the indicator and the waiting state: a pending
    # permission or open question form outranks "running", which a blocked
    # session keeps reporting server-side.
    cblock=$(_oc_dir_sessions "$path")
    kids=$(printf '%s' "$cblock" | tail -n +2)
    hdr=$(printf '%s' "$cblock" | head -n 1)
    wcount=${hdr##*waiting=}; wcount=${wcount%%[^0-9]*}; [ -n "$wcount" ] || wcount=0
    wait_detail=""; wait_age="-"
    if [ "$wcount" -gt 0 ]; then
      IFS=$'\x1f' read -r _wsid wstate wage wtitle <<<"$(printf '%s' "$kids" | head -n 1)"
      if [ "$wstate" = 'waiting' ]; then
        wait_detail="$wtitle"; wait_age="$wage"
        if [ "$wcount" -gt 1 ]; then wait_detail="$wait_detail (+$((wcount - 1)) more)"; fi
      fi
    fi

    if [ -n "$wait_detail" ]; then
      # 1. something here needs the user — a blocked session stays "active"
      # server-side, so waiting must win over running, not the reverse.
      state='waiting'; detail="$wait_detail"; ago="$wait_age"
    elif [ "$has_active" = '1' ]; then
      # 2. opencode server says a session here is running — authoritative.
      # Combine both sources: API title says WHAT runs, fresh plugin detail
      # says what it is doing RIGHT NOW (e.g. "tool edit"); plugin age wins
      # when fresher so busy sessions never show a stale-looking age.
      pstate="$state"
      state='working'; ago="$active_ago"
      if [ "$pstate" = 'working' ] && [ -n "$at" ] && [ "$((now - at))" -lt 600 ]; then
        ago="$(_ago_m "$now" "$at")"
      fi
      if [ -n "$detail" ] && [ -n "$active_title" ] && [ "$detail" != "$active_title" ]; then
        detail="$active_title | $detail"
      else
        detail="$active_title"
      fi
    elif [ "$state" = 'idle' ]; then
      # 3. plugin says idle — trust, but prefer the API session title: it
      # tells WHAT the session is about ("done" is already shown by the icon).
      if [ -n "$newest_title" ]; then detail="$newest_title"; fi
      ago="$(_ago_m "$now" "$at")"
    elif [ "$state" = 'working' ] && [ -n "$at" ] && [ "$((now - at))" -lt 600 ]; then
      # 4. fresh plugin "working" with nothing active (e.g. between steps).
      ago="$(_ago_m "$now" "$at")"
    else
      # 5. newest session -> idle (only when liveness is known — never report
      # a possibly-busy session as idle), else the local plugin stamp, else
      # the live-screen heuristic, else unknown.
      if [ -n "$newest_id" ] && [ "${active_ok:-0}" = '1' ]; then
        state='idle'; detail="$newest_title"; ago="$newest_age"
      elif [ -n "$newest_id" ]; then
        state='?'; detail="$newest_title"; ago="$newest_age"
      elif [ "$state" = 'waiting' ] || [ "$state" = 'idle' ]; then
        ago="$(_ago_m "$now" "$at")"
      else
        # 6. live-screen heuristic; 7. unknown.
        guess=$(_oc_pane_guess "$s")
        if [ -n "$guess" ]; then state="$guess"; [ -z "$detail" ] && detail='live screen'; ago='-'
        else state='?'; ago='-'; fi
      fi
    fi

    case "$state" in
    waiting) rank=0 ;; # needs input - sorts first
    idle)    rank=1 ;; # done, your turn
    working) rank=3 ;; # busy - sorts last
    *)       rank=2 ;; # unknown
    esac
    _oc_icon "$state"
    detail="${detail:-}"

    # Indicator from the already-computed child block (stashed for phase 2).
    if [ -n "$kids" ]; then
      printf '%s\n' "$cblock" >"$tmpd/kids.$s"
      if _oc_is_expanded "$s"; then indpfx='▾ '; else indpfx='▸ '; fi
    else
      indpfx='  '
    fi
    # rank \t session \t indicator+icon \t age \t path \t detail \t type
    # (rank/session/type hidden via --with-nth)
    printf '%s\t%s\t%s%s\t%5s\t%s\t%s\tp\n' \
      "$rank" "$s" "$indpfx" "$icon" "$ago" "${path#"$HOME"/}" "${detail:0:60}" >>"$tmpd/rows"
  done
  [ -f "$tmpd/rows" ] || { rm -rf "$tmpd"; return 0; }

  # Expansion state uses stable tmux names; drop entries for dead sessions so
  # the file never accumulates cruft (per-parent state is otherwise untouched).
  if [ -f "$_oc_expanded_file" ]; then
    octmux list-sessions -F '#{session_name}' 2>/dev/null | grep "^${prefix}" >"$tmpd/live" 2>/dev/null || true
    grep -Fxf "$tmpd/live" "$_oc_expanded_file" >"$tmpd/exp" 2>/dev/null || true
    cat "$tmpd/exp" >"$_oc_expanded_file" 2>/dev/null
  fi

  # Phase 2: parents in rank order, each followed by its children when expanded.
  # Child rows mirror the parent's rank/session (hidden); enter, preview and
  # kill therefore act on the containing tmux session, exactly like the parent.
  sort -t$'\t' -k1,1n -k4,4n "$tmpd/rows" 2>/dev/null | while IFS= read -r row; do
    printf '%s\n' "$row"
    s=$(printf '%s' "$row" | cut -f2)
    crank=$(printf '%s' "$row" | cut -f1)
    if _oc_is_expanded "$s" && [ -f "$tmpd/kids.$s" ]; then
      total=$(tail -n +2 "$tmpd/kids.$s" | wc -l | tr -d ' ')
      i=0
      tail -n +2 "$tmpd/kids.$s" | while IFS= read -r krow; do
        i=$((i + 1))
        if [ "$i" -ge "$total" ]; then br='└'; else br='├'; fi
        IFS=$'\x1f' read -r sid cstate cage ctitle <<<"$krow"
        _oc_icon "$cstate"
        printf '%s\t%s\t  %s %s\t%5s\t\t%s\tc:%s\n' \
          "$crank" "$s" "$br" "$icon" "$cage" "${ctitle:0:60}" "$sid"
      done
    fi
  done
  rm -rf "$tmpd"
}

[ "${1:-}" = '--list' ] && { emit_rows; exit 0; }
[ "${1:-}" = '--toggle' ] && { _oc_toggle "${2:-}"; }

if ! command -v fzf >/dev/null 2>&1; then
  tmux display-message "tmux-opencode-session-manager: fzf is required for the picker"
  exit 0
fi

self="${BASH_SOURCE[0]}"
export FZF_DEFAULT_OPTS=''

# The opencode TUI renders a right-hand sidebar (Context/MCP/LSP) at absolute
# columns near the pane's full width (~161 cols). A raw capture jammed into the
# narrow preview window overlaps that sidebar onto the chat text. To keep the
# preview readable we capture with wrapped lines joined (-J) and then trim each
# line to the left chat column, preserving ANSI colour codes.
[ "${1:-}" = '--preview' ] && {
  tmux -L "$socket" capture-pane -epJt "$2" 2>/dev/null |
    perl -pe '
      my $limit = 112; my $vis = 0; my $out = ""; my $i = 0;
      while ($i < length) {
        my $c = substr($_, $i, 1);
        if ($c eq "\033") {                       # copy full ANSI escape
          my $j = $i + 1;
          $j++ while $j < length && substr($_, $j, 1) !~ /[A-Za-z]/;
          $out .= substr($_, $i, $j - $i + 1); $i = $j + 1; next;
        }
        last if $vis >= $limit;                    # stop at column limit
        $out .= $c; $vis++; $i++;
      }
      $_ = $out . "\033[0m\n";
    '
  exit 0
}

sel=$(emit_rows | fzf --ansi --delimiter='\t' --with-nth=3,4,5,6 \
  --reverse --cycle --header='opencode sessions · tab: expand · enter: jump · ctrl-x: kill' \
  --preview="$self --preview {2}" --preview-window='right,62%,nowrap' \
  --bind="ctrl-x:execute-silent(tmux -L $socket kill-session -t {2})+reload($self --list)" \
  --bind="tab:execute-silent($self --toggle {2})+reload($self --list)")

[ -z "$sel" ] && exit 0
target=$(printf '%s' "$sel" | cut -f2)

# Move the underlying parent (main-server) client to the session's origin window
# (best-effort), then resume the session in a popup over it.
origin=$(octmux show-options -qv -t "$target" @opencode_origin 2>/dev/null)
parent=$(tmux show-options -gqv @opencode_parent 2>/dev/null)
[ -n "$origin" ] && [ -n "$parent" ] &&
  tmux switch-client -c "$parent" -t "$origin" 2>/dev/null

w="$(get_tmux_option @opencode_popup_width '90%')"
h="$(get_tmux_option @opencode_popup_height '90%')"

# We're running INSIDE the picker's own display-popup. Opening another
# display-popup synchronously here races with this popup closing, so tmux
# silently drops it (the client jumps to the origin window but no popup shows).
# Instead, defer: schedule a detached run-shell that waits for this picker popup
# to disappear, then opens the opencode popup cleanly on the parent client.
attach_cmd="tmux -L $socket attach-session -t '=${target}'"
if [ -n "$parent" ]; then
  popup_cmd="tmux display-popup -c '$parent' -w '$w' -h '$h' -E \"$attach_cmd\""
  wait_cmd="tmux display-message -p -t '$parent' '#{client_flags}' 2>/dev/null | grep -q popup"
else
  popup_cmd="tmux display-popup -w '$w' -h '$h' -E \"$attach_cmd\""
  wait_cmd="false"
fi

tmux run-shell -b "
  for _ in \$(seq 1 100); do
    $wait_cmd || break
    sleep 0.02
  done
  $popup_cmd
"
