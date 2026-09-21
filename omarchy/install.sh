#!/usr/bin/env bash

set -euo pipefail

dotfiles_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
backup_stamp=$(date +%Y%m%d%H%M%S)
input_group_added=false
idle_screensaver_seconds=3600
idle_lock_seconds=3600
theme=${1:-omablue}

if (( $# > 1 )) || [[ $theme != omablue && $theme != firouzeh ]]; then
  printf 'Usage: %s [omablue|firouzeh]\n' "$0" >&2
  exit 1
fi

link_config() {
  local source=$1
  local target=$2

  mkdir -p -- "$(dirname -- "$target")"

  if [[ -L $target ]] && [[ $(readlink -f -- "$target") == $(readlink -f -- "$source") ]]; then
    printf 'Already linked: %s\n' "$target"
    return
  fi

  if [[ -e $target || -L $target ]]; then
    mv -- "$target" "$target.bak.$backup_stamp"
    printf 'Backed up: %s\n' "$target"
  fi

  ln -s -- "$source" "$target"
  printf 'Linked: %s -> %s\n' "$target" "$source"
}

ensure_shell_idle() {
  local shell_json="$config_home/omarchy/shell.json"
  mkdir -p -- "$(dirname -- "$shell_json")"

  if [[ ! -f $shell_json ]]; then
    local default_json="${OMARCHY_PATH:-/usr/share/omarchy}/config/omarchy/shell.json"
    if [[ -f $default_json ]]; then
      cp -- "$default_json" "$shell_json"
      printf 'Copied default shell config: %s\n' "$shell_json"
    fi
  fi

  # Patch idle timeouts in place, preserving bar layout and other keys
  # (stdlib only, idempotent; backs up only when a change is needed).
  IDLE_SCREENSAVER="$idle_screensaver_seconds" IDLE_LOCK="$idle_lock_seconds" SHELL_JSON="$shell_json" python3 - <<'PY'
import json
import os
import shutil
import time

path = os.environ["SHELL_JSON"]
screensaver = int(os.environ["IDLE_SCREENSAVER"])
lock = int(os.environ["IDLE_LOCK"])

with open(path, encoding="utf-8") as f:
    data = json.load(f)

idle = data.setdefault("idle", {})
if idle.get("screensaver") == screensaver and idle.get("lock") == lock:
    print(f"Idle already set: screensaver={screensaver}s lock={lock}s")
else:
    backup = f"{path}.bak.{time.strftime('%Y%m%d%H%M%S')}"
    shutil.copy2(path, backup)
    print(f"Backed up: {backup}")
    idle["screensaver"] = screensaver
    idle["lock"] = lock
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print(f"Set idle: screensaver={screensaver}s lock={lock}s in {path}")
PY
}

if ! command -v omarchy >/dev/null 2>&1; then
  printf 'This installer requires Omarchy.\n' >&2
  exit 1
fi

if ! pacman -Q apple_cursor >/dev/null 2>&1; then
  omarchy pkg aur add apple_cursor
fi

# Upstream ships white hand cursors in both variants; patch the black
# theme to a black hand like real macOS (idempotent, stdlib only).
for cursor_dir in /usr/share/icons/macOS "$HOME/.icons/macOS" "$HOME/.local/share/icons/macOS"; do
  if [[ -f $cursor_dir/cursors/hand1 ]]; then
    python3 "$dotfiles_dir/cursors/black_hands.py" "$cursor_dir"
  fi
done

if [[ ! -x $HOME/.cargo/bin/speedy ]]; then
  if ! command -v cargo >/dev/null 2>&1; then
    omarchy pkg add rust
  fi
  cargo install --git https://github.com/4m1z/speedy.git
fi

ensure_omarchy_plugin() {
  local id=$1
  local url=$2

  if omarchy plugin list 2>/dev/null | grep -q "$id"; then
    printf 'Plugin already installed: %s\n' "$id"
  else
    omarchy plugin add "$url" --enable
  fi
}

# Third-party bar widgets used with this dotfiles setup (idempotent).
# The GitHub widget additionally needs an authenticated gh CLI and jq.
if ! command -v gh >/dev/null 2>&1; then
  omarchy pkg add github-cli
fi

if ! command -v jq >/dev/null 2>&1; then
  omarchy pkg add jq
fi

ensure_omarchy_plugin "io.github.4m1z.speedy" "https://github.com/4m1z/speedy.git"
ensure_omarchy_plugin "io.github.4m1z.terminalodo" "https://github.com/4m1z/terminalodo.git"
ensure_omarchy_plugin "tmn73.calendar" "https://github.com/tmn73/omarchy-calendar.git"
ensure_omarchy_plugin "robzolkos.github" "https://github.com/robzolkos/omarchy-github.git"

if [[ " $(id -nG) " != *" input "* ]]; then
  sudo usermod -aG input "$USER"
  input_group_added=true
fi

link_config "$dotfiles_dir/hypr/bindings.lua" "$config_home/hypr/bindings.lua"
link_config "$dotfiles_dir/hypr/input.lua" "$config_home/hypr/input.lua"
link_config "$dotfiles_dir/hypr/looknfeel.lua" "$config_home/hypr/looknfeel.lua"
link_config "$dotfiles_dir/themes/omablue" "$config_home/omarchy/themes/omablue"
link_config "$dotfiles_dir/themes/firouzeh" "$config_home/omarchy/themes/firouzeh"
ensure_shell_idle

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface cursor-theme 'macOS'
  gsettings set org.gnome.desktop.interface cursor-size 24
fi

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user set-environment XCURSOR_THEME=macOS XCURSOR_SIZE=24
fi

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  hyprctl reload
  hyprctl setcursor macOS 24

  config_errors=$(hyprctl configerrors)
  if [[ -n $config_errors ]]; then
    printf 'Hyprland configuration errors:\n%s\n' "$config_errors" >&2
    exit 1
  fi
fi

omarchy theme set "$theme"

if [[ $input_group_added == true ]]; then
  printf 'Log out and back in before using Speedy so the input group takes effect.\n'
fi

printf 'Omarchy dotfiles installed. Switch English/Persian with Alt + Shift and launch Speedy with Super + Shift + I.\n'
