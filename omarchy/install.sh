#!/usr/bin/env bash

set -euo pipefail

dotfiles_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
backup_stamp=$(date +%Y%m%d%H%M%S)
input_group_added=false

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

if ! command -v omarchy >/dev/null 2>&1; then
  printf 'This installer requires Omarchy.\n' >&2
  exit 1
fi

if ! pacman -Q nordzy-cursors >/dev/null 2>&1; then
  omarchy pkg aur add nordzy-cursors
fi

if [[ ! -x $HOME/.cargo/bin/speedy ]]; then
  if ! command -v cargo >/dev/null 2>&1; then
    omarchy pkg add rust
  fi
  cargo install --git https://github.com/4m1z/speedy.git
fi

if [[ " $(id -nG) " != *" input "* ]]; then
  sudo usermod -aG input "$USER"
  input_group_added=true
fi

link_config "$dotfiles_dir/hypr/bindings.lua" "$config_home/hypr/bindings.lua"
link_config "$dotfiles_dir/hypr/input.lua" "$config_home/hypr/input.lua"
link_config "$dotfiles_dir/hypr/looknfeel.lua" "$config_home/hypr/looknfeel.lua"
link_config "$dotfiles_dir/themes/omablue" "$config_home/omarchy/themes/omablue"

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface cursor-theme 'Nordzy-cursors-white'
  gsettings set org.gnome.desktop.interface cursor-size 24
fi

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user set-environment XCURSOR_THEME=Nordzy-cursors-white XCURSOR_SIZE=24
fi

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  hyprctl reload
  hyprctl setcursor Nordzy-cursors-white 24

  config_errors=$(hyprctl configerrors)
  if [[ -n $config_errors ]]; then
    printf 'Hyprland configuration errors:\n%s\n' "$config_errors" >&2
    exit 1
  fi
fi

omarchy theme set omablue

if [[ $input_group_added == true ]]; then
  printf 'Log out and back in before using Speedy so the input group takes effect.\n'
fi

printf 'Omarchy dotfiles installed. Switch English/Persian with Alt + Shift and launch Speedy with Super + Shift + I.\n'
