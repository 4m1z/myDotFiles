#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
export REPO_DIR
source "$REPO_DIR/cachyos/lib/common.sh"

# The live config directory can be a symlink into the repo, making source and
# destination the same file. link_config must leave that source untouched.
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/repo/hypr/config" "$tmp/config"
printf 'personal config\n' > "$tmp/repo/hypr/config/personal.lua"
ln -s "$tmp/repo/hypr" "$tmp/config/hypr"
link_config "$tmp/repo/hypr/config/personal.lua" "$tmp/config/hypr/config/personal.lua" >/dev/null
if [[ ! -f "$tmp/repo/hypr/config/personal.lua" || -L "$tmp/repo/hypr/config/personal.lua" ]]; then
  echo 'link_config moved its source when source and destination were the same file' >&2
  exit 1
fi

# hypr/ holds the real personal modules as regular files.
for module in input animations workspaces bindings; do
  [[ -f "$REPO_DIR/hypr/config/personal-$module.lua" && ! -L "$REPO_DIR/hypr/config/personal-$module.lua" ]]
done
[[ -f "$REPO_DIR/hypr/config/personal.lua" && ! -L "$REPO_DIR/hypr/config/personal.lua" ]]

# Installer links from hypr/ directly, no mydotfiles subdir.
grep -Fq '"$REPO_DIR/hypr/config/personal.lua"' "$REPO_DIR/cachyos/install.sh"
grep -Fq '"$REPO_DIR/hypr/config/personal-$module.lua"' "$REPO_DIR/cachyos/install.sh"
! grep -Fq '"$REPO_DIR/cachyos/hypr/' "$REPO_DIR/cachyos/install.sh"
! [[ -d "$REPO_DIR/hypr/config/mydotfiles" ]]

printf 'Hyprland configuration has one source of truth\n'
