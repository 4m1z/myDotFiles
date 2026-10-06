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

4. Log out and back in if group membership changed (`input`, `docker`).
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
| user | Oh My Zsh + autosuggestions/syntax-highlighting; links for zsh, nvim, tmux, alacritty, mise (only when absent), `~/.local/bin` helpers; installs Packer + runs one-time `PackerSync` for the tracked Neovim plugin set; `opencode/install.sh` (V2 + plugins); Speedy binary (release tarball, cargo fallback); macOS cursor user-locally (`~/.local/share/icons/`). |
| desktop (CachyOS) | Noctalia hand layer `50-mydotfiles.toml` (dock off, auto theme, alacritty template) + optional OmaBlue palette; Hyprland `personal.lua` (layouts, keys, opaque foot, Notes rules); `binds.lua` patch (Notes on `SUPER+SHIFT+W`, wallpaper menu → `SUPER+SHIFT+B`); theme-state backfill; `hyprctl reload` when in a live session. |
| verify | `cachyos/tests/test-bootstrap.sh --verify-only`. |

The package phase selects Framework 13 Pro Intel or AMD integrated-graphics
firmware/media packages from the CPU vendor; it does not install both stacks.

Flags: `--no-packages`, `--no-desktop`, `--no-verify`.

## Desktop

Noctalia is the shell. Native Noctalia provides bar, launcher,
notifications, control center, clipboard, session controls, lock screen,
wallpaper, volume/brightness/media keys, and OSD. No Waybar/rofi/wofi/
mako/swaync/AGS/Quickshell, and **no bottom dock** (`[dock] enabled =
false`; no replacement dock installed).

Keybindings on top of CachyOS defaults:

| Binding | Action |
|---|---|
| `SUPER+SHIFT+T` | toggle light/dark (free in official binds) |
| `SUPER+SHIFT+I` | focus or launch Speedy (free in official binds) |
| `SUPER+SHIFT+W` | focus or launch Notes PWA, floating 1200x800 (official wallpaper menu moved to `SUPER+SHIFT+B`) |
| `Alt+Shift` | cycle `us,ir,de` layouts |

## Themes

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
- **OmaBlue is optional**: `cachyos/noctalia/palettes/OmaBlue.json`
  (dark ported from the legacy theme, light is best-effort). Apply with
  `noctalia msg color-scheme-set custom OmaBlue`. Firouzeh and Godfather
  were intentionally not migrated.

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
omarchy/            LEGACY Omarchy setup (reference only, not used by bootstrap)
```

## Legacy: Omarchy setup (reference only)

The previous workstation ran Omarchy. `omarchy/install.sh` and the
`omarchy/` tree are kept for reference; the CachyOS bootstrap does not
use them, and no runtime config depends on Omarchy anymore:

- `nvim/lua/omarchy.lua` → superseded by `nvim/lua/system_theme.lua`
  (`:OmarchyTheme` remains as an alias of `:SystemTheme`).
- Omarchy bar plugins (`amir.memory`, Speedy/Terminalodo/calendar/GitHub
  widgets) have no Noctalia equivalent and were removed from the active
  path. Speedy itself works standalone via `mydotfiles-speedy`.
- Firouzeh/Godfather themes were not migrated (documented above).
- `alacritty.toml` no longer imports the staged Omarchy theme.
- The cursor patcher script moved to `cachyos/cursors/` (same behavior,
  user-local install).
