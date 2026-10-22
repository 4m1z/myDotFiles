#!/usr/bin/env bash
# Self-check for setup_cursor and its upsert helpers (cachyos/lib/common.sh):
# the cursor theme must land in the UWSM env file and in both GTK ini files,
# rerunning must not duplicate or drop lines, and a missing theme must be a
# no-op. Runs against a temporary HOME, never the real one.
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
has() { # file needle what
  if grep -qF -- "$2" "$1"; then ok "$3"; else bad "$3" "missing in $1: $2"; fi
}
count_is() { # file needle expected what
  local n
  n=$(grep -cF -- "$2" "$1" || true)
  if [[ "$n" == "$3" ]]; then ok "$4"; else bad "$4" "expected $3 lines, got $n in $1"; fi
}

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home"
export CONFIG_HOME="$tmp/home/.config"
mkdir -p "$HOME/.local/share/icons/Bibata-Modern-Ice" "$CONFIG_HOME/uwsm" "$CONFIG_HOME/gtk-3.0"

# A skel-like UWSM env file and a GTK ini with unrelated settings.
cat >"$CONFIG_HOME/uwsm/env" <<'EOF'
export BROWSER=firefox
export HYPRCURSOR_THEME="Bibata-Modern-Ice"
export HYPRCURSOR_SIZE=24
export XCURSOR_THEME="Bibata-Modern-Ice"
export XCURSOR_SIZE=24
EOF
cat >"$CONFIG_HOME/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=18
EOF

LOG="$tmp/calls.log"
hyprctl() { printf 'hyprctl %s\n' "$*" >>"$LOG"; }
gsettings() { printf 'gsettings %s\n' "$*" >>"$LOG"; }
systemctl() { printf 'systemctl %s\n' "$*" >>"$LOG"; }

# 1. missing theme: warn, change nothing.
out=$(setup_cursor "NoSuchCursorTheme" 24 2>&1)
if [[ "$out" == *"not installed"* ]]; then
  ok "missing theme is reported"
else
  bad "missing theme is reported" "got: $out"
fi
has "$CONFIG_HOME/uwsm/env" 'export HYPRCURSOR_SIZE=24' "missing theme leaves the env file alone"

# 2. real setup.
setup_cursor "Bibata-Modern-Ice" 18 >/dev/null
has "$CONFIG_HOME/uwsm/env" 'export HYPRCURSOR_THEME="Bibata-Modern-Ice"' "env file has the theme"
has "$CONFIG_HOME/uwsm/env" 'export HYPRCURSOR_SIZE="18"' "env file has the size"
has "$CONFIG_HOME/uwsm/env" 'export XCURSOR_THEME="Bibata-Modern-Ice"' "env file has the X11 theme"
has "$CONFIG_HOME/uwsm/env" 'export XCURSOR_SIZE="18"' "env file has the X11 size"
has "$CONFIG_HOME/uwsm/env" 'export BROWSER=firefox' "env file keeps unrelated exports"
has "$CONFIG_HOME/gtk-3.0/settings.ini" 'gtk-cursor-theme-name=Bibata-Modern-Ice' "gtk3 has the theme"
has "$CONFIG_HOME/gtk-3.0/settings.ini" 'gtk-cursor-theme-size=18' "gtk3 has the size"
has "$CONFIG_HOME/gtk-3.0/settings.ini" 'gtk-theme-name=adw-gtk3-dark' "gtk3 keeps unrelated keys"
has "$CONFIG_HOME/gtk-4.0/settings.ini" 'gtk-cursor-theme-name=Bibata-Modern-Ice' "gtk4 file is created"
has "$LOG" 'hyprctl setcursor Bibata-Modern-Ice 18' "compositor cursor is applied"
has "$LOG" 'gsettings set org.gnome.desktop.interface cursor-size 18' "gsettings is updated"

# 3. rerun: idempotent, no duplicate keys.
setup_cursor "Bibata-Modern-Ice" 18 >/dev/null
count_is "$CONFIG_HOME/gtk-3.0/settings.ini" 'gtk-cursor-theme-name=' 1 "gtk3 theme key stays unique"
count_is "$CONFIG_HOME/gtk-3.0/settings.ini" 'gtk-cursor-theme-size=' 1 "gtk3 size key stays unique"
count_is "$CONFIG_HOME/uwsm/env" 'export HYPRCURSOR_SIZE=' 1 "env size line stays unique"
count_is "$CONFIG_HOME/uwsm/env" 'export BROWSER=' 1 "unrelated export is not duplicated"

if [[ "$failures" -eq 0 ]]; then
  printf 'all checks passed\n'
else
  printf '%s check(s) failed\n' "$failures" >&2
  exit 1
fi
