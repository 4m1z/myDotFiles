-- OmaBlue liquid glass: rounded corners, backdrop blur, soft shadows.
-- Theme-scoped: only applies while `omarchy theme set omablue` is active.
-- Borders mirror colors.toml (white / PowerShell-blue gradient).

local active_border_color = { colors = { "rgba(ffffffff)", "rgba(73b7ffee)" }, angle = 45 }
local inactive_border_color = "rgba(7ba2c788)"

hl.config({
  general = {
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
  },

  decoration = {
    rounding = 14,

    blur = {
      enabled = true,
      size = 12,
      passes = 3,
      vibrancy = 0.1696,
      new_optimizations = true,
    },

    shadow = {
      enabled = true,
      range = 30,
      render_power = 3,
      color = "rgba(00132dff)",
    },
  },
})
