# myDotFiles

CachyOS (Hyprland + Noctalia) dotfiles: a CachyOS bootstrap layer plus
portable zsh / tmux / Neovim / OpenCode configs.

## Install

```bash
git clone git@github.com:4m1z/myDotFiles.git ~/myDotFiles
cd ~/myDotFiles && ./cachyos/install.sh     # --allow-groups for docker/input
```

Log out and back in afterwards: Zsh becomes the login shell and the new
groups apply.

The installer is idempotent: conflicting files move to timestamped `.bak`s,
never deleted. System packages change **only on CachyOS**. Flags:
`--no-packages`, `--no-desktop`, `--allow-groups`.

`--allow-groups` is opt-in because both groups are real privilege
escalation: `docker` is effectively root, `input` is raw keyboard access.
Without the flag the installer prints the exact `usermod` command for
every group that exists on the machine.

## What it installs

- **Packages** (pacman): git, gh, tmux, neovim, zsh, lazygit, foot,
  Chromium, Zen Browser, Telegram, Docker, kubectl/k9s/lazydocker,
  base-devel, rust, tree-sitter-cli, power/thermal/firmware tooling.
- **Runtimes** — mise (Node, TypeScript, Go, Java, Bun, Zig); Rust via
  pacman. An existing mise config is kept.
- **User** — Oh My Zsh, symlinks for zsh/nvim/tmux/opencode,
  Packer + one-time `PackerSync`, OpenCode v2 + plugins, agent skills,
  Speedy, OpenClaw CLI.
- **Desktop** — Noctalia layer `zz-mydotfiles.toml` and the Hyprland
  personal layer in `cachyos/hypr/`. The Noctalia templates theme
  kitty, foot and the GTK/Qt apps from one palette.

## Desktop

Noctalia is the whole shell: bar, launcher, notifications, control center,
clipboard, session, lock, wallpaper, OSD. No Waybar/rofi/wofi/mako/swaync/
AGS/Quickshell, and **no bottom dock**.

| Binding | Action |
|---|---|
| `SUPER+1` … `SUPER+0` | workspace 1 … 10 |
| `SUPER+SHIFT+1` … `SUPER+SHIFT+0` | move the focused window to that workspace |
| `SUPER+CTRL+SHIFT+1` … `+3` | move the focused window to that monitor |
| `SUPER+Return` | foot (light terminal) |
| `SUPER+W` | Zen Browser |
| `SUPER+D` | lazydocker (in foot) |
| `SUPER+K` | k9s (in foot) |
| `SUPER+SHIFT+T` | toggle light/dark |
| `SUPER+SHIFT+L` | back to the English layout |
| `SUPER+SHIFT+I` | focus or launch Speedy |
| `SUPER+SHIFT+W` | focus or launch the tiled Notes PWA |
| `SUPER+-` / `SUPER+=` | resize the focused window (100px, omarchy style) |
| `SUPER+SHIFT+-` / `SUPER+SHIFT+=` | resize its height (100px) |
| `SUPER+ALT+-` / `SUPER+ALT+=` | resize the width (25px) |
| `SUPER+CTRL+-` / `SUPER+CTRL+=` | resize the width (300px) |
| `SUPER+CTRL+ALT+-` / `SUPER+CTRL+ALT+=` | cursor zoom (trackpad pinch default) |
| `Alt+Shift` | cycle `us,ir,de` layouts (Scroll Lock LED shows the active one) |

Workspaces 1-10 always exist (persistent), so `SUPER+1` … `SUPER+0` and
`SUPER+SHIFT+1` … `SUPER+SHIFT+0` work on an empty workspace.

## Themes

Native Noctalia palettes. The mode is **dark**: the theme never switches
to light on its own. A 07:00/20:00 schedule is configured and only
applies if the mode is switched to `auto` by hand. `SUPER+SHIFT+T`
toggles; `noctalia msg theme-mode-set dark|light|auto` and
`noctalia msg color-scheme-set builtin <name>` do the same from the CLI.
Foot follows via the Noctalia template, Neovim via
`nvim/lua/system_theme.lua`: a running instance watches the theme state
file and re-applies on its own, `:SystemTheme` forces a resync.
Neovim picks `monochrome` in dark mode and `github-monochrome-light` in
light mode.

The cursor is `Bibata-Modern-Ice` at 18 px (the theme itself ships with the
CachyOS profile). The installer sets it in the UWSM env (compositor +
XWayland) and in both GTK `settings.ini` files, so all three agree; the
running session is updated with `hyprctl setcursor`, no logout needed.

## OpenCode / AI workflow

V2 CLI, tracked `opencode.json`, package plugins (graph-live,
tmux-session-status, ponytail, superpowers) and the tmux popup session
manager (`prefix+y` launch, `prefix+u` picker, `prefix+b` OpenClaw).
Secrets live in `~/.config/opencode/secrets.zsh` (see the `.example`);
nothing secret is committed. Per-machine auth: `opencode auth login`,
`gh auth login`.

Agent skills live in `~/.agents/skills/`; `skills/manifest.txt` is the
expected list and `opencode/skills.sh --verify` reports what is missing.
Global agent instructions are in `~/.config/opencode/AGENTS.md`.

`opencode/install.sh` restarts the background service at the end, because
the service caches its config and would otherwise ignore a newly declared
plugin. Set `OPENCODE_SKIP_SERVICE_RESTART=1` to skip that — required
when the bootstrap runs inside a session the service itself backs.

## Layout

```text
cachyos/            CachyOS layer (bootstrap, Hyprland/Noctalia overrides)
cachyos/tests/      self-checks (bash cachyos/tests/groups.sh)
nvim/ tmux/ zsh/    portable app configs (no CachyOS coupling)
opencode/           distro-independent AI workflow + installer
skills/             agent skills installed into ~/.agents/skills
mise/               base runtime manifest (linked only when absent)
```

## Compatibility notes

Verified on this workstation (2026-10); re-check after a major upgrade.

- **Hyprland 0.56.2 uses a Lua config** (`hyprland.lua` + `config/*.lua`);
  `package.path` includes `<config>/?.lua`, so `require("config.mydotfiles.input")` resolves.
- **`hl` API**: `hl.window_rule` takes `match`, `float`, `center`, `size`.
  String matching is **RE2 with a full match**, so the title pattern uses
  `(?i)` (supported) and not lookarounds (not supported).
- **Noctalia 5.3.0** deep-merges `~/.config/noctalia/*.toml`, a **later
  filename wins**, and the state-dir `settings.toml` wins over all of them.
- **OpenCode 2.x** merges config files rather than replacing them; the
  current key is `plugins` (`plugin` is deprecated).
- **Node is managed by mise**, so a global `node` binary is not guaranteed.
