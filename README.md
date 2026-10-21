# myDotFiles

CachyOS (Hyprland + Noctalia) dotfiles: a small CachyOS bootstrap layer plus
portable zsh / tmux / Neovim / alacritty / OpenCode configs.

## Install

1. Install CachyOS with the **Hyprland + Noctalia** desktop and reboot.
2. ```bash
   git clone git@github.com:4m1z/myDotFiles.git ~/myDotFiles
   cd ~/myDotFiles && ./cachyos/install.sh
   ```
3. Log out and back in (Zsh becomes the login shell; `input`/`docker` groups apply).
4. `./cachyos/tests/test-bootstrap.sh --verify-only`, then work through
   `cachyos/framework/CHECKLIST.md` on the real hardware.

`cachyos/install.sh` is idempotent: conflicting files move to timestamped
`.bak`s, never deleted. System packages change **only on CachyOS**; elsewhere
it does the portable user-level setup. Flags: `--no-packages`, `--no-desktop`,
`--no-verify`, `--allow-groups`.

`--allow-groups` is required for the two supplementary group memberships the
bootstrap can apply: `docker` (effectively root on this machine) and `input`
(raw keyboard-event access). They are opt-in because both are real privilege
escalation; without the flag the installer prints the exact `usermod` command
instead of running it.

## What it installs

- **Packages** — toolchain + apps via pacman `--needed`: git, gh, tmux, neovim,
  zsh, lazygit, foot, Chromium, Docker stack, kubectl/k9s/lazydocker,
  base-devel, rust, power/thermal/firmware tooling, Zen Browser, Telegram.
  Enables `docker.socket` on demand, `power-profiles-daemon`, Bluetooth.
- **Runtimes** — mise base manifest (Node LTS, Bun, Go, Java, Zig, TypeScript);
  Rust via pacman. An existing mise config is kept.
- **User** — Oh My Zsh (+ autosuggestions/syntax-highlighting), symlinks for
  zsh/nvim/tmux/alacritty/opencode, Packer + one-time `PackerSync`, OpenCode V2
  and plugins, Speedy, OpenClaw CLI, macOS cursor.
- **Agent skills** — `~/.agents/skills/` gets the UI/UX Pro Max bundle, the
  ecosystem skills from the [skills CLI](https://skills.sh) (Vercel frontend,
  Supabase Postgres, marketing/growth, Trail of Bits security, Playwright CLI)
  and the vendored skills in `skills/`; `skills/manifest.txt` is the expected
  list and `opencode/skills.sh --verify` checks it. The
  `supply-chain-risk-auditor` skill runs its scripts with `uv`, installed as
  a package.
- **Desktop** — Noctalia layer `zz-mydotfiles.toml` (dock off, auto theme,
  alacritty template) and Hyprland `personal.lua` / `input.lua` / `bindings.lua`.

The Noctalia layer is named `zz-mydotfiles.toml` on purpose: Noctalia
deep-merges every `~/.config/noctalia/*.toml` and a **later filename wins**.
The CachyOS profile ships `config.toml`, so a layer that sorts before it
(e.g. `50-mydotfiles.toml`) is silently ignored. `cachyos/tests/static.sh`
enforces the ordering.

## Desktop

Noctalia is the whole shell: bar, launcher, notifications, control center,
clipboard, session, lock, wallpaper, OSD. No Waybar/rofi/wofi/mako/swaync/AGS/
Quickshell, and **no bottom dock**.

Keys on top of CachyOS defaults:

| Binding | Action |
|---|---|
| `SUPER+1` … `SUPER+0` | switch to workspace 1 … 10 |
| `SUPER+SHIFT+T` | toggle light/dark |
| `SUPER+SHIFT+I` | focus or launch Speedy |
| `SUPER+SHIFT+W` | focus or launch Notes PWA (floating 1200x800) |
| `Alt+Shift` | cycle `us,ir,de` layouts |

Personal Hyprland settings live in `cachyos/hypr/` and are linked under
`~/.config/hypr/config/mydotfiles/` and loaded via `personal.lua`.

## Themes

Native Noctalia palettes (Ayu, Catppuccin, Dracula, Eldritch, Gruvbox,
Noctalia, Nord, Rosé Pine, Tokyo-Night). `mode = "auto"` follows a
fixed 07:00/20:00 schedule. Manual control: `SUPER+SHIFT+T`,
`noctalia msg theme-mode-set dark|light|auto`,
`noctalia msg color-scheme-set builtin <name>`. The alacritty template
propagates the theme to the terminal; Neovim follows via
`nvim/lua/system_theme.lua` (`:SystemTheme` resyncs a running instance).

## OpenCode / AI workflow

V2 CLI (`~/.opencode/bin` first on PATH), tracked `opencode.json[.jsonc]`,
package plugins (`graph-live`, `tmux-session-status`, `ponytail`, `superpowers`),
and the tmux popup session manager (`prefix+y` launch, `prefix+u` picker).
Secrets live in `~/.config/opencode/secrets.zsh` (see the `.example`); nothing
secret is committed. Per-machine auth: `opencode auth login`, `gh auth login`.

Superpowers ([obra/superpowers](https://github.com/obra/superpowers)) is an
OpenCode plugin: it registers the brainstorming / writing-plans / TDD /
systematic-debugging / code-review skill set and injects the skill bootstrap.
It is declared in the `plugins` array of `opencode/opencode.json` and installed
by `opencode/install.sh`; update it with
`opencode plugin update superpowers@git+https://github.com/obra/superpowers.git`.

Agent skills land in the agent-standard `~/.agents/skills/`: the UI/UX Pro Max
bundle, the ecosystem skills from the [skills CLI](https://skills.sh) (Vercel
frontend, Supabase Postgres, marketing/growth, Trail of Bits security,
Playwright CLI) and the vendored skills in `skills/`. `skills/manifest.txt` is
the expected list, `opencode/skills.sh` installs it and
`opencode/skills.sh --verify` reports what is missing. Refresh the ecosystem
skills with `npx skills update -g`.

Global agent instructions live in `~/.config/opencode/AGENTS.md` (linked from
`opencode/AGENTS.md`): engineering rules and the skill-to-phase map.

`opencode/install.sh` restarts the background service at the end, because the
service caches its config and would otherwise ignore a newly declared plugin.
Set `OPENCODE_SKIP_SERVICE_RESTART=1` to skip that step — required when the
bootstrap runs inside a session the service itself backs, since restarting it
drops that session. The plugins then register on the next service start.

## Tests

```bash
./cachyos/tests/static.sh                    # syntax + coupling audits
./cachyos/tests/sandbox-test.sh              # isolated user-level 2-run test
./cachyos/tests/test-bootstrap.sh --verify-only
./cachyos/tests/test-bootstrap.sh --docker   # clean-room: 2 installs + checks
```

Docker covers packages, symlinks, shells, tmux, Neovim, OpenCode, mise, Speedy,
and idempotency. It cannot cover Hyprland/Noctalia rendering, Wayland, GPU or
Framework hardware — those go through `cachyos/framework/CHECKLIST.md`.

## Layout

```text
cachyos/            CachyOS layer (bootstrap, Hyprland/Noctalia overrides, tests)
nvim/ tmux/ zsh/    portable app configs (no CachyOS coupling)
opencode/           distro-independent AI workflow + installer
skills/             agent skills installed into ~/.agents/skills (manifest + vendored)
alacritty/          Noctalia-template-driven terminal config
mise/               base runtime manifest (linked only when absent)
```
