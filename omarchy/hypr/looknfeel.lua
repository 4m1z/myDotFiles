-- Apple black pointer (macOS, black base with white outline).
hl.env("XCURSOR_THEME", "macOS")
hl.env("XCURSOR_SIZE", "24")

-- Frosted glass for the system UI (bar, popups, menus, notifications).
-- This is theme-independent: translucent shell surfaces need a real
-- backdrop blur, otherwise windows behind them bleed through sharp and
-- text becomes unreadable (e.g. the calendar flyout over a terminal).
hl.config({
  decoration = {
    blur = {
      enabled = true,
      size = 12,
      passes = 3,
      vibrancy = 0.3,
      vibrancy_darkness = 0.5,
      ignore_opacity = true,
      new_optimizations = true,
      -- Blur layer-shell popups (calendar etc.) anchored to the bar.
      popups = true,
      popups_ignorealpha = 0.35,
      input_methods = true,
      input_methods_ignorealpha = 0.4,
    },
  },
})

-- Opaque terminals for readability: opt out of Omarchy's default
-- 0.985/0.96 window opacity so terminal backgrounds stay solid.
-- (Terminal apps also set their own opacity to 1.0.)
o.window("^(Alacritty|com.mitchellh.ghostty|foot|kitty|org.codeberg.dnkl.foot)$", { tag = "-default-opacity" })
o.window("^(Alacritty|com.mitchellh.ghostty|foot|kitty|org.codeberg.dnkl.foot)$", { opacity = "1 1" })

-- Apply backdrop blur to every Omarchy shell layer except the wallpaper.
-- ignore_alpha lets the blur show through translucent surfaces while
-- opaque ones (alpha 1.0) are unaffected.
hl.layer_rule({
  match = {
    namespace = "^(omarchy-bar.*|omarchy-menu|omarchy-notifications|omarchy-clipboard|omarchy-emojis|omarchy-image-selector|omarchy-osd|omarchy-polkit|omarchy-reminders|omarchy-keyboard-panel.*|omarchy-lock-preview|omarchy-network-qr|omarchy-.*speedtest)$",
  },
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.35,
})
