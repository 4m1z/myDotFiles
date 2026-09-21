# OmaBlue

An Omarchy theme built around the classic Windows PowerShell console color:
dark blue `#012456` surfaces with white foreground text, electric-blue
`#73B7FF` accents, and a matching wallpaper set (line-art + aurora glow).

Apply it with:

```sh
omarchy theme set omablue
```

The accompanying Hyprland dotfiles use stock Omarchy window opacity.
Press `Super + Backspace` to toggle the focused window between transparent
and fully opaque.

## Liquid glass (theme-scoped)

`hyprland.lua` enables rounding (14), backdrop blur (14/3, vibrancy 0.2),
shadows (range 40), gaps (5/12), 2px electric-blue/cyan borders, and snappy
popin/fade/slide animations — only while OmaBlue is active.
`shell.{bar,menu,launcher,notifications,popups}.toml` drop those surfaces to
0.72–0.78 alpha so the blur shows through; `shell.lock.toml` + `icons.theme`
(Yaru-blue) finish the look.
The terminal half lives in `~/.config/ghostty/config`
(`background-opacity = 0.7`, global, not tracked in this repo):
the staged theme `ghostty.conf` only carries colors, so per-theme
terminal opacity isn't possible. Revert with `background-opacity = 1.0`.
`04-aurora-glow.jpg` is the hero wallpaper for the frosted effect — the
flat line-art wallpapers mute it by design, so cycle with
`omarchy theme bg next` to compare.
