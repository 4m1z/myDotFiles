# myDotFiles zshrc. Portable: no distro-specific helpers, no secrets.

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

# zstyle ':omz:update' mode reminder

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source "$HOME/.zsh_profile"

alias vi="nvim"
alias vim="nvim"
alias lzg="lazygit"
alias lzd="lazydocker"
alias oc="opencode"
alias kc="kubectl"
export PATH="$HOME/.local/bin:$PATH"

# Single compiler default (clang when present, else system cc).
if command -v clang >/dev/null 2>&1; then
  export CC=clang
  export CXX=clang++
fi

# Load machine-local secrets if present (API keys live here, never committed).
# See opencode/secrets.zsh.example for the expected shape.
[ -f "$HOME/.config/opencode/secrets.zsh" ] && source "$HOME/.config/opencode/secrets.zsh"

# bun
export BUN_INSTALL="$HOME/.bun"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# mise (preferred runtime manager) if installed.
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

# Prefer the V2 CLI installed by opencode/install.sh over older mise versions.
export PATH="$HOME/.opencode/bin:$PATH"

# Ctrl+G to open lazygit
function _lazygit() {
  local saved_buffer="$BUFFER"
  local saved_cursor="$CURSOR"
  BUFFER=""
  zle redisplay
  echoti rmkx 2>/dev/null
  lazygit </dev/tty
  echoti smkx 2>/dev/null
  BUFFER="$saved_buffer"
  CURSOR="$saved_cursor"
  zle reset-prompt
}
zle -N _lazygit
bindkey '^G' _lazygit

# Ctrl+N to open nvim in current directory
function _nvim_dot() {
  local saved_buffer="$BUFFER"
  local saved_cursor="$CURSOR"
  BUFFER=""
  zle redisplay
  echoti rmkx 2>/dev/null
  nvim . </dev/tty
  echoti smkx 2>/dev/null
  BUFFER="$saved_buffer"
  CURSOR="$saved_cursor"
  zle reset-prompt
}
zle -N _nvim_dot
bindkey '^N' _nvim_dot

# Ctrl+K to open k9s
function _k9s() {
  local saved_buffer="$BUFFER"
  local saved_cursor="$CURSOR"
  BUFFER=""
  zle redisplay
  echoti rmkx 2>/dev/null
  k9s </dev/tty
  echoti smkx 2>/dev/null
  BUFFER="$saved_buffer"
  CURSOR="$saved_cursor"
  zle reset-prompt
}
zle -N _k9s
bindkey '^K' _k9s

[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

# ---------------------------------------------------------------------------
# Git worktree helpers
# ---------------------------------------------------------------------------
# Folder name: lowercased ticket id (e.g. ADT-712-fe-foo -> adt-712).
# Falls back to the full lowercased branch name if no ticket pattern is found.
_wt_dirname() {
  local branch="$1"
  # strip any leading "origin/" or other remote prefix
  branch="${branch#*/}"
  local id
  # match a leading <letters>-<digits> ticket id, case-insensitive
  if [[ "$branch" =~ '^[A-Za-z]+-[0-9]+' ]]; then
    id="${(L)MATCH}"
  else
    # sanitize: lowercase + replace anything non-alnum with '-'
    id="${(L)branch//[^a-zA-Z0-9]/-}"
  fi
  print -r -- "$id"
}

# Root of the *main* working tree (so siblings are always relative to it,
# even when you're already inside a worktree).
_wt_main_root() {
  git rev-parse --path-format=absolute --git-common-dir 2>/dev/null \
    | sed 's#/\.git$##'
}

# Optional: files to copy from the main worktree into a new one (untracked,
# not in git). Uncomment and add what you need, e.g. (.env .env.local).
# _WT_COPY_FILES=(.env .env.local)
_wt_postcreate() {
  local dest="$1" src
  src="$(_wt_main_root)"
  [[ -z "${_WT_COPY_FILES+x}" ]] && return 0
  local f
  for f in $_WT_COPY_FILES; do
    [[ -e "$src/$f" && ! -e "$dest/$f" ]] && cp -r "$src/$f" "$dest/$f" \
      && echo "  copied $f"
  done
}

# wt <branch>  -> worktree from an existing branch (local, else origin/<branch>)
wt() {
  if [[ -z "$1" ]]; then echo "usage: wt <branch>"; return 1; fi
  local branch="$1"
  local dir; dir="$(_wt_dirname "$branch")"
  local main; main="$(_wt_main_root)"
  local dest="$main/../$dir"
  if [[ -d "$dest" ]]; then echo "worktree dir already exists: $dest"; cd "$dest"; return; fi

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$dest" "$branch" || return
  elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git worktree add "$dest" -b "$branch" "origin/$branch" || return
  else
    echo "branch '$branch' not found locally or on origin"; return 1
  fi
  _wt_postcreate "$dest"
  cd "$dest"
}

# wtn <branch> [base] -> create a NEW branch + worktree (base defaults to HEAD)
wtn() {
  if [[ -z "$1" ]]; then echo "usage: wtn <new-branch> [base-ref]"; return 1; fi
  local branch="$1" base="${2:-HEAD}"
  local dir; dir="$(_wt_dirname "$branch")"
  local main; main="$(_wt_main_root)"
  local dest="$main/../$dir"
  git worktree add "$dest" -b "$branch" "$base" || return
  _wt_postcreate "$dest"
  cd "$dest"
}

# wl -> list worktrees
wl() { git worktree list; }

# ws -> fuzzy-pick a worktree and cd into it
ws() {
  local sel
  sel=$(git worktree list | fzf --height=40% --reverse \
        --header="switch worktree" ) || return
  cd "${sel%% *}"
}

# wrm -> fuzzy-pick a worktree to remove (skips the current/main one)
wrm() {
  local sel path
  sel=$(git worktree list | fzf --height=40% --reverse \
        --header="remove worktree" ) || return
  path="${sel%% *}"
  if [[ "$path" == "$PWD" ]]; then echo "refusing to remove current worktree"; return 1; fi
  git worktree remove "$path" && echo "removed $path" \
    || echo "use 'git worktree remove --force $path' if it has changes"
}
# ---------------------------------------------------------------------------

# Load Angular CLI autocompletion when Angular CLI is installed.
if command -v ng >/dev/null 2>&1; then
  source <(ng completion script)
fi

# Rust toolchain (single guarded source; rustup shims live in ~/.cargo/bin).
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
