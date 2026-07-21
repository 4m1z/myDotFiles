export PATH="/home/amir/.local/share/mise/installs/node/24.14.0/bin:$PATH"
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)


source $ZSH/oh-my-zsh.sh


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh



source $HOME/.zsh_profile






alias vi="nvim"
alias vim="nvim"
alias lzg="lazygit"
alias lzd="lazydocker"
alias oc="opencode"
export PATH=$HOME/.local/bin:$PATH




export CC=clang
export CC=clang-14


export TerraformPath=$HOME/work/terraform;


export CC=clang
export CXX=clang++

# Load machine-local secrets if present (API keys live here, never committed).
# e.g. GEMINI_API_KEY, GOOGLE_GENERATIVE_AI_API_KEY, etc.
[ -f "$HOME/.config/opencode/secrets.zsh" ] && source "$HOME/.config/opencode/secrets.zsh"

# opencode
export PATH=/home/amir/.opencode/bin:$PATH

# bun completions
[ -s "/home/amir/.bun/_bun" ] && source "/home/amir/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

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

. "$HOME/.local/share/../bin/env"

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
#
#

