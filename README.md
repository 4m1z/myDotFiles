# myDotFiles

## Fresh laptop installation

1. Update Framework firmware if appropriate (`fwupdmgr`, or the EFI shell
   bundle from Framework when LVFS has no release for your board yet).
2. Boot the CachyOS installer, select the official **Hyprland + Noctalia**
   desktop, finish installation, reboot.
3. Verify Wi-Fi/audio/basic hardware, then:

```bash
git clone git@github.com:4m1z/myDotFiles.git ~/myDotFiles
cd ~/myDotFiles
./cachyos/install.sh
```

4. Log out and back in to start Zsh as the default shell and apply group
   membership changes (`input`, `docker`).
5. Verify: Noctalia top bar exists, bottom dock does not
   (`SUPER+Space` launcher, `SUPER+X` control center).
6. Verify light/dark: `SUPER+SHIFT+T`, or
   `noctalia msg theme-mode-set dark|light|auto`.
7. Run `./cachyos/tests/test-bootstrap.sh --verify-only`.
8. Work through `cachyos/framework/CHECKLIST.md` on the real hardware.

## What the bootstrap does

`cachyos/install.sh` is idempotent and safe to rerun. Conflicting files
are moved to timestamped `.bak` files, never deleted. Pacman system
changes run **only on CachyOS**; elsewhere the installer does the
portable user-level setup and skips the rest with a message.

| Phase | What |
|---|---|
| packages | `cachyos/packages.sh` via pacman `--needed`: git, gh, curl, jq, ripgrep, fd, fzf, tmux, neovim, zsh, lazygit, wl-clipboard, foot, Chromium (Notes PWA app mode), bluez, Docker stack, kubectl, k9s, lazydocker, base-devel, rust, power-profiles-daemon, thermald, fwupd, fprintd, sof-firmware, and lightweight laptop diagnostics (`dmidecode`, `pciutils`, `usbutils`, `iw`, `v4l-utils`, `libva-utils`, `mpv`, `powertop`). mise via pacman or `mise.run` fallback. Enables on-demand `docker.socket`, `power-profiles-daemon`, and Bluetooth under systemd (thermald on Intel only). |
| user | Oh My Zsh + autosuggestions/syntax-highlighting; links for zsh, nvim, tmux, alacritty, mise (only when absent), `~/.local/bin` helpers; installs Packer + runs one-time `PackerSync` for the tracked Neovim plugin set; `opencode/install.sh` (V2 + plugins); Speedy binary (release tarball, cargo fallback). |
| desktop (CachyOS) | Noctalia hand layer `50-mydotfiles.toml` (dock off, auto theme, alacritty template); Hyprland `personal.lua` (layouts, keys, Notes rules); `binds.lua` patch (Notes on `SUPER+SHIFT+W`, wallpaper menu → `SUPER+SHIFT+B`); theme-state backfill; `hyprctl reload` when in a live session. |
| verify | `cachyos/tests/test-bootstrap.sh --verify-only`. |

The package phase selects Framework 13 Pro Intel or AMD integrated-graphics
firmware/media packages from the CPU vendor; it does not install both stacks.

Flags: `--no-packages`, `--no-desktop`, `--no-verify`.

### Development tools installed automatically

On a fresh CachyOS install, run `./cachyos/install.sh` to install all of:

| Tool | Installation |
|---|---|
| Node.js + npm | mise, current Node.js LTS |
| TypeScript (`tsc`, `tsserver`) | mise npm backend, latest |
| Bun | mise, latest |
| Rust + Cargo | pacman `rust` (includes `rustc` and `cargo`) |
| Go | mise, latest |
| Docker + Compose | pacman `docker` + `docker-compose`; enables `docker.socket` |
| kubectl | pacman `kubectl` |

The installer runs `mise install` after linking `mise/config.toml`, so
configured runtimes are downloaded, including Java and Zig from the base
manifest. An existing mise config is preserved and must declare Node.js,
Bun, Go, and TypeScript (`npm:typescript`); its configured versions are used. Runtime installation errors
stop the installer. `--no-packages` skips both pacman and runtime downloads.

Open a new terminal after installation so zsh activates mise. Log out and
back in once for Docker group membership to take effect. Verify with:

```bash
node --version && npm --version
tsc --version
bun --version
rustc --version && cargo --version
go version
docker --version && docker compose version
kubectl version --client
```

### Shell, terminal workflow, and AI tools

The same `./cachyos/install.sh` command also sets up:

- **Zsh + Oh My Zsh** with `zsh-autosuggestions` and
  `zsh-syntax-highlighting`. Tracked `zsh/.zshrc` and `zsh/.zsh_profile`
  are symlinked into your home directory, including aliases, keybindings,
  mise activation, and the `robbyrussell` theme. On CachyOS, the installer
  changes your account's default login shell to Zsh.
- **tmux**, with its tracked configuration, helpers, and OpenCode session
  manager symlinked into `~/.config/tmux/`.
- **OpenCode V2**, with tracked configs and local plugins symlinked into
  `~/.config/opencode/` (plus configured package plugins).
- **OpenClaw CLI**, installed through the official rootless installer under
  `${XDG_DATA_HOME:-~/.local/share}/openclaw`, with a supported private Node
  runtime and a command symlink at `~/.local/bin/openclaw`.

After logging back in, finish the machine-specific sign-ins and OpenClaw
setup:

```bash
opencode auth login
openclaw onboard --install-daemon
```

OpenClaw's generated account/channel configuration stays machine-local;
there is no tracked OpenClaw configuration to symlink yet. `--no-packages`
also skips changing the login shell.

