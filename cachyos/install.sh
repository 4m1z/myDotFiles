#!/usr/bin/env bash
#
# CachyOS workstation bootstrap for myDotFiles.
#
# Fresh Framework Laptop 13 Pro procedure:
#   1. Install official CachyOS with the Hyprland + Noctalia desktop profile.
#   2. git clone git@github.com:4m1z/myDotFiles.git ~/myDotFiles
#   3. cd ~/myDotFiles && ./cachyos/install.sh
#
# Idempotent and safe to rerun. Conflicting files are moved to
# timestamped .bak files, never deleted. System (pacman) changes run
# ONLY on CachyOS; on other distros the installer performs the portable
# user-level setup and skips the rest with a clear message.
#
# Flags:
#   --no-packages   skip pacman installs (user + desktop config only)
#   --no-desktop    skip Hyprland/Noctalia desktop overrides
#   --no-verify     skip the final verification pass
#   -h, --help      usage
#
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export REPO_DIR
# shellcheck disable=SC1091
source "$REPO_DIR/cachyos/lib/common.sh"
# shellcheck disable=SC1091
source "$REPO_DIR/cachyos/packages.sh"

DO_PACKAGES=true
DO_DESKTOP=true
DO_VERIFY=true
for arg in "$@"; do
  case "$arg" in
    --no-packages) DO_PACKAGES=false ;;
    --no-desktop) DO_DESKTOP=false ;;
    --no-verify) DO_VERIFY=false ;;
    -h | --help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      printf 'Unknown flag: %s\n' "$arg" >&2
      exit 1
      ;;
  esac
done

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

IS_CACHYOS=false
if is_cachyos; then
  IS_CACHYOS=true
fi
log "Repository: $REPO_DIR"
log "CachyOS detected: $IS_CACHYOS"

# ---------------------------------------------------------------- packages
phase_packages() {
  $DO_PACKAGES || { log "Skipping packages (--no-packages)."; return 0; }
  if ! $IS_CACHYOS; then
    warn "Not CachyOS: skipping pacman system changes (nothing installed)."
    return 0
  fi
  log "Installing pacman packages..."
  pkg_install "${PACKAGES[@]}"

  # Framework Laptop 13 Pro is sold with either Intel Core Ultra Series 3
  # or AMD Ryzen AI 300 integrated graphics. Install only the matching
  # firmware/media/Vulkan stack; never mix vendor drivers.
  if grep -q 'GenuineIntel' /proc/cpuinfo 2>/dev/null; then
    pkg_install linux-firmware-intel intel-media-driver vulkan-intel libvpl vpl-gpu-rt intel-gpu-tools
  elif grep -q 'AuthenticAMD' /proc/cpuinfo 2>/dev/null; then
    pkg_install linux-firmware-amdgpu vulkan-radeon
  fi

  # mise: Arch package when available, upstream installer otherwise.
  if ! command -v mise >/dev/null 2>&1; then
    if ! pkg_install mise; then
      warn "pacman mise unavailable, using upstream installer."
      curl -fsSL https://mise.run | sh
    fi
  fi

  # Docker group + services (systemd only; containers have none).
  if getent group docker >/dev/null 2>&1; then
    if [[ "$(id -u)" -ne 0 ]] && [[ " $(id -nG) " != *" docker "* ]]; then
      as_root usermod -aG docker "$USER" || warn "could not join docker group."
    fi
  fi
  if has_systemd; then
    as_root systemctl enable --now docker.socket >/dev/null 2>&1 \
      || warn "could not enable docker.socket."
    as_root systemctl enable --now power-profiles-daemon.service >/dev/null 2>&1 \
      || warn "could not enable power-profiles-daemon."
    as_root systemctl enable --now bluetooth.service >/dev/null 2>&1 \
      || warn "could not enable bluetooth.service."
    # thermald helps Intel fan behavior; on AMD, power-profiles-daemon
    # owns power management, so thermald stays installed but off.
    if grep -qi 'vendor_id.*GenuineIntel' /proc/cpuinfo 2>/dev/null; then
      as_root systemctl enable --now thermald.service >/dev/null 2>&1 \
        || warn "could not enable thermald."
    fi
  else
    log "No systemd running: skipping service enablement."
  fi
}

