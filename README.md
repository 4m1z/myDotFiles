# myDotFiles

CachyOS (Hyprland + Noctalia) dotfiles: a CachyOS bootstrap layer plus
portable zsh / tmux / Neovim / alacritty / OpenCode configs.

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
Without the flag the installer prints the exact `usermod` command.

## What it installs

- **Packages** (pacman): git, gh, tmux, neovim, zsh, lazygit, foot,
  Chromium, Zen Browser, Telegram, Docker, kubectl/k9s/lazydocker,
  base-devel, rust, tree-sitter-cli, power/thermal/firmware tooling.
- **Runtimes** — mise (Node, TypeScript, Go, Java, Bun, Zig); Rust via
  pacman. An existing mise config is kept.
- **User** — Oh My Zsh, symlinks for zsh/nvim/tmux/alacritty/opencode,
  Packer + one-time `PackerSync`, OpenCode v2 + plugins, agent skills,
  Speedy, OpenClaw CLI.
- **Desktop** — Noctalia layer `zz-mydotfiles.toml` and the Hyprland
  personal layer in `cachyos/hypr/`. The Noctalia templates theme
  alacritty, kitty, foot and the GTK/Qt apps from one palette.

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
| `SUPER+D` | lazydocker |
| `SUPER+K` | k9s |
| `SUPER+SHIFT+T` | toggle light/dark |
| `SUPER+SHIFT+L` | back to the English layout |
| `SUPER+SHIFT+I` | focus or launch Speedy |
| `SUPER+SHIFT+W` | focus or launch the Notes PWA (floating 1200x800) |
| `Alt+Shift` | cycle `us,ir,de` layouts |

## Themes

Native Noctalia palettes. The mode is **dark**: the theme never switches
to light on its own. A 07:00/20:00 schedule is configured and only
applies if the mode is switched to `auto` by hand. `SUPER+SHIFT+T`
toggles; `noctalia msg theme-mode-set dark|light|auto` and
`noctalia msg color-scheme-set builtin <name>` do the same from the CLI.
Alacritty follows via the Noctalia template, Neovim via
`nvim/lua/system_theme.lua` (`:SystemTheme` resyncs a running instance).

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
nvim/ tmux/ zsh/    portable app configs (no CachyOS coupling)
opencode/           distro-independent AI workflow + installer
skills/             agent skills installed into ~/.agents/skills
alacritty/          Noctalia-template-driven terminal config
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
- **Noctalia 5.3.0** already ships the alacritty template id, so the
  layer only needs to keep templates enabled.
- **OpenCode 2.x** merges config files rather than replacing them; the
  current key is `plugins` (`plugin` is deprecated).
- **Node is managed by mise**, so a global `node` binary is not guaranteed.
