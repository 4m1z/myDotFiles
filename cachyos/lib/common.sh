#!/usr/bin/env bash
# Shared helpers for the CachyOS bootstrap. Source-only.
# shellcheck disable=SC2034

# REPO_DIR must be set by the caller before sourcing.
: "${REPO_DIR:?REPO_DIR must be set}"

BACKUP_STAMP="$(date +%Y%m%d%H%M%S%N)"
export BACKUP_STAMP

log() { printf '[myDotFiles] %s\n' "$*"; }
warn() { printf '[myDotFiles:WARN] %s\n' "$*" >&2; }

# True only when /etc/os-release identifies CachyOS. ID_LIKE=arch is not
# enough: this installer must not run CachyOS system operations on plain
# Arch or another Arch-based distribution.
# Test hook: MYDOTFILES_FORCE_CACHYOS=1 pretends to be CachyOS (used by
# cachyos/tests/sandbox-test.sh on non-CachyOS dev machines).
is_cachyos() {
  if [[ "${MYDOTFILES_FORCE_CACHYOS:-0}" == "1" ]]; then
    return 0
  fi
  local id=""
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    id=$(. /etc/os-release 2>/dev/null; printf '%s' "${ID:-}")
  fi
  [[ "$id" == "cachyos" ]]
}

has_systemd() {
  [[ -d /run/systemd/system ]] && command -v systemctl >/dev/null 2>&1
}

# Run a command as root: directly when already root, via sudo otherwise.
as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo -- "$@"
  else
    warn "need root for: $* (no sudo available), skipping"
    return 1
  fi
}

# Idempotent symlink: $1 source, $2 target. Backs up conflicts.
link_config() {
  local source=$1 target=$2
  if [[ ! -e $source && ! -L $source ]]; then
    warn "link source missing, skipping: $source"
    return 1
  fi
  mkdir -p -- "$(dirname -- "$target")"
  if [[ -L $target ]] && [[ $(readlink -f -- "$target") == "$(readlink -f -- "$source")" ]]; then
    log "Already linked: $target"
    return 0
  fi
  if [[ -e $target || -L $target ]]; then
    mv -- "$target" "$target.bak.$BACKUP_STAMP"
    log "Backed up: $target -> $target.bak.$BACKUP_STAMP"
  fi
  ln -s -- "$source" "$target"
  log "Linked: $target -> $source"
}

# Idempotent line append: $1 line, $2 file. Appends only when absent.
ensure_line() {
  local line=$1 file=$2
  mkdir -p -- "$(dirname -- "$file")"
  [[ -f $file ]] || : >"$file"
  grep -Fxq -- "$line" "$file" 2>/dev/null && return 0
  printf '%s\n' "$line" >>"$file"
  log "Added to $file: $line"
}

# Idempotent pacman install. Never fails the bootstrap when a package
# is unavailable; the caller decides whether that is fatal.
pkg_install() {
  local pkgs=("$@")
  if ! command -v pacman >/dev/null 2>&1; then
    warn "pacman not found, cannot install: ${pkgs[*]}"
    return 1
  fi
  as_root pacman -S --needed --noconfirm -- "${pkgs[@]}"
}
