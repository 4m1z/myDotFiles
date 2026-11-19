#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export NOTES_TEST_DIR="$tmp"
export XDG_RUNTIME_DIR="$tmp"
mkdir "$tmp/bin"
export PATH="$tmp/bin:$PATH"

# Stub only the desktop boundary: run the real helper and jq without touching
# the user's windows or launching a real browser.
cat >"$tmp/bin/hyprctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  clients) cat "$NOTES_TEST_DIR/clients.json" ;;
  activewindow) cat "$NOTES_TEST_DIR/active.json" ;;
  activeworkspace) printf '{"id":2,"name":"2"}\n' ;;
  dispatch)
    [[ "$2" == hl.dsp.* ]] || { printf 'Lua dispatcher required\n' >&2; exit 7; }
    printf '%s\n' "$*" >>"$NOTES_TEST_DIR/actions"
    ;;
  *) exit 1 ;;
esac
SH
cat >"$tmp/bin/chromium" <<'SH'
#!/usr/bin/env bash
printf 'launch %s\n' "$*" >>"$NOTES_TEST_DIR/actions"
SH
cat >"$tmp/bin/uwsm" <<'SH'
#!/usr/bin/env bash
shift 2
exec "$@"
SH
chmod +x "$tmp/bin/"*

notes='{"address":"0x123","class":"chrome-amirahmadzadeh.com__p_notes-Default","title":"Notes","workspace":{"id":3,"name":"3"},"floating":false,"focusHistoryID":0}'
other='{"address":"0x456","class":"chromium","title":"Notes","workspace":{"id":2,"name":"2"}}'
printf '[%s]\n' "$notes" >"$tmp/clients.json"
printf '%s\n' "$other" >"$tmp/active.json"

run_helper() {
  : >"$tmp/actions"
  bash "$REPO_DIR/cachyos/bin/mydotfiles-notes" "$@"
}
expect_action() {
  grep -Fxq -- "$1" "$tmp/actions" || {
    printf 'Missing action: %s\nActual actions:\n' "$1" >&2
    cat "$tmp/actions" >&2
    exit 1
  }
}

# The native Wayland app ID must reuse the existing window, not launch another.
run_helper
expect_action "dispatch hl.dsp.window.move({workspace=2,follow=false,window='address:0x123'})"
expect_action "dispatch hl.dsp.window.float({action='enable',window='address:0x123'})"
expect_action "dispatch hl.dsp.focus({window='address:0x123'})"
if grep -q '^launch ' "$tmp/actions"; then exit 1; fi

# Pressing the shortcut again hides the focused window without closing it.
printf '%s\n' "$notes" >"$tmp/active.json"
run_helper
expect_action "dispatch hl.dsp.window.move({workspace='special:notes',follow=false,window='address:0x123'})"
[[ $(wc -l <"$tmp/actions") == 1 ]]

# Keyboard close also hides Notes, including the older custom app class.
for class in chrome-amirahmadzadeh.com__p_notes-Default NotesApp; do
  jq --arg cls "$class" '.class = $cls' <<<"$notes" >"$tmp/active.json"
  run_helper --close
  expect_action "dispatch hl.dsp.window.move({workspace='special:notes',follow=false,window='address:0x123'})"
  [[ $(wc -l <"$tmp/actions") == 1 ]]
done

# Reopening a hidden popup keeps its size/state and doesn't relaunch it.
jq '.workspace = {id:-99,name:"special:notes"} | .floating = true' <<<"$notes" \
  | jq -s . >"$tmp/clients.json"
printf '%s\n' "$other" >"$tmp/active.json"
run_helper
expect_action "dispatch hl.dsp.window.move({workspace=2,follow=false,window='address:0x123'})"
expect_action "dispatch hl.dsp.focus({window='address:0x123'})"
if grep -Eq 'launch |window.resize' "$tmp/actions"; then exit 1; fi

# A non-popup browser tab named Notes must still close normally.
run_helper --close
expect_action "dispatch hl.dsp.window.close({window='address:0x456'})"
[[ $(wc -l <"$tmp/actions") == 1 ]]

# No active window: close is a no-op, not a launch or an untargeted close.
printf '{}\n' >"$tmp/active.json"
run_helper --close
[[ ! -s "$tmp/actions" ]]

# No existing Notes window: keep the normal PWA launch path.
printf '[]\n' >"$tmp/clients.json"
run_helper
expect_action 'launch --app=https://amirahmadzadeh.com/p/notes --class=NotesApp --name=NotesApp'

printf 'Notes popup: reuse, float, hide, restore, close isolation and launch passed\n'
