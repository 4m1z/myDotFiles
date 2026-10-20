#!/usr/bin/env bash

set -euo pipefail

dotfiles_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
backup_stamp=$(date +%Y%m%d%H%M%S)
opencode_bin="$HOME/.opencode/bin/opencode"

link_config() {
  local source=$1 target=$2
  mkdir -p -- "$(dirname -- "$target")"
  if [[ -L $target ]] && [[ $(readlink -f -- "$target") == $(readlink -f -- "$source") ]]; then
    return
  fi
  if [[ -e $target || -L $target ]]; then
    mv -- "$target" "$target.bak.$backup_stamp"
    printf 'Backed up: %s\n' "$target"
  fi
  ln -s -- "$source" "$target"
  printf 'Linked: %s -> %s\n' "$target" "$source"
}

if [[ ! -x $opencode_bin ]] || [[ $($opencode_bin --version) != 'opencode v2.'* ]]; then
  # --no-modify-path: our shell rc already exports ~/.opencode/bin, and on
  # this repo ~/.zshrc is a symlink into the checkout (must not be edited).
  curl --retry 5 --retry-all-errors --retry-delay 2 -fsSL \
    https://opencode.ai/v2/install | bash -s -- --no-modify-path
fi

if [[ ! -x $opencode_bin ]] || [[ $($opencode_bin --version) != 'opencode v2.'* ]]; then
  printf 'OpenCode V2 was not installed at %s\n' "$opencode_bin" >&2
  exit 1
fi

link_config "$dotfiles_dir/opencode.json" "$config_dir/opencode.json"
link_config "$dotfiles_dir/opencode.jsonc" "$config_dir/opencode.jsonc"
# Global instructions for the agent (skill map + engineering rules).
link_config "$dotfiles_dir/AGENTS.md" "$config_dir/AGENTS.md"
for plugin in "$dotfiles_dir"/plugins/*.ts; do
  link_config "$plugin" "$config_dir/plugins/${plugin##*/}"
done

# The running service caches the config it started with, so a newly declared
# plugin stays invisible to the plugin manager until it restarts.
"$opencode_bin" service restart >/dev/null 2>&1 || true

# Install skills and their browser tool, then require a usable installation.
bash "$dotfiles_dir/skills.sh"
bash "$dotfiles_dir/skills.sh" --verify

# The config declares the packages (graph-live, tmux-status, ponytail and
# superpowers, which registers the skill set); the service installs them on
# boot. Require their runtime registrations, waiting for that async install.
bash "$dotfiles_dir/verify-plugins.sh" "$opencode_bin"
