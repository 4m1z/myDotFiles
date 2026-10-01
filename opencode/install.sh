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
  curl -fsSL https://opencode.ai/v2/install | bash
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

"$opencode_bin" plugin update opencode-graph-live@latest
"$opencode_bin" plugin list | grep -Eq '^graph-live[[:space:]]'
printf 'OpenCode graph-live plugin installed.\n'
