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
for plugin in "$dotfiles_dir"/plugins/*.ts; do
  link_config "$plugin" "$config_dir/plugins/${plugin##*/}"
done

ensure_package_plugin() {
  # The current OpenCode config key is `plugin` (singular), and the CLI
  # resolves npm packages lazily when the service starts. Running `plugin
  # add` against a package already listed in config is an error, so only
  # add it when the tracked config does not declare it.
  local spec=$1 id=$2
  if ! grep -Fq -- "$spec" "$dotfiles_dir/opencode.json"; then
    "$opencode_bin" plugin add "$spec"
  fi
  printf 'Configured OpenCode plugin: %s (%s)\n' "$spec" "$id"
}

# Keep in sync with the "plugin" array in opencode.json.
ensure_package_plugin opencode-graph-live@latest graph-live
ensure_package_plugin opencode-tmux-session-status@latest tmux-status
printf 'OpenCode package plugins installed.\n'
