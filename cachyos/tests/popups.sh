#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export POPUP_TEST_DIR="$tmp"
export XDG_RUNTIME_DIR="$tmp"
mkdir "$tmp/bin"
export PATH="$tmp/bin:$PATH"

# Stub the desktop boundary so checks cannot close or launch real apps.
cat >"$tmp/bin/hyprctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  clients) cat "$POPUP_TEST_DIR/clients.json" ;;
  activewindow)
    if [[ -n "${POPUP_REQUEST_ID:-}" ]]; then
      printf 'start %s\n' "$POPUP_REQUEST_ID" >>"$POPUP_TEST_DIR/requests"
      sleep 0.1
    fi
    cat "$POPUP_TEST_DIR/active.json"
    ;;
  activeworkspace)
    # Hiding a window can shift focus to another monitor/workspace.
    if grep -q "workspace='special:" "$POPUP_TEST_DIR/actions"; then
      printf '{"id":7,"name":"7"}\n'
    else
      printf '{"id":2,"name":"2"}\n'
    fi
    ;;
  dispatch)
    [[ "$2" == hl.dsp.* ]] || exit 7
    printf '%s\n' "$*" >>"$POPUP_TEST_DIR/actions"
    if [[ -n "${POPUP_REQUEST_ID:-}" && "$2" == 'hl.dsp.window.center('* ]]; then
      printf 'finish %s\n' "$POPUP_REQUEST_ID" >>"$POPUP_TEST_DIR/requests"
    fi
    ;;
  *) exit 1 ;;
