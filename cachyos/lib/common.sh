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
# the tests on non-CachyOS dev machines).
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

# Supplementary group membership: `docker` is effectively root and `input`
# grants raw keyboard access, so both are real privilege escalation and stay
# opt-in ($ALLOW_GROUPS, set by the caller from --allow-groups). When the
# change is skipped the exact usermod command is printed so the user can run
# it later. Groups that do not exist on this machine are ignored: usermod
# would fail on them anyway.
# $1 group, $2 why it is a privilege escalation.
ensure_group() {
  local group="$1" reason="$2" account
  account=$(id -un)
  if [[ " $(id -nG) " == *" $group "* ]]; then
    return 0
  fi
  if ! getent group "$group" >/dev/null 2>&1; then
    return 0
  fi
  if ${ALLOW_GROUPS:-false}; then
    if as_root usermod -aG "$group" "$account"; then
      log "Added $account to the $group group; log out and back in for it to apply."
    else
      warn "could not join the $group group; run: sudo usermod -aG $group \"$account\""
    fi
  else
    log "Skipping '$group' group membership ($reason)."
    log "  Run when you want it: sudo usermod -aG $group \"$account\""
  fi
}

# Upsert "key=value" in an ini-style file: replace the existing line, append
# when absent. The rest of the file is untouched.
set_ini_key() {
  local file="$1" key="$2" value="$3"
  mkdir -p -- "$(dirname -- "$file")"
  [[ -f $file ]] || : >"$file"
  if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$file"; then
    sed -i -E "s|^[[:space:]]*${key}[[:space:]]*=.*$|${key}=${value}|" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >>"$file"
  fi
}

# Upsert "export key=value" in a shell-style env file (value quoted).
set_export() {
  local file="$1" key="$2" value="$3"
  mkdir -p -- "$(dirname -- "$file")"
  [[ -f $file ]] || : >"$file"
  if grep -qE "^[[:space:]]*export[[:space:]]+${key}=" "$file"; then
    sed -i -E "s|^[[:space:]]*export[[:space:]]+${key}=.*$|export ${key}=\"${value}\"|" "$file"
  else
    printf 'export %s="%s"\n' "$key" "$value" >>"$file"
  fi
}

# Cursor theme and size. The theme itself ships with the CachyOS profile
# skel; this makes the compositor, XWayland apps and GTK apps agree on it.
# $1 theme, $2 size in px.
setup_cursor() {
  local theme="${1:-Bibata-Modern-Ice}" size="${2:-18}"
  local config_home="${CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}"
  if ! [[ -d "$HOME/.local/share/icons/$theme" || -d "/usr/share/icons/$theme" ]]; then
    warn "cursor theme '$theme' is not installed; skipping cursor setup."
    return 0
  fi
  # UWSM pins the theme for the compositor and for XWayland apps.
  local uwsm_env="$config_home/uwsm/env"
  if [[ -f $uwsm_env ]]; then
    set_export "$uwsm_env" HYPRCURSOR_THEME "$theme"
    set_export "$uwsm_env" HYPRCURSOR_SIZE "$size"
    set_export "$uwsm_env" XCURSOR_THEME "$theme"
    set_export "$uwsm_env" XCURSOR_SIZE "$size"
  fi
  # GTK apps keep their own copy.
  local ini
  for ini in "$config_home/gtk-3.0/settings.ini" "$config_home/gtk-4.0/settings.ini"; do
    set_ini_key "$ini" gtk-cursor-theme-name "$theme"
    set_ini_key "$ini" gtk-cursor-theme-size "$size"
  done
  # Live session: compositor cursor, GTK default and the user manager env.
  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl setcursor "$theme" "$size" >/dev/null 2>&1 || true
  fi
  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface cursor-theme "$theme" >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface cursor-size "$size" >/dev/null 2>&1 || true
  fi
  export HYPRCURSOR_THEME="$theme" HYPRCURSOR_SIZE="$size"
  export XCURSOR_THEME="$theme" XCURSOR_SIZE="$size"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user import-environment \
      HYPRCURSOR_THEME HYPRCURSOR_SIZE XCURSOR_THEME XCURSOR_SIZE >/dev/null 2>&1 || true
  fi
  log "Cursor theme: $theme (${size}px)."
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

# Idempotent pacman install. Returns pacman's exit status so the CALLER
# decides whether a failure is fatal: the bulk install in
# cachyos/install.sh tolerates it (and warns), while the explicit
# tool/version checks later in the run still fail loudly when something
# essential is missing. Never aborts the bootstrap on its own.
pkg_install() {
  local pkgs=("$@")
  if ! command -v pacman >/dev/null 2>&1; then
    warn "pacman not found, cannot install: ${pkgs[*]}"
    return 1
  fi
  local status=0
  as_root pacman -S --needed --noconfirm -- "${pkgs[@]}" || status=$?
  if [[ "$status" -ne 0 ]]; then
    warn "pacman could not install all of: ${pkgs[*]} (exit $status)"
  fi
  return "$status"
}
