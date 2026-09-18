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
- Live status per session — `working` / `waiting` / `idle` — plus *what* each
  session is doing (its newest opencode session title / current tool).
- A live preview of each session's screen in the picker.
- Smart jump — selecting a session switches your client to its origin window,
  then resumes it in a popup over it.
- A launcher (`prefix` + `y`) that opens/attaches an opencode session for the
  current directory (resolves the real cwd, including an active nvim's cwd).
- Quick kill (`ctrl-x`) of finished sessions from the picker.

Status never shows `?` without a fight. Resolution order per session:

1. **Question mode** — a child with a pending permission
   (`/api/permission/request`) or open question form (`/api/form`) → `waiting`,
   with what it's waiting on (e.g. `risky change -- edit`). This outranks
   running: a blocked session stays "active" server-side, so liveness alone
   would hide question mode behind `working`.
2. **opencode API** (`/api/session/active`) — authoritative "running" state.
3. **Status plugin** (`@opencode_state`, when fresh) — instant push updates.
   Stale `working` with nothing running is ignored, never stuck.
4. **opencode API** — newest session in that directory → `idle` (+ its title).
5. **Live pane heuristic** — an `esc interrupt` footer means `working`.
6. `?` only when the server is unreachable *and* the screen is unreadable.

## Prerequisites

- tmux >= 3.2 (for `display-popup`)
- [fzf](https://github.com/junegunn/fzf) — the picker UI
- opencode CLI (`opencode` command, **v2**). Status is read from the v2
  background service API, so the service must be running (it starts on demand).
  Note: the binary must be installed and available in `$PATH`.
- bash; macOS or Linux
- `python3` (JSON parsing for the API fallback; the picker degrades
  gracefully without it)

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
| `tab`                | Expand/collapse the row's opencode sessions     |
| `ctrl-x`             | Kill the highlighted session                    |
| `up`/`down`, type    | fzf navigation / filter                         |

Each row is one tmux session (`▸` collapsed, `▾` expanded). `tab` expands it
inline to show every opencode session in that directory as an indented child
(`├`/`└`), each with its own status, age, and title — `enter` on a child jumps
to its containing tmux session, same as the parent. Expansion state is kept per
session and survives list refreshes.

Sessions needing attention (`waiting`, `idle`) sort to the top.

## Status setup (the opencode plugin)

Status is pushed by `opencode/plugins/tmux-status.ts` (symlinked live from
this repo at `~/.config/opencode/plugins/` — no copy step). It is a native
**V2** plugin: V1 hook implementations do not run in V2, and V2 plugins
execute in the background service (outside tmux), so instead of `$TMUX_PANE`
it maps each event's project directory to the tmux session with the same
`oc_<cksum-of-dir>` hash the launcher uses, then stamps the session via
`tmux -L <socket> set-option`:

| opencode event(s)                                              | State        | Meaning                   |
| -------------------------------------------------------------- | ------------ | ------------------------- |
| tool run / prompt sent / `busy` / step / tool / text / shell start | 🔴 `working` | Busy — leave it        |
| `permission.asked` / `form.created`                            | 🟡 `waiting` | Needs your input          |
| `session.idle` / `session.status idle` / run finished          | 🟢 `idle`    | Turn finished — your move |

Tool/permission detail (`tool edit`, `permission ...`) is stored in
`@opencode_detail` and shown as the last picker column. The plugin takes
optional `socket` / `prefix` options (defaults `opencode-popup` / `oc_`).

New plugin files load on `opencode service restart` (`opencode reload` only
re-reads config). The picker does **not** depend on the plugin: without it,
status still resolves through the opencode API and the live-screen fallback.

## Options

Set any of these on your MAIN tmux server before the plugin loads (defaults
shown):

    set -g @opencode_launch_key     'y'              # prefix key: launch/open for current dir
    set -g @opencode_list_key       'u'              # prefix key: open the picker
    set -g @opencode_command        'opencode'      # command run in new sessions
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
