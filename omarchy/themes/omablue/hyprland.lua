-- OmaBlue liquid glass: rounded corners, backdrop blur, soft shadows.
-- Theme-scoped: only applies while `omarchy theme set omablue` is active.
-- Borders mirror colors.toml (electric-blue / cyan gradient).

local active_border_color = { colors = { "rgba(73b7ffee)", "rgba(72e6e6ee)" }, angle = 45 }
local inactive_border_color = "rgba(3a5a8caa)"

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
      text_color = "rgb(ffffff)",
      text_color_inactive = "rgba(a8bdd299)",
      col = {
        active = "rgba(1a4a8acc)",
        inactive = "rgba(00132d88)",
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
      color = "rgba(00132daa)",
    },
  },
})

-- Snappy, sexy motion to match the glass. Mirrors Omarchy defaults, tuned faster.
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "quick", style = "popin 87%" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "quick", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.5, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slidevert" })

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
