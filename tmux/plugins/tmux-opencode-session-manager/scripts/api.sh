#!/usr/bin/env bash
# Shared opencode-API cache for tmux-opencode-session-manager.
#
# Sourced by picker.sh (interactive rows) and reconcile.sh (background
# watcher) so both resolve status from the same snapshots with the same
# precedence. Has no side effects on source: it only defines variables and
# functions. Callers must source helpers.sh first (for nothing here directly,
# but callers rely on both).
#
# Resolution order per tmux session directory (first hit wins):
#   1. waiting — a child with a pending permission or open question form.
#        Must come first: a blocked session stays "running" server-side, so
#        liveness alone would hide question mode behind "working".
#   2. opencode API active map  -> working (+ newest running session title)
#   3. plugin state, when fresh -> as stamped (+ plugin detail)
#        (stale "working" with nothing active is ignored, not stuck)
#   4. opencode API: newest session in that directory -> done/error/idle
#        from its outcome (+ its title). Terminal outcomes only promote a
#        NEWER completion than the current stamp — history never re-fires.
#   5. live pane heuristic ("esc interrupt" footer) -> working/waiting
#   6. "?" only when nothing at all is known. Silence, a dead server, or a
#      closed popup is NEVER reported as completion.

_oc_cache_dir="${TMPDIR:-/tmp}/opencode-picker-$USER"
_oc_active_file="$_oc_cache_dir/active.json"
_oc_sess_file="$_oc_cache_dir/sessions.json"
_oc_perms_file="$_oc_cache_dir/perms.json"
_oc_forms_file="$_oc_cache_dir/forms.json"
# Expansion state: one tmux session name per line (stable `oc_<hash>` ids).
_oc_expanded_file="$_oc_cache_dir/expanded"
# Tombstones for vanished tmux sessions with unacknowledged terminal states.
_oc_tomb_dir="$_oc_cache_dir/tombs"

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
# has_active | active_title | active_age_m | newest_id | newest_title | newest_age_m | active_ok | newest_outcome | newest_updated_ms
# (\x1f, not tab: bash read collapses empty tab-separated fields.
# active_ok=0 means liveness is unknown: callers must not report idle/done.)
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
nid, nt, na, nout, nupd = "", "", "-", "", 0
if cands:
    n = cands[0]
    nid = n.get("id", "")
    nt = str(n.get("title") or "").replace("\t", " ").replace("\n", " ")[:60]
    na = "%dm" % max(0, int((now - n.get("time", {}).get("updated", now)) / 60000))
    nout = str(n.get("outcome") or "")
    try:
        nupd = int(n.get("time", {}).get("updated", 0) or 0)
    except Exception:
        nupd = 0
print("%d\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%d\x1f%s\x1f%d" % (1 if at else 0, at, aa, nid, nt, na, 1 if active is not None else 0, nout, nupd))
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
order = {"waiting": 0, "working": 1, "error": 1, "done": 2, "idle": 2, "?": 3}
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
        oc = s.get("outcome") or ""
        if oc == "failed":
            st, reason = "error", "run failed"
        elif oc == "interrupted":
            st, reason = "error", "interrupted"
        elif oc:
            st, reason = "done", ""
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
