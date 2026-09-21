-- Firouzeh frosted glass: rounded corners, backdrop blur, soft shadows.
-- Theme-scoped: only applies while `omarchy theme set firouzeh` is active.
-- Borders mirror colors.toml (turquoise glaze edge).

local active_border_color = "rgba(54b7aeee)"
local inactive_border_color = "rgba(344752aa)"

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
      text_color = "rgb(f1e8d7)",
      text_color_inactive = "rgba(9caca899)",
      col = {
        active = "rgba(29464dcc)",
        inactive = "rgba(090f1888)",
      },
      gradients = true,
    },
  },

  decoration = {
    rounding = 14,

    blur = {
      enabled = true,
      size = 14,
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

    shadow = {
      enabled = true,
      range = 40,
      render_power = 3,
      color = "rgba(090f18aa)",
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
