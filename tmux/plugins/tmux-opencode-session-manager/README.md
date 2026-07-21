# tmux-opencode-session-manager

Run many [opencode](https://opencode.ai) sessions across your projects, each in
its own tmux popup session — then **list them, see which are done vs. still
working, and jump to one** from a single picker.

Adapted from [craftzdog/tmux-claude-session-manager](https://github.com/craftzdog/tmux-claude-session-manager)
for opencode. Differences:

- Launches `opencode` instead of `claude`.
- Sessions live on a **dedicated tmux server socket** (`opencode-popup` by
  default) so popups stay isolated from your main tmux server.
- Status comes from an **opencode plugin** (opencode has no file-based hooks
  like Claude Code), wired to opencode's event stream.

Features:

- A central picker (`prefix` + `u`) listing every running opencode session.
- Live status per session — `working` / `waiting` / `idle` — driven by the
  opencode status plugin.
- A live preview of each session's screen in the picker.
- Smart jump — selecting a session switches your client to its origin window,
  then resumes it in a popup over it.
- A launcher (`prefix` + `y`) that opens/attaches an opencode session for the
  current directory (resolves the real cwd, including an active nvim's cwd).
- Quick kill (`ctrl-x`) of finished sessions from the picker.

Status is optional: without the plugin the picker still lists, previews, jumps,
and kills — sessions just show `?` instead of a color.

## Prerequisites

- tmux >= 3.2 (for `display-popup`)
- [fzf](https://github.com/junegunn/fzf) — the picker UI
- opencode CLI (the `opencode` command)
- bash; macOS or Linux

## Install

This repo lives at:

    ~/.config/tmux/plugins/tmux-opencode-session-manager

Add to your tmux config (`~/.tmux.conf` or `~/.config/tmux/tmux.conf`), then
reload (`prefix` + `r`):

    run-shell ~/.config/tmux/plugins/tmux-opencode-session-manager/opencode_session_manager.tmux

> Keybinding note: it binds `prefix` + `y` (launch) and `prefix` + `u` (list).
> If your config binds those elsewhere, change the options below, or make sure
> this loads **after** your own bindings so the one you want wins.

## Usage

| Key            | Action                                                              |
| -------------- | ------------------------------------------------------------------- |
| `prefix` + `y` | Launch (or re-attach) an opencode session for the current directory |
| `prefix` + `u` | Open the session picker                                             |

Inside the picker:

| Key                  | Action                                          |
| -------------------- | ----------------------------------------------- |
| `enter`              | Jump to the session (origin window + resume)    |
| `ctrl-x`             | Kill the highlighted session                    |
| `up`/`down`, type    | fzf navigation / filter                         |

Sessions needing attention (`waiting`, `idle`) sort to the top.

## Status setup (the opencode plugin)

Status comes from `~/.config/opencode/plugins/tmux-status.js`, installed
alongside this. It maps opencode events to tmux session state via
`scripts/state.sh`:

| opencode event                              | State          | Meaning                  |
| ------------------------------------------- | -------------- | ------------------------ |
| startup / `message.updated` / `tool.*`      | 🔴 `working`   | Busy — leave it          |
| `permission.asked`                          | 🟡 `waiting`   | Needs permission         |
| `session.idle`                              | 🟢 `idle`      | Turn finished — your move|

opencode loads plugins at startup, so already-running sessions report status on
their next launch once the plugin is present.

## Options

Set any of these on your MAIN tmux server before the plugin loads (defaults
shown):

    set -g @opencode_launch_key     'y'              # prefix key: launch/open for current dir
    set -g @opencode_list_key       'u'              # prefix key: open the picker
    set -g @opencode_command        'opencode'       # command run in new sessions
    set -g @opencode_session_prefix 'oc_'            # tmux session name prefix
    set -g @opencode_socket         'opencode-popup' # dedicated tmux server socket
    set -g @opencode_popup_width    '90%'            # popup width
    set -g @opencode_popup_height   '90%'            # popup height

## How it works

- The **launcher** resolves the current directory (preferring an active nvim's
  cwd), creates a detached `oc_<cksum-of-dir>` session on the dedicated socket
  running `opencode`, records the origin window in `@opencode_origin`, and
  attaches in a popup. The detached session survives closing the popup, so
  state persists per directory.
- The **plugin** sets `@opencode_state` / `@opencode_state_at` on the session as
  opencode works.
- The **picker** lists sessions on the dedicated socket, reads their state and a
  live `capture-pane` preview, and on selection moves your client to the
  session's origin window before resuming it in a popup.
- Pressing `prefix` + `u` **from inside a popup** detaches that popup first, then
  reopens the picker full-size on the outer client.

## License

MIT
