# OmaBlue

An Omarchy theme built around the classic Windows PowerShell console color:
dark blue `#012456` surfaces with white foreground text and a matching
blue-and-white illustrated wallpaper set.

Apply it with:

```sh
omarchy theme set omablue
```

The accompanying Hyprland dotfiles use stock Omarchy window opacity.
Press `Super + Backspace` to toggle the focused window between transparent
and fully opaque.

## Liquid glass (theme-scoped)

`hyprland.lua` enables rounding (14), backdrop blur (12/3) and shadows —
only while OmaBlue is active. `shell.{bar,menu,launcher,notifications,popups}.toml`
drop those surfaces to 0.82–0.90 alpha so the blur shows through.
The terminal half lives in `~/.config/ghostty/config`
(`background-opacity = 0.7`, global, not tracked in this repo):
the staged theme `ghostty.conf` only carries colors, so per-theme
terminal opacity isn't possible. Revert with `background-opacity = 1.0`.
Note: the OmaBlue wallpaper is nearly flat dark blue, so even at 0.7 the
frosted effect is subtle — opacity, not blur size, is the lever.
