#!/usr/bin/env bash
# Declarative pacman package set for the CachyOS workstation.
# Source-only: sets the PACKAGES array. The official CachyOS
# Hyprland/Noctalia profile already provides hyprland, noctalia, uwsm,
# kitty, portals, brightnessctl, etc., so those are NOT listed here.
set -euo pipefail

# Portable dev tools (checked against Arch extra names, Oct 2026).
DEV_PACKAGES=(
  git
  github-cli
  curl
  wget
  jq
  ripgrep
  fd
  fzf
  tmux
  neovim
  zsh
  lazygit
  wl-clipboard
  foot
  chromium # Notes PWA --app window (NotesApp WM class) and dev browser
  bluez
  bluez-utils
)

# Containers / k8s.
OPS_PACKAGES=(
  docker
  docker-compose
  kubectl
  k9s
  lazydocker
)

# Build-from-source fallback (Speedy when no release binary exists).
BUILD_PACKAGES=(
  base-devel
  rust
)

# Framework Laptop 13 Pro daily-driver hardware support.
# NOTE: no TLP on purpose. Framework + CachyOS guidance is
# power-profiles-daemon; TLP fights it. thermald is installed but only
# enabled on Intel CPUs (see install.sh).
LAPTOP_PACKAGES=(
  power-profiles-daemon
  thermald
  fwupd
  fprintd
  sof-firmware
  dmidecode
  pciutils
  usbutils
  iw
  v4l-utils
  libva-utils
  mpv
  powertop
)

# shellcheck disable=SC2034 # consumed by cachyos/install.sh after sourcing
PACKAGES=(
  "${DEV_PACKAGES[@]}"
  "${OPS_PACKAGES[@]}"
  "${BUILD_PACKAGES[@]}"
  "${LAPTOP_PACKAGES[@]}"
)
