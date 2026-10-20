#!/usr/bin/env bash
#
# Install (and verify) the agent skills this setup expects in ~/.agents/skills.
#
#   skills.sh            install; idempotent, never aborts the caller
#   skills.sh --verify   list the missing skills; exit 1 if any are missing
#
# The expected set lives in skills/manifest.txt (<skill> <source> per line):
#   - <owner/repo>  installed by the `skills` CLI (the open agent skills
#                    ecosystem); each repo's skills are installed in one call
#   - ui-ux-pro-max installed by the ui-ux-pro-max CLI
#   - vendored      linked from skills/<name>/ in this repo
#
# No `set -e`: optional skills must never abort a bootstrap.
set -uo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
SKILLS_DIR="$HOME/.agents/skills"
MANIFEST="$REPO_DIR/skills/manifest.txt"
export DISABLE_TELEMETRY=1

log() { printf '[skills] %s\n' "$*"; }
warn() { printf '[skills] WARNING: %s\n' "$*" >&2; }

# Manifest rows: "<skill> <source>", comments and blanks ignored.
manifest_rows() {
  sed 's/#.*//' "$MANIFEST" | awk 'NF >= 2 { print $1, $2 }'
}

skill_names() {
  manifest_rows | awk '{ print $1 }'
}

missing_skills() {
  local name
  while read -r name; do
    [[ -n $name ]] || continue
    [[ -e "$SKILLS_DIR/$name" ]] || printf '%s\n' "$name"
  done < <(skill_names)
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

# Ecosystem skills: the `skills` CLI copies them into ~/.agents/skills (the
# agent-standard location every harness reads). One call per repository, and
# only when something from it is missing.
install_ecosystem_skills() {
  local repo names missing
  command -v npx >/dev/null 2>&1 || {
    warn "npx not found; skipping the ecosystem skills (install node or mise)."
    return 0
  }
  for repo in $(manifest_rows | awk '$2 ~ /\// { print $2 }' | sort -u); do
    names=$(manifest_rows | awk -v r="$repo" '$2 == r { print $1 }' | tr '\n' ' ')
    missing=""
    for name in $names; do
      [[ -e "$SKILLS_DIR/$name" ]] || missing="$missing $name"
    done
    if [[ -z $missing ]]; then
      log "present: $repo"
      continue
    fi
    log "installing: $repo ($missing)"
    if ! (cd "$HOME" && npx -y skills@latest add "$repo" -g -a opencode -s $names -y); then
      warn "skills CLI failed for $repo; retry: npx skills add $repo -g -a opencode -s $names"
    fi
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
  local missing
  missing=$(missing_skills)
  if [[ -n $missing ]]; then
    printf '%s\n' "$missing" | while read -r name; do
      printf '[skills] missing: %s\n' "$name" >&2
    done
    return 1
  fi
}

case "${1:-}" in
  --verify)
    verify_skills
    ;;
  "")
    mkdir -p -- "$SKILLS_DIR"
    install_vendored_skills
    install_ecosystem_skills
    install_design_skills
    verify_skills || warn "some skills are missing; see above."
    ;;
  *)
    printf 'Usage: %s [--verify]\n' "$0" >&2
    exit 1
    ;;
esac
