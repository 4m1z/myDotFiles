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
- Live status per session — `working` / `waiting` / `done` / `error` / `idle`
  — plus *what* each session is doing (its newest opencode session title /
  current tool).
- Persistent per-agent indicators in **every** tmux status line (bottom-right,
  just left of the hostname): one compact glyph + directory label per agent,
  visible even with all popups closed. A working agent animates its spinner;
  completion and input requests stay visible until you return.
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
4. **opencode API** — newest session in that directory → `done`/`error` (from
   its `outcome`) or `idle` (+ its title). Only completions *newer than the
   current stamp* promote — history never re-fires, and acknowledged
   completions stay acknowledged.
5. **Live pane heuristic** — an `esc interrupt` footer means `working`.
6. `?` only when the server is unreachable *and* the screen is unreadable.
   Silence, a dead server, or a closed popup is never reported as completion.

## Persistent indicators

One indicator per tracked agent (`oc_<hash>` session), rendered by
`scripts/statusline.sh` as a `#(...)` segment prepended to your existing
`status-right` — your content and styling are preserved, and narrow
terminals get at most `@opencode_indicators_max` (default 4) indicators plus
a `+N` overflow count. Labels are the project basename (truncated to 12
chars); two projects sharing a basename show as `parent/base`. While the
`prefix + u` picker popup is open the indicators hide themselves — the
picker already shows every agent's state, so they would only duplicate it.

| State | Glyph | Meaning |
| ----- | ----- | ------- |
| `working` | animated spinner `⠋…⠏` (red) | Actively running |
| `waiting` | `◉ label!` (yellow) | Needs input / permission — outranks running |
| `done` | `✓` (green) | Turn finished, **unacknowledged** — stays until you return |
| `error` | `✖` (red) | Run failed / interrupted — stays until a new task starts |
| `idle` | `○` (dim) | Acknowledged, nothing pending — distinct from `done` |
| unknown | `?` (dim) | No signal yet; never shown as completion |

Tradeoff: tmux has no floating persistent overlay — popups and menus cover
content and vanish on dismissal — so a right-aligned status-line group is the
native always-visible UI. It sits bottom-right, just left of the hostname.

Completion/attention handling:

- Finishing replaces the spinner with `✓` (or `✖` on failure); input
  requests replace it with `◉!`. Neither disappears on its own.
- Opening the agent (`prefix` + `y`) or jumping to it from the picker
  acknowledges *completion only* (`done` → `idle`). `waiting` and `error`
  survive the visit and clear when the next task starts (`working`).
- Starting another prompt flips the indicator back to `working` via the
  status plugin's tool/prompt hooks. Nothing ever switches your session or
  steals focus except an explicit picker selection.
- Removing a tmux session with unacknowledged `done`/`waiting`/`error`
  keeps a `~`-suffixed tombstone indicator for 30 minutes.

How the pieces fit (all state lives in per-session tmux options, keyed by
stable `oc_<hash>` names, so renames, popup reopening, and multiple clients
can't duplicate or misroute agents):

- `opencode/plugins/tmux-status.ts` pushes lifecycle events instantly
  (`working` on tool/prompt/step start, `waiting` on
  `permission.asked`/`question.asked`, `done` on `session.idle`, `error` on
  `session.error`/step failure). It handles both V2 (`payload.properties`)
  and legacy event envelopes.
- `scripts/statusline.sh` renders one cheap `#()` tick: a single
  `list-sessions` read, no API calls, no pane scrapes.
- `scripts/reconcile.sh daemon` polls the opencode API every
  `@opencode_reconcile_every` seconds (default 15) and corrects stamps
  (waiting outranks running; terminal `outcome`s promote only newer
  completions; silence never completes). Single-instance via PID lockfile,
  so config reloads never stack watchers.
- `scripts/ack.sh` records visits. Called by the launcher and the picker.

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

Sessions needing attention (`waiting`, `error`, `done`) sort to the top.

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
| tool run / prompt sent / step / tool / text / shell start      | 🔴 `working` | Busy — leave it        |
| `permission.asked` / `question.asked`                          | 🟡 `waiting` | Needs your input          |
| `session.idle` / `session.status` idle                         | ✅ `done`    | Turn finished — stays until you return |
| `session.error` / step failed                                  | 🔴 `error`   | Run failed — needs attention |
| `session.created` / ack of `done`                              | 🟢 `idle`    | Quiet — your move |

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
    set -g @opencode_indicators_max '4'              # status-line indicators before +N
    set -g @opencode_indicator_idle 'on'             # also show dim idle agents
    set -g @opencode_status_interval '2'             # status tick (spinner); never raises yours
    set -g @opencode_reconcile_every '15'            # watcher poll seconds (min 5)

## Tests

`scripts/tests.sh` covers state transitions (`done`/`error`/`waiting` vs
ack), glyph distinctness and spinner animation, label identity (basename
collisions, truncation), `session_hash` stability, `ack.sh` semantics, and
status-line rendering (overflow, tombstones, dead server) via a stub tmux:

    bash ~/.config/tmux/plugins/tmux-opencode-session-manager/scripts/tests.sh

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