# ---------------------------------------------------------------- user env
install_oh_my_zsh() {
  # Derive paths from HOME, never from a possibly stale $ZSH in the env.
  local omz_dir="$HOME/.oh-my-zsh"
  if [[ -d "$omz_dir" ]]; then
    log "Oh My Zsh already installed."
  else
    log "Installing Oh My Zsh..."
    ZSH="$omz_dir" RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
  local custom="$omz_dir/custom/plugins"
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ -d "$custom/$plugin" ]]; then
      log "OMZ plugin already present: $plugin"
    else
      log "Installing OMZ plugin: $plugin"
      git clone --depth=1 "https://github.com/zsh-users/$plugin.git" "$custom/$plugin"
    fi
  done
}

link_portable_configs() {
  log "Linking portable configs..."
  # shell (tracked files live at repo/zsh/)
  link_config "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"
  link_config "$REPO_DIR/zsh/.zsh_profile" "$HOME/.zsh_profile"
  # neovim
  link_config "$REPO_DIR/nvim" "$CONFIG_HOME/nvim"
  # tmux (XDG layout; .tmux.conf references ~/.config/tmux/* paths)
  link_config "$REPO_DIR/tmux/.tmux.conf" "$CONFIG_HOME/tmux/tmux.conf"
  link_config "$REPO_DIR/tmux/tmux-sessionizer" "$CONFIG_HOME/tmux/tmux-sessionizer"
  link_config "$REPO_DIR/tmux/tmux-todo.sh" "$CONFIG_HOME/tmux/tmux-todo.sh"
  link_config "$REPO_DIR/tmux/plugins/tmux-opencode-session-manager" \
    "$CONFIG_HOME/tmux/plugins/tmux-opencode-session-manager"
  # alacritty + Noctalia template placeholder (never overwrite a rendered theme)
  link_config "$REPO_DIR/alacritty/alacritty.toml" "$CONFIG_HOME/alacritty/alacritty.toml"
  mkdir -p -- "$CONFIG_HOME/alacritty/themes"
  if [[ ! -e "$CONFIG_HOME/alacritty/themes/noctalia.toml" ]]; then
    cp -- "$REPO_DIR/alacritty/themes/noctalia-fallback.toml" \
      "$CONFIG_HOME/alacritty/themes/noctalia.toml"
    log "Installed alacritty noctalia.toml placeholder."
  else
    log "Alacritty noctalia.toml already present (template-managed?)."
  fi
  # mise base config: only when the user has none (never clobber).
  if [[ -e "$CONFIG_HOME/mise/config.toml" ]]; then
    log "mise config already present, leaving untouched."
  else
    link_config "$REPO_DIR/mise/config.toml" "$CONFIG_HOME/mise/config.toml"
  fi
  # helper scripts
  mkdir -p -- "$HOME/.local/bin"
  for helper in mydotfiles-speedy mydotfiles-notes mydotfiles-theme-toggle mydotfiles-sync-theme-mode; do
    link_config "$REPO_DIR/cachyos/bin/$helper" "$HOME/.local/bin/$helper"
  done
  # secrets template pointer (real secrets stay in ~/.config/opencode/secrets.zsh)
  if [[ ! -e "$CONFIG_HOME/opencode/secrets.zsh" ]]; then
    log "No opencode secrets file; see opencode/secrets.zsh.example (optional)."
  fi
}

install_nvim_plugins() {
  command -v nvim >/dev/null 2>&1 || {
    warn "Neovim unavailable; skipping Packer setup."
    return 0
  }
  command -v git >/dev/null 2>&1 || {
    warn "git unavailable; cannot install Neovim plugins."
    return 0
  }
  local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
  local packer_dir="$data_home/nvim/site/pack/packer/start/packer.nvim"
  local sync_marker="$STATE_HOME/mydotfiles/nvim-packer-synced"
  if [[ ! -d "$packer_dir" ]]; then
    log "Installing Neovim Packer plugin manager..."
    mkdir -p -- "$(dirname -- "$packer_dir")"
    git clone --depth 1 https://github.com/wbthomason/packer.nvim "$packer_dir"
  fi
  if [[ -f "$sync_marker" ]]; then
    log "Neovim plugin sync already completed; leaving installed plugins untouched."
    return 0
  fi
  log "Installing tracked Neovim plugins (PackerSync; one-time on a fresh account)..."
  mkdir -p -- "$(dirname -- "$sync_marker")"
  if nvim --headless \
    -c 'autocmd User PackerComplete quitall' \
    -c 'PackerSync'; then
    date -u +%Y-%m-%dT%H:%M:%SZ >"$sync_marker"
    log "Neovim PackerSync completed."
  else
    warn "Neovim PackerSync failed; plugins can be retried with :PackerSync."
    return 1
  fi
}

