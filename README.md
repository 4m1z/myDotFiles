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
- English/Persian keyboard layouts with `Alt + Shift` switching
- Speedy on `Super + Shift + I`
- Nordzy white-and-blue cursor theme

Run this from an Omarchy desktop session after cloning the repository:

```sh
./omarchy/install.sh
```

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
  `bjarneo/aether.nvim` (Omarchy's canonical fallback theme).
