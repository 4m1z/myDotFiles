# Dotfiles


Tracked configuration:
- `zsh/.zshrc`
- `zsh/.zsh_profile`
- `tmux/.tmux.conf`
- `tmux/tmux-sessionizer`
- `nvim/`
- `alacritty/`
- `foot/foot.ini`
- `opencode/`
- `omarchy/`

## Omarchy setup

`omarchy/install.sh` installs and links these customizations:

- OmaBlue theme and blue-and-white wallpaper set
- [Firouzeh — فیروزه](omarchy/themes/firouzeh/) theme with original Iranian courtyard and geometric wallpapers
- English/Persian keyboard layouts with `Alt + Shift` switching
- Speedy on `Super + Shift + I`
- Apple black cursor theme (`macOS` from AUR `apple_cursor`, hand cursors patched to black via `omarchy/cursors/black_hands.py`)

Run this from an Omarchy desktop session after cloning the repository:

```sh
./omarchy/install.sh
```

To select Firouzeh during installation:

```sh
./omarchy/install.sh firouzeh
```

Both themes are linked by the installer; its default selection is OmaBlue.
After installation, switch to the turquoise-and-indigo Firouzeh theme with
`omarchy theme set firouzeh`. See its [README](omarchy/themes/firouzeh/README.md)
for a theme-only installation, palette and artwork build instructions.

The installer is safe to run again. Existing target files are moved to
timestamped `.bak` files before new symlinks are created. It may ask for your
password while installing the cursor package or adding your user to the
`input` group required by Speedy.

## Neovim ↔ Omarchy theme sync

The custom Neovim config (packer-based, not LazyVim) follows the system-wide
Omarchy theme. `nvim/lua/omarchy.lua` reads the live staged theme at
`~/.local/state/omarchy/current/theme/` on startup (`theme.name`,
`colors.toml`, generated `neovim.lua`) and applies its background mode,
intended colorscheme and palette (terminal colors, foreground, selection).
`nvim/lua/colorscheme.lua` falls back through
`aether → solarized-osaka → tokyonight-night → monochrome`, so any theme works
even when its dedicated Vim colorscheme is not installed.

- New Neovim instances pick up `omarchy theme set <name>` automatically.
- In a running instance, run `:OmarchyTheme` to re-sync without restarting.
- On non-Omarchy machines the module is inert and `monochrome` is used.
- After pulling, run `:PackerSync` once inside Neovim to install
  `bjarneo/aether.nvim` (Omarchy's canonical fallback theme),
  `rebelot/kanagawa.nvim` (sunny `kanagawa-lotus` theme below) and
  `rose-pine/neovim` (dark `tokyo-night` override below).

### Kanagawa Lotus (sunny theme)

The Omarchy theme [`bjarneo/omarchy-kanagawa-lotus-theme`](https://github.com/bjarneo/omarchy-kanagawa-lotus-theme)
is a third-party clone, so Omarchy does not stage its `neovim.lua` — the live
staged theme resolves to the generic `aether` template. Neovim maps the theme
slug back to the author's intent:

- `nvim/lua/plugins.lua` installs `rebelot/kanagawa.nvim`.
- `nvim/lua/kanagawa_conf.lua` configures it (transparent, terminal colors,
  lotus `bg #f1e9d2` to match the Omarchy `colors.toml`).
- `nvim/lua/omarchy.lua` maps theme name `kanagawa-lotus` → colorscheme
  `kanagawa-lotus` (light background), even though staged `neovim.lua` says
  `aether`. Other themes are unaffected (`omablue` still uses `aether`).

So `omarchy theme set kanagawa-lotus` gives you `kanagawa-lotus` in Neovim
automatically; `:OmarchyTheme` re-syncs a running instance.

### Rose Pine (Tokyo Night dark mode)

When the system theme is `tokyo-night` (dark), Neovim uses
[Rosé Pine](https://github.com/rose-pine/neovim) in dark mode instead of
`tokyonight-night`:

- `nvim/lua/plugins.lua` installs `rose-pine/neovim`.
- `nvim/lua/rose_pine_conf.lua` configures it (transparent, terminal colors,
  `variant = "auto"` + `dark_variant = "main"` so dark background picks the
  dark `main` variant).
- `nvim/lua/omarchy.lua` maps theme name `tokyo-night` → colorscheme
  `rose-pine` (dark background), even though staged `neovim.lua` says
  `tokyonight-night`. Other themes are unaffected.

So `omarchy theme set tokyo-night` gives you `rose-pine` (dark `main`) in
Neovim automatically; `:OmarchyTheme` re-syncs a running instance.