install_speedy() {
  local tmp_dir=""
  local bin=""
  if command -v speedy >/dev/null 2>&1; then
    bin=$(command -v speedy)
  elif [[ -x "$HOME/.local/bin/speedy" ]]; then
    bin="$HOME/.local/bin/speedy"
  elif [[ -x "$HOME/.cargo/bin/speedy" ]]; then
    bin="$HOME/.cargo/bin/speedy"
  fi
  if [[ -n "$bin" ]]; then
    log "Speedy already installed: $bin"
  else
    log "Installing Speedy (https://github.com/4m1z/speedy.git)..."
    tmp_dir=$(mktemp -d)
    local archive="speedy-x86_64-unknown-linux-gnu.tar.gz"
    local release_url="https://github.com/4m1z/speedy/releases/latest/download"
    if [[ "$(uname -m)" == "x86_64" ]] \
      && curl -fsSL "$release_url/$archive" -o "$tmp_dir/$archive" \
      && curl -fsSL "$release_url/$archive.sha256" -o "$tmp_dir/$archive.sha256" \
      && (cd "$tmp_dir" && sha256sum --check "$archive.sha256") \
      && tar -xzf "$tmp_dir/$archive" -C "$tmp_dir"; then
      mkdir -p -- "$HOME/.local/bin"
      install -Dm755 "$tmp_dir/speedy" "$HOME/.local/bin/speedy"
      log "Installed Speedy release binary."
    else
      warn "No Speedy release binary; building from source (needs cargo)."
      if ! command -v cargo >/dev/null 2>&1; then
        warn "cargo missing and packages were skipped; cannot build Speedy."
        rm -rf -- "$tmp_dir"
        return 0
      fi
      mkdir -p -- "$HOME/.local/bin"
      CARGO_NET_RETRY=3 cargo install --locked --git https://github.com/4m1z/speedy.git \
        --root "$HOME/.local" || {
        warn "Speedy source build failed; rerun the installer later."
        rm -rf -- "$tmp_dir"
        return 0
      }
      log "Built Speedy from source."
    fi
    bin="$HOME/.local/bin/speedy"
    rm -rf -- "$tmp_dir"
  fi
  # Keyboard-device access needs the input group (laptop: log out/in after).
  if [[ " $(id -nG) " != *" input "* ]]; then
    if as_root usermod -aG input "$USER" 2>/dev/null; then
      log "Added $USER to input group; log out and back in for Speedy."
    else
      warn "Speedy wants the input group: sudo usermod -aG input $USER"
    fi
  fi
  # Start the background recorder. Best effort: headless containers have
  # no input devices, so a failure here must not fail the bootstrap.
  if "$bin" --start >/dev/null 2>&1; then
    log "Speedy recorder running."
  else
    warn "Speedy recorder did not start (expected in containers); run 'speedy --start' on the laptop."
  fi
}

phase_user() {
  install_oh_my_zsh
  link_portable_configs
  install_nvim_plugins
  log "Setting up OpenCode..."
  "$REPO_DIR/opencode/install.sh"
  install_speedy
}

# ------------------------------------------------------- desktop overrides
patch_hypr_binds() {
  # Move the official wallpaper menu off SUPER+SHIFT+W (Notes takes it) to
  # SUPER+SHIFT+B (free in official binds.lua), idempotently.
  local binds="$CONFIG_HOME/hypr/config/binds.lua"
  [[ -f $binds ]] || { warn "No $binds; skipping binds patch (is the CachyOS profile installed?)."; return 0; }
  if grep -q "myDotFiles: notes-on-W" "$binds"; then
    log "binds.lua already patched (notes-on-W)."
    return 0
  fi
  if ! grep -q 'SHIFT + W.*panel-toggle wallpaper' "$binds"; then
    warn "Official wallpaper binding not found in binds.lua; leaving binds untouched."
    return 0
  fi
  local backup="$binds.bak.$BACKUP_STAMP"
  cp -- "$binds" "$backup"
  log "Backed up binds.lua -> $backup"
  python3 - "$binds" <<'PY'
import sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    text = f.read()
old = 'hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(noctCall .. "panel-toggle wallpaper"))'
assert old in text, "wallpaper binding line changed upstream; patch aborted"
new = ('-- myDotFiles: notes-on-W (installer patch): Notes owns SUPER+SHIFT+W;\n'
       '-- wallpaper menu moved to SUPER+SHIFT+B (was free in official binds).\n'
       'hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd((os.getenv("HOME") or "") .. "/.local/bin/mydotfiles-notes"))\n'
       'hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(noctCall .. "panel-toggle wallpaper"))')
text = text.replace(old, new)
with open(path, "w", encoding="utf-8") as f:
    f.write(text)
print("Patched binds.lua: SUPER+SHIFT+W -> Notes, wallpaper -> SUPER+SHIFT+B")
PY
}

