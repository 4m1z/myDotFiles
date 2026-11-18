#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export POPUP_TEST_DIR="$tmp"
mkdir "$tmp/bin"
export PATH="$tmp/bin:$PATH"

# Stub the desktop boundary so checks cannot close or launch real apps.
cat >"$tmp/bin/hyprctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  clients) cat "$POPUP_TEST_DIR/clients.json" ;;
  activewindow) cat "$POPUP_TEST_DIR/active.json" ;;
  activeworkspace) printf '{"id":2,"name":"2"}\n' ;;
  dispatch)
    [[ "$2" == hl.dsp.* ]] || exit 7
    printf '%s\n' "$*" >>"$POPUP_TEST_DIR/actions"
    ;;
  *) exit 1 ;;
esac
SH
cat >"$tmp/bin/chatgpt" <<'SH'
#!/usr/bin/env bash
[[ $# == 0 ]] || exit 1
printf 'launch chatgpt\n' >>"$POPUP_TEST_DIR/actions"
SH
cat >"$tmp/bin/uwsm" <<'SH'
#!/usr/bin/env bash
[[ "$1 $2" == 'app --' ]] || exit 1
shift 2
exec "$@"
SH
chmod +x "$tmp/bin/"*

chatgpt='{"address":"0x123","class":"Chatgpt","workspace":{"id":3,"name":"3"},"floating":false,"focusHistoryID":0}'
other='{"address":"0x456","class":"zen","title":"ChatGPT","workspace":{"id":2,"name":"2"}}'
notes='{"address":"0x789","class":"chrome-amirahmadzadeh.com__p_notes-Default","workspace":{"name":"special:notes"},"floating":true,"focusHistoryID":1}'
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

# Reuse the desktop app from another workspace, without touching Notes.
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

# A similarly titled browser still closes normally; an empty workspace is safe.
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

if run_helper unknown >"$tmp/error" 2>&1; then
  printf 'Unknown popup must be rejected\n' >&2
  exit 1
fi
[[ ! -s "$tmp/actions" ]]

printf 'ChatGPT popup: reuse, float, hide, restore, close isolation and launch passed\n'
