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
