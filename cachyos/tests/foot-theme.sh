#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
config="$REPO_DIR/cachyos/noctalia/zz-mydotfiles.toml"
template="$REPO_DIR/cachyos/noctalia/templates/terminal-sequences"

grep -Fq '[theme.templates.user.terminal-sequences]' "$config"
grep -Fq 'input_path = "$XDG_CONFIG_HOME/noctalia/templates/terminal-sequences"' "$config"
grep -Fq 'output_path = "~/.cache/noctalia/terminal-sequences"' "$config"
grep -Fq 'post_hook = "bash ~/.cache/noctalia/terminal-sequences | tee /dev/pts/[0-9]*"' "$config"
grep -Fq 'cachyos/noctalia/templates/terminal-sequences' "$REPO_DIR/cachyos/install.sh"
grep -Fq 'font=Comic Shanns Mono:size=12' "$REPO_DIR/cachyos/install.sh"
grep -Fq 'colors.terminal_background.default.hex' "$template"
grep -Fq 'colors.terminal_foreground.default.hex' "$template"
grep -Fq 'colors.terminal_normal_black.default.hex' "$template"
grep -Fq 'colors.terminal_bright_white.default.hex' "$template"

printf 'Foot live-theme template is configured\n'