ensure_hypr_personal() {
  local hypr_main="$CONFIG_HOME/hypr/hyprland.lua"
  [[ -f $hypr_main ]] || { warn "No $hypr_main; skipping hypr personal.lua (is the CachyOS profile installed?)."; return 0; }
  link_config "$REPO_DIR/cachyos/hypr/personal.lua" "$CONFIG_HOME/hypr/config/personal.lua"
  local marker='require("config.personal") -- myDotFiles'
  if grep -Fq 'config.personal' "$hypr_main"; then
    log "hyprland.lua already requires config.personal."
    return 0
  fi
  local backup="$hypr_main.bak.$BACKUP_STAMP"
  cp -- "$hypr_main" "$backup"
  log "Backed up hyprland.lua -> $backup"
  printf '%s\n' "$marker" >>"$hypr_main"
  log "hyprland.lua now requires config.personal."
}

phase_desktop() {
  $DO_DESKTOP || { log "Skipping desktop overrides (--no-desktop)."; return 0; }
  if ! $IS_CACHYOS; then
    warn "Not CachyOS: skipping Hyprland/Noctalia overrides."
    return 0
  fi
  log "Installing Hyprland/Noctalia overrides..."
  link_config "$REPO_DIR/cachyos/noctalia/50-mydotfiles.toml" \
    "$CONFIG_HOME/noctalia/50-mydotfiles.toml"
  link_config "$REPO_DIR/cachyos/noctalia/palettes/OmaBlue.json" \
    "$CONFIG_HOME/noctalia/palettes/OmaBlue.json"
  # Persist dock-hidden state too when the shell is already running. This
  # wins over a stale GUI settings override; config.toml remains authoritative
  # on the next fresh start. IPC unavailable before login is expected.
  if command -v noctalia >/dev/null 2>&1; then
    if noctalia msg dock-hide >/dev/null 2>&1; then
      log "Noctalia dock hidden (persisted via IPC)."
    else
      log "No running Noctalia IPC yet; declarative dock=false applies at login."
    fi
  fi
  patch_hypr_binds
  ensure_hypr_personal
  # Backfill the theme state file Neovim reads (toggle helper refreshes it).
  if command -v noctalia >/dev/null 2>&1; then
    local mode
    mode=$(noctalia msg theme-mode-get 2>/dev/null || true)
    if [[ "$mode" == "dark" || "$mode" == "light" ]]; then
      mkdir -p -- "$STATE_HOME/mydotfiles"
      printf 'mode=%s\n' "$mode" >"$STATE_HOME/mydotfiles/theme"
      log "Recorded Noctalia mode: $mode"
    fi
    if command -v noctalia >/dev/null 2>&1; then
      noctalia config validate >/dev/null 2>&1 \
        && log "Noctalia config validates." \
        || warn "noctalia config validate reported issues; check ~/.config/noctalia/."
    fi
  else
    log "noctalia not running/installed here; theme state backfill skipped."
  fi
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload
    config_errors=$(hyprctl configerrors 2>/dev/null || true)
    if [[ -n "$config_errors" ]]; then
      printf 'Hyprland configuration errors:\n%s\n' "$config_errors" >&2
      return 1
    fi
    log "Hyprland reloaded cleanly."
  else
    log "No live Hyprland session; reload skipped (takes effect at login)."
  fi
}

# ------------------------------------------------------------------ verify
phase_verify() {
  $DO_VERIFY || { log "Skipping verification (--no-verify)."; return 0; }
  log "Verifying..."
  "$REPO_DIR/cachyos/tests/test-bootstrap.sh" --verify-only
}

main() {
  phase_packages
  phase_user
  phase_desktop
  phase_verify
  log "Done. Rerun any time: ./cachyos/install.sh"
  if [[ " $(id -nG) " != *" input "* ]] || [[ " $(id -nG) " != *" docker "* ]]; then
    log "If group membership changed (input/docker), log out and back in."
  fi
}

main "$@"