esac
SH
cat >"$tmp/bin/chatgpt" <<'SH'
#!/usr/bin/env bash
[[ $# == 0 ]] || exit 1
printf 'launch chatgpt\n' >>"$POPUP_TEST_DIR/actions"
SH
cat >"$tmp/bin/zen-browser" <<'SH'
#!/usr/bin/env bash
[[ $# == 0 ]] || exit 1
printf 'launch zen-browser\n' >>"$POPUP_TEST_DIR/actions"
SH
cat >"$tmp/bin/uwsm" <<'SH'
#!/usr/bin/env bash
[[ "$1 $2" == 'app --' ]] || exit 1
shift 2
exec "$@"
SH
chmod +x "$tmp/bin/"*

chatgpt='{"address":"0x123","class":"Chatgpt","workspace":{"id":3,"name":"3"},"floating":false,"focusHistoryID":0}'
other='{"address":"0x456","class":"chromium","title":"ChatGPT","workspace":{"id":2,"name":"2"}}'
notes='{"address":"0x789","class":"chrome-amirahmadzadeh.com__p_notes-Default","workspace":{"name":"special:notes"},"floating":true,"focusHistoryID":1}'
browser='{"address":"0xabc","class":"zen","workspace":{"id":3,"name":"3"},"floating":false,"focusHistoryID":2}'
printf '[%s,%s,%s]\n' "$chatgpt" "$other" "$notes" >"$tmp/clients.json"
printf '%s\n' "$chatgpt" >"$tmp/active.json"

run_helper() {
  : >"$tmp/actions"
  bash "$REPO_DIR/cachyos/bin/mydotfiles-popup" "$@"
}
expect_action() {
  grep -Fxq -- "$1" "$tmp/actions" || {
    printf 'Missing action: %s\nActual actions:\n' "$1" >&2
    cat "$tmp/actions" >&2
    exit 1
  }
}

# The existing close entry point must hide ChatGPT, never destroy its state.
: >"$tmp/actions"
bash "$REPO_DIR/cachyos/bin/mydotfiles-notes" --close
expect_action "dispatch hl.dsp.window.move({workspace='special:chatgpt',follow=false,window='address:0x123'})"
[[ $(wc -l <"$tmp/actions") == 1 ]]

# Keyboard close also preserves the browser's live tabs.
printf '%s\n' "$browser" >"$tmp/active.json"
run_helper --close
expect_action "dispatch hl.dsp.window.move({workspace='special:browser',follow=false,window='address:0xabc'})"
[[ $(wc -l <"$tmp/actions") == 1 ]]

# Reuse the desktop app from another workspace, without touching hidden Notes.
printf '%s\n' "$other" >"$tmp/active.json"
run_helper chatgpt
expect_action "dispatch hl.dsp.window.move({workspace=2,follow=false,window='address:0x123'})"
expect_action "dispatch hl.dsp.window.float({action='enable',window='address:0x123'})"
expect_action "dispatch hl.dsp.focus({window='address:0x123'})"
if grep -Eq '^launch |0x789|window.close' "$tmp/actions"; then exit 1; fi

# Pressing the shortcut again hides the focused app.
printf '%s\n' "$chatgpt" >"$tmp/active.json"
run_helper chatgpt
expect_action "dispatch hl.dsp.window.move({workspace='special:chatgpt',follow=false,window='address:0x123'})"
[[ $(wc -l <"$tmp/actions") == 1 ]]

# Restoring the same live window preserves its custom size.
jq '.workspace = {name:"special:chatgpt"} | .floating = true' <<<"$chatgpt" \
  | jq -s . >"$tmp/clients.json"
printf '%s\n' "$other" >"$tmp/active.json"
run_helper chatgpt
expect_action "dispatch hl.dsp.window.move({workspace=2,follow=false,window='address:0x123'})"
expect_action "dispatch hl.dsp.focus({window='address:0x123'})"
if grep -Eq '^launch |window.resize|window.close' "$tmp/actions"; then exit 1; fi

# A similarly titled non-popup app closes normally; an empty workspace is safe.
run_helper --close
expect_action "dispatch hl.dsp.window.close({window='address:0x456'})"
[[ $(wc -l <"$tmp/actions") == 1 ]]
printf '{}\n' >"$tmp/active.json"
run_helper --close
[[ ! -s "$tmp/actions" ]]

# With only Notes running, launch the installed ChatGPT app.
printf '[%s]\n' "$notes" >"$tmp/clients.json"
run_helper chatgpt
expect_action 'launch chatgpt'
[[ $(wc -l <"$tmp/actions") == 1 ]]

# Showing any popup hides the other two before revealing the selected window.
printf '[%s,%s,%s,%s]\n' "$notes" "$chatgpt" "$browser" "$other" \
  | jq 'map(.workspace = {id:3,name:"3"})' >"$tmp/clients.json"
for target in notes chatgpt browser; do
  case "$target" in
    notes) address=0x789; printf '%s\n' "$browser" >"$tmp/active.json" ;;
    chatgpt) address=0x123; printf '%s\n' "$notes" >"$tmp/active.json" ;;
    browser) address=0xabc; printf '%s\n' "$chatgpt" >"$tmp/active.json" ;;
  esac
  run_helper "$target"
  show="dispatch hl.dsp.window.move({workspace=2,follow=false,window='address:$address'})"
  expect_action "$show"
  expect_action "dispatch hl.dsp.focus({window='address:$address'})"
  show_line=$(grep -nFx "$show" "$tmp/actions" | cut -d: -f1)
  for popup in 'notes 0x789' 'chatgpt 0x123' 'browser 0xabc'; do
    read -r name addr <<<"$popup"
    [[ "$name" != "$target" ]] || continue
    hide="dispatch hl.dsp.window.move({workspace='special:$name',follow=false,window='address:$addr'})"
    expect_action "$hide"
    hide_line=$(grep -nFx "$hide" "$tmp/actions" | cut -d: -f1)
    (( hide_line < show_line ))
  done
  if grep -Eq '^launch |window.close|0x456' "$tmp/actions"; then exit 1; fi
done

# Browser toggle hides, and restore keeps the same window and custom size.
printf '[%s]\n' "$browser" >"$tmp/clients.json"
printf '%s\n' "$browser" >"$tmp/active.json"
run_helper browser
expect_action "dispatch hl.dsp.window.move({workspace='special:browser',follow=false,window='address:0xabc'})"
[[ $(wc -l <"$tmp/actions") == 1 ]]
jq '.workspace = {name:"special:browser"} | .floating = true' <<<"$browser" \
  | jq -s . >"$tmp/clients.json"
printf '%s\n' "$other" >"$tmp/active.json"
run_helper browser
expect_action "dispatch hl.dsp.window.move({workspace=2,follow=false,window='address:0xabc'})"
expect_action "dispatch hl.dsp.focus({window='address:0xabc'})"
if grep -Eq '^launch |window.resize|window.close' "$tmp/actions"; then exit 1; fi

# First browser launch hides the currently visible popups too.
printf '[%s,%s]\n' "$notes" "$chatgpt" \
  | jq 'map(.workspace = {id:3,name:"3"})' >"$tmp/clients.json"
run_helper browser
expect_action "dispatch hl.dsp.window.move({workspace='special:notes',follow=false,window='address:0x789'})"
expect_action "dispatch hl.dsp.window.move({workspace='special:chatgpt',follow=false,window='address:0x123'})"
[[ $(tail -n 1 "$tmp/actions") == 'launch zen-browser' ]]
[[ $(wc -l <"$tmp/actions") == 3 ]]

if run_helper unknown >"$tmp/error" 2>&1; then
  printf 'Unknown popup must be rejected\n' >&2
  exit 1
fi
[[ ! -s "$tmp/actions" ]]

# Overlapping hotkeys must finish one switch before the next reads its snapshot.
printf '[%s,%s,%s]\n' "$notes" "$chatgpt" "$browser" >"$tmp/clients.json"
printf '%s\n' "$other" >"$tmp/active.json"
: >"$tmp/actions"
POPUP_REQUEST_ID=notes bash "$REPO_DIR/cachyos/bin/mydotfiles-popup" notes &
first=$!
POPUP_REQUEST_ID=chatgpt bash "$REPO_DIR/cachyos/bin/mydotfiles-popup" chatgpt &
second=$!
wait "$first"
wait "$second"
requests=$(cat "$tmp/requests")
if [[ "$requests" != $'start notes\nfinish notes\nstart chatgpt\nfinish chatgpt' \
   && "$requests" != $'start chatgpt\nfinish chatgpt\nstart notes\nfinish notes' ]]; then
  printf 'Popup requests overlapped:\n%s\n' "$requests" >&2
  exit 1
fi

printf 'Popups: browser/ChatGPT reuse, hide, restore, exclusive switching, close isolation and launch passed\n'