### Desktop applications

The default installer also installs **Zen Browser** (`zen-browser-bin` from
the CachyOS repository) and **Telegram Desktop** (`telegram-desktop`, the
official native client packaged for Arch). Both are installed through pacman
and appear in the desktop launcher. `--no-packages` skips these installations.

## Desktop

Noctalia is the shell. Native Noctalia provides bar, launcher,
notifications, control center, clipboard, session controls, lock screen,
wallpaper, volume/brightness/media keys, and OSD. No Waybar/rofi/wofi/
mako/swaync/AGS/Quickshell, and **no bottom dock** (`[dock] enabled =
false`; no replacement dock installed).

Keybindings on top of CachyOS defaults:

Notes also appears in the app launcher: **SUPER+Space → type Notes → Enter**.
Its desktop entry launches `mydotfiles-notes`, opening
`https://amirahmadzadeh.com/p/notes` in a standalone Chromium app window,
or focusing the existing Notes window.

| Binding | Action |
|---|---|
| `SUPER+1` … `SUPER+9` | switch directly to workspace 1 … 9 (replaces stock monitor-focus bindings) |
| `SUPER+0` | switch directly to workspace 10 |
| `SUPER+SHIFT+T` | toggle light/dark (free in official binds) |
| `SUPER+SHIFT+I` | focus or launch Speedy (free in official binds) |
| `SUPER+SHIFT+W` | focus or launch Notes PWA, floating 1200x800 (official wallpaper menu moved to `SUPER+SHIFT+B`) |
| `Alt+Shift` | cycle `us,ir,de` layouts |

Workspace shortcuts use the physical number row so they work across all
three keyboard layouts. Workspaces are created when selected; they do not
need to be opened in advance.

## Themes

Personal Hyprland settings live in `cachyos/hypr/`: `input.lua` keeps the
keyboard layouts, and `bindings.lua` keeps workspace shortcuts, Speedy/Notes
bindings, and Notes window rules. The installer
links these modules under `~/.config/hypr/config/mydotfiles/` and loads
them through `personal.lua`.

Native Noctalia palettes: Ayu, Catppuccin, Dracula, Eldritch, Gruvbox,
Kanagawa, Noctalia, Nord, Rosé Pine, Tokyo-Night.

- `mode = "auto"` follows a fixed 07:00/20:00 schedule (no geolocation).
  Manual control always works: `SUPER+SHIFT+T`,
  `noctalia msg theme-mode-set dark|light|auto`,
  `noctalia msg color-scheme-set builtin <name>`.
- The builtin `alacritty` template propagates the theme to the terminal;
  Neovim follows the mode via `nvim/lua/system_theme.lua` (new instances
  automatically through Noctalia mode hooks, running ones with `:SystemTheme`).
- The personal Noctalia layer keeps the bar at the top and adds native
  Bluetooth, brightness, battery, and control-center widgets. It removes
  the official CachyOS sample GPU/RAM sysmon widget group (and lengthens
  GPU polling to 15 seconds) to reduce background activity.

## OpenCode / AI workflow

Preserved and distro-independent: V2 CLI (`~/.opencode/bin/opencode`
first on PATH), tracked `opencode.json`/`opencode.jsonc`, local `rtk`
plugin, `graph-live` + `tmux-session-status` package plugins, and the
tmux popup session manager (`prefix+y` launch, `prefix+u` picker).
No API credentials are needed for tests; auth is interactive per machine:

```bash
opencode --version && opencode plugin list
opencode auth login
gh auth login
```

Secrets live in `~/.config/opencode/secrets.zsh` (see
`opencode/secrets.zsh.example`); nothing secret is committed.

Docker is installed with `docker.socket` enabled on demand. After logging
out/in if `docker` group membership was added, verify with:

```bash
docker run --rm hello-world
docker compose version
```

## Power and performance

Laptop-first: `power-profiles-daemon` (no TLP), thermald on Intel only,
no high-frequency monitoring widgets, no duplicate notification/launcher/
clipboard/shell services, tasteful blur via the stock CachyOS Noctalia
layer rule only.

## Tests

```bash
./cachyos/tests/static.sh                  # syntax + coupling audits
./cachyos/tests/sandbox-test.sh             # isolated user-level 2-run test
./cachyos/tests/test-bootstrap.sh --verify-only
./cachyos/tests/test-bootstrap.sh --docker # clean-room: 2 installs + checks
```

The sandbox does not perform package installation; it isolates `HOME`, runs
the bootstrap twice, installs the real Neovim plugin set and builds Speedy
where needed. The Docker test uses the official CachyOS image and covers
pacman/package integration when Docker is available.

Docker validates packages, symlinks, shells, tmux, Neovim, OpenCode,
mise, Speedy, and idempotency. It cannot validate Hyprland/Noctalia
rendering, dock visuals, Wayland, GPU, portals, or any Framework
hardware — those are covered by `cachyos/framework/CHECKLIST.md`.
No graphical VM test was performed in this migration: `/dev/kvm` exists,
but QEMU/libvirt tooling is not installed and could not be installed without
privileged package access. The first real CachyOS boot should follow the
checklist.

## Repository layout

```text
cachyos/            CachyOS-specific layer (bootstrap, Hyprland/Noctalia
                    overrides, helpers, Docker + static tests, Framework docs)
nvim/ tmux/ zsh/    portable app configs (no CachyOS coupling)
opencode/           distro-independent AI workflow + installer
alacritty/          Noctalia-template-driven terminal config
mise/               base runtime manifest (linked only when absent)
```
