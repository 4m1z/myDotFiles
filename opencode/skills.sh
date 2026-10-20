#!/usr/bin/env bash
#
# Install (and verify) the agent skills this setup expects in ~/.agents/skills.
#
#   skills.sh            install; idempotent, never aborts the caller
#   skills.sh --verify   check skill files and the browser CLI; exit 1 on failure
#
# The expected set lives in skills/manifest.txt (<skill> <source> per line):
#   - <owner/repo>  installed by the `skills` CLI (the open agent skills
#                    ecosystem); each repo's skills are installed in one call
#   - ui-ux-pro-max installed by the ui-ux-pro-max CLI
#   - vendored      linked from skills/<name>/ in this repo
#
# Try every source; the caller uses --verify to enforce a complete setup.
set -uo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
SKILLS_DIR="$HOME/.agents/skills"
MANIFEST="$REPO_DIR/skills/manifest.txt"
export DISABLE_TELEMETRY=1

log() { printf '[skills] %s\n' "$*"; }
warn() { printf '[skills] WARNING: %s\n' "$*" >&2; }

# Resolve managed runtimes from HOME, not from the caller's project config.
run_node_tool() (
  cd "$HOME" || exit 1
  if command -v npx >/dev/null 2>&1; then
    "$@"
  elif command -v mise >/dev/null 2>&1; then
    mise exec -- "$@"
  else
    warn "Node tools unavailable; install Node or configure Node in mise."
    return 1
  fi
)

skill_present() {
  [[ -f "$SKILLS_DIR/$1/SKILL.md" && -r "$SKILLS_DIR/$1/SKILL.md" && -s "$SKILLS_DIR/$1/SKILL.md" ]]
}

backup_invalid_skill() {
  local target="$SKILLS_DIR/$1" backup root
  [[ -e $target || -L $target ]] || return 0
  root="${XDG_STATE_HOME:-$HOME/.local/state}/mydotfiles/skills-backups"
  mkdir -p -- "$root" || return 1
  backup=$(mktemp -d "$root/$(date +%Y%m%d%H%M%S)-XXXXXX") || return 1
  mv -- "$target" "$backup/$1" || return 1
  log "backed up invalid skill: $target -> $backup/$1"
}

# Manifest rows: "<skill> <source>", comments and blanks ignored.
manifest_rows() {
  sed 's/#.*//' "$MANIFEST" | awk 'NF >= 2 { print $1, $2 }'
}

skill_names() {
  manifest_rows | awk '{ print $1 }'
}

missing_skills() {
  local name names
  names=$(skill_names) || return 1
  while read -r name; do
    [[ -n $name ]] || continue
    skill_present "$name" || printf '%s\n' "$name"
  done <<< "$names"
}

# Vendored skills: preserve usable installed copies, including distro-provided ones.
install_vendored_skills() {
  local dir name target
  for dir in "$REPO_DIR"/skills/*/; do
    [[ -f $dir/SKILL.md ]] || continue
    name=$(basename "${dir%/}")
    target="$SKILLS_DIR/$name"
    if skill_present "$name"; then
      log "present: $target"
      continue
    fi
    backup_invalid_skill "$name" || continue
    ln -s -- "${dir%/}" "$target" || continue
    log "linked: $target -> ${dir%/}"
  done
}

# Ecosystem skills: the `skills` CLI copies them into ~/.agents/skills (the
# agent-standard location every harness reads). One call per repository, and
# only when something from it is missing.
install_ecosystem_skills() {
  local repo names name missing
  for repo in $(manifest_rows | awk '$2 ~ /\// { print $2 }' | sort -u); do
    names=$(manifest_rows | awk -v r="$repo" '$2 == r { print $1 }' | tr '\n' ' ')
    missing=""
    for name in $names; do
      skill_present "$name" || missing="$missing $name"
    done
    if [[ -z $missing ]]; then
      log "present: $repo"
      continue
    fi
    log "installing: $repo ($missing)"
    for name in $missing; do
      backup_invalid_skill "$name" || return 1
    done
    if ! run_node_tool npx -y skills@latest add "$repo" -g -a opencode -s $missing -y; then
      warn "skills CLI failed for $repo; retry: npx skills add $repo -g -a opencode -s $missing"
    fi
  done
}

# Stage the bundle: upstream skips subskills when the main skill already exists.
install_design_skills() (
  local name missing="" staging
  for name in $(manifest_rows | awk '$2 == "ui-ux-pro-max" { print $1 }'); do
    skill_present "$name" || missing="$missing $name"
  done
  [[ -n $missing ]] || return 0
  staging=$(mktemp -d) || return 1
  trap 'rm -rf -- "$staging"' EXIT
  if ! run_node_tool env HOME="$staging" npm_config_cache="${npm_config_cache:-$HOME/.npm}" \
    npx -y ui-ux-pro-max-cli init --ai universal --global; then
    warn "UI/UX Pro Max staging failed; existing skills were preserved."
    return 1
  fi
  for name in $missing; do
    [[ -s "$staging/.agents/skills/$name/SKILL.md" ]] || { warn "bundle missing: $name"; continue; }
    backup_invalid_skill "$name" || return 1
    cp -a -- "$staging/.agents/skills/$name" "$SKILLS_DIR/$name" || return 1
  done
  command -v python3 >/dev/null 2>&1 ||
    warn "the ui-ux-pro-max skill needs Python 3 for its search script."
)

install_playwright() {
  local prefix="${XDG_DATA_HOME:-$HOME/.local/share}/mydotfiles/playwright-cli"
  local target="$HOME/.local/bin/playwright-cli" source
  # Resolve the repo path so a symlinked checkout still compares equal.
  source=$(readlink -f -- "$REPO_DIR/opencode/bin/playwright-cli") || return 1
  if [[ ! -x $prefix/bin/playwright-cli ]]; then
    run_node_tool npm install --global --prefix "$prefix" @playwright/cli@latest || return 1
  fi
  mkdir -p -- "${target%/*}" || return 1
  if [[ -L $target && $(readlink -f -- "$target") == "$source" ]]; then
    return 0
  fi
  if [[ -e $target || -L $target ]]; then
    local backup="$target.bak.$(date +%Y%m%d%H%M%S).$$"
    mv -- "$target" "$backup" || return 1
    log "backed up browser command: $backup"
  fi
  ln -s -- "$source" "$target"
}

verify_playwright() {
  local help
  help=$("$HOME/.local/bin/playwright-cli" --help) || return 1
  grep -Eq '^[[:space:]]*snapshot([[:space:]]|$)' <<< "$help" &&
    grep -Eq '^[[:space:]]*goto[[:space:]]' <<< "$help"
}

verify_skills() {
  local missing
  [[ -r $MANIFEST && -s $MANIFEST ]] || { warn "missing or empty manifest: $MANIFEST"; return 1; }
  missing=$(missing_skills) || return 1
  if [[ -n $missing ]]; then
    printf '%s\n' "$missing" | while read -r name; do
      printf '[skills] missing: %s\n' "$name" >&2
    done
    return 1
  fi
  verify_playwright || { warn "browser CLI unavailable or incompatible; rerun opencode/skills.sh"; return 1; }
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
    install_playwright || warn "Playwright CLI installation failed."
    verify_skills || warn "some skills or tools are missing; see above."
    ;;
  *)
    printf 'Usage: %s [--verify]\n' "$0" >&2
    exit 1
    ;;
esac
