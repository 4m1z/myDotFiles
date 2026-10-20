#!/usr/bin/env bash
# Check runtime registrations, not just declarations in opencode.json.
# A freshly started service installs and registers plugins asynchronously, so
# poll until they appear instead of failing on the first empty response.
set -euo pipefail

opencode_bin=${1:-$HOME/.opencode/bin/opencode}
wait_seconds=${PLUGIN_WAIT_SECONDS:-300}
interval=${PLUGIN_POLL_INTERVAL:-2}
ids=(graph-live tmux-status ponytail superpowers)

deadline=$((SECONDS + wait_seconds))
while :; do
  plugins=$(cd "$HOME" && "$opencode_bin" plugin list 2>/dev/null) || plugins=""
  missing=()
  for id in "${ids[@]}"; do
    awk -v id="$id" '$1 == id { found = 1 } END { exit !found }' <<< "$plugins" ||
      missing+=("$id")
  done
  [[ ${#missing[@]} -eq 0 ]] && break
  if ((SECONDS >= deadline)); then
    for id in "${missing[@]}"; do
      printf 'OpenCode plugin did not load: %s\n' "$id" >&2
    done
    printf 'Retry: %s plugin list  (or opencode plugin update)\n' "$opencode_bin" >&2
    exit 1
  fi
  sleep "$interval"
done

for id in "${ids[@]}"; do
  printf 'Loaded OpenCode plugin: %s\n' "$id"
done
