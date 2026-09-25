-- Godfather frosted noir: rounded corners, backdrop blur, soft shadows.
-- Theme-scoped: only applies while `omarchy theme set godfather` is active.
-- Borders mirror colors.toml (aged-gold edge).

local active_border_color = "rgba(c9a86aee)"
local inactive_border_color = "rgba(3a2a1aaa)"

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 12,
    border_size = 2,

    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },

    groupbar = {
      text_color = "rgb(fff2d6)",
      text_color_inactive = "rgba(9a8b7399)",
      col = {
        active = "rgba(3a2a1acc)",
        inactive = "rgba(08070688)",
      },
      gradients = true,
    },
  },

  decoration = {
    rounding = 12,

    blur = {
      enabled = true,
      size = 14,
      passes = 3,
      vibrancy = 0.25,
      vibrancy_darkness = 0.6,
      ignore_opacity = true,
      new_optimizations = true,
      -- Blur layer-shell popups (calendar etc.) anchored to the bar.
      popups = true,
      popups_ignorealpha = 0.35,
      input_methods = true,
      input_methods_ignorealpha = 0.4,
    },

    shadow = {
      enabled = true,
      range = 40,
      render_power = 3,
      color = "rgba(080706aa)",
    },
  },
})

-- Frosted glass for the Omarchy shell layers: blur the backdrop behind
-- translucent bar popups (calendar), menus, notifications and launcher
-- so text stays readable. Mirrors the system-wide rules in hypr/looknfeel.lua.
hl.layer_rule({
  match = {
    namespace = "^(omarchy-bar.*|omarchy-menu|omarchy-notifications|omarchy-clipboard|omarchy-emojis|omarchy-image-selector|omarchy-osd|omarchy-polkit|omarchy-reminders|omarchy-keyboard-panel.*|omarchy-lock-preview|omarchy-network-qr|omarchy-.*speedtest)$",
  },
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.35,
})
