#!/usr/bin/env bash
#
# Install (and verify) the agent skills this setup expects in ~/.agents/skills.
#
#   skills.sh            install; idempotent, never aborts the caller
#   skills.sh --verify   list the missing skills; exit 1 if any are missing
#
# Sources (see skills/README.md):
#   - skills/<name>/ in this repo  -> symlinked into ~/.agents/skills
#   - the UI/UX Pro Max CLI        -> installs the design/UI skills globally
#
# No `set -e`: optional skills must never abort a bootstrap.
set -uo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
SKILLS_DIR="$HOME/.agents/skills"
MANIFEST="$REPO_DIR/skills/manifest.txt"

log() { printf '[skills] %s\n' "$*"; }
warn() { printf '[skills] WARNING: %s\n' "$*" >&2; }

# Expected skill names, one per line.
expected_skills() {
  grep -vE '^[[:space:]]*(#|$)' "$MANIFEST" | sed 's/[[:space:]]//g'
}

# Vendored skills: link the repo copy only when nothing is installed yet, so a
# distro-provided skill is never clobbered.
install_vendored_skills() {
  local dir name target
  for dir in "$REPO_DIR"/skills/*/; do
    [[ -f $dir/SKILL.md ]] || continue
    name=$(basename "${dir%/}")
    target="$SKILLS_DIR/$name"
    if [[ -e $target || -L $target ]]; then
      log "present: $target"
      continue
    fi
    ln -s -- "${dir%/}" "$target"
    log "linked: $target -> ${dir%/}"
  done
}

# Design/UI skills: the UI/UX Pro Max CLI installs them into the
# agent-standard global skills dir. Needs node; mise is the fallback.
install_design_skills() {
  local runner=()
  if command -v npx >/dev/null 2>&1; then
    runner=(npx)
  elif command -v mise >/dev/null 2>&1; then
    runner=(mise exec -- npx)
  else
    warn "npx not found; skipping the UI/UX Pro Max skills (install node or mise)."
    return 0
  fi
  if ! "${runner[@]}" -y ui-ux-pro-max-cli init --ai universal --global --force; then
    warn "UI/UX Pro Max install failed; retry with: npx -y ui-ux-pro-max-cli init --ai universal --global --force"
  fi
  command -v python3 >/dev/null 2>&1 ||
    warn "the ui-ux-pro-max skill needs Python 3 for its search script."
}

verify_skills() {
  local missing=0 name
  while read -r name; do
    [[ -n $name ]] || continue
    if [[ ! -e "$SKILLS_DIR/$name" ]]; then
      printf '[skills] missing: %s\n' "$name" >&2
      missing=1
    fi
  done < <(expected_skills)
  [[ $missing -eq 0 ]]
}

case "${1:-}" in
  --verify)
    verify_skills
    ;;
  "")
    mkdir -p -- "$SKILLS_DIR"
    install_vendored_skills
    install_design_skills
    verify_skills || warn "some skills are missing; see above."
    ;;
  *)
    printf 'Usage: %s [--verify]\n' "$0" >&2
    exit 1
    ;;
esac
