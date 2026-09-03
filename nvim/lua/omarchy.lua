local M = {}

M._cache = nil

local function is_dir(path)
  return vim.fn.isdirectory(path) == 1
end

local function is_file(path)
  return vim.fn.filereadable(path) == 1
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Directory holding the staged current theme, or nil when not on Omarchy.
function M.state_dir()
  local override = os.getenv("OMARCHY_THEME_DIR")
  if override ~= nil and override ~= "" and is_dir(override) then
    return override
  end
  local home = os.getenv("HOME") or ""
  local current = home .. "/.local/state/omarchy/current/theme"
  if is_dir(current) then
    return current
  end
  local legacy = home .. "/.config/omarchy/current/theme"
  if is_dir(legacy) then
    return legacy
  end
  return nil
end

--- Minimal TOML reader for Omarchy's flat `key = "value"` colors files.
--- Returns a table of strings (unquoted values stay as-is).
function M.parse_toml(path)
  local out = {}
  local fh = io.open(path, "r")
  if fh == nil then
    return out
  end
  for raw in fh:lines() do
    local line = trim(raw)
    if line ~= "" and line:sub(1, 1) ~= "#" and line:sub(1, 1) ~= "[" then
      local key, val = line:match("^([A-Za-z0-9_%.%-]+)%s*=%s*(.-)%s*$")
      if key ~= nil and val ~= nil then
        local first = val:sub(1, 1)
        if first == '"' or first == "'" then
          out[key] = val:match("^" .. first .. "(.-)" .. first) or ""
        else
          -- unquoted: cut trailing comment
          out[key] = trim((val:gsub("%s*#.*$", "")))
        end
      end
    end
  end
  fh:close()
  return out
end

local function read_first_line(path)
  local fh = io.open(path, "r")
  if fh == nil then
    return nil
  end
  local line = fh:read("*l")
  fh:close()
  if line == nil then
    return nil
  end
  return trim(line)
end

--- The `colorscheme = "..."` the theme ships in its generated `neovim.lua`.
--- This is the theme author's intent (e.g. "gruvbox", or "aether" for
--- template-generated themes such as custom ones with only a colors.toml).
local function parse_generated_neovim(path)
  local fh = io.open(path, "r")
  if fh == nil then
    return nil, {}
  end
  local content = fh:read("*a")
  fh:close()
  if content == nil then
    return nil, {}
  end
  local scheme = content:match('colorscheme%s*=%s*["\']([^"\']+)["\']')
  -- The generated file carries the fully resolved palette (selection
  -- fallbacks, bright variants, ...), which newer minimal colors.toml files
  -- no longer spell out. Only hex values can be palette entries, so the
  -- plugin spec strings (branch, name, ...) never match.
  local colors = {}
  for key, val in content:gmatch('([A-Za-z0-9_]+)%s*=%s*["\'](#[%x]+)["\']') do
    colors[key] = val
  end
  return scheme, colors
end

--- Load (and cache) the active Omarchy theme. Returns nil when absent.
--- Shape: { name = "manga", scheme = "aether"|nil, colors = { bg=..., ... } }
function M.load()
  if M._cache ~= nil then
    return M._cache
  end
  local dir = M.state_dir()
  if dir == nil then
    return nil
  end
  local colors_file = dir .. "/colors.toml"
  if not is_file(colors_file) then
    return nil
  end
  local scheme, generated = parse_generated_neovim(dir .. "/neovim.lua")
  local colors = M.parse_toml(colors_file)
  for key, val in pairs(generated) do
    if colors[key] == nil then
      colors[key] = val
    end
  end
  -- `theme.name` lives next to the staged dir: current/theme.name.
  local name = read_first_line(dir .. "/theme.name") or read_first_line(dir .. "/../theme.name")
  local state = {
    dir = dir,
    name = name,
    scheme = scheme,
    colors = colors,
  }
  M._cache = state
  return state
end

--- Drop the cached state so the next call re-reads disk.
--- Used by :OmarchyTheme after `omarchy theme set` in a running session.
function M.reload()
  M._cache = nil
  return M.load()
end

local FALLBACKS = { "aether","monochrome","solarized-osaka", "tokyonight-night" }

--- Pick the colorscheme to use. Sets `vim.o.background` from the theme mode
--- as a side effect. Returns nil when there is no Omarchy state.
function M.preferred_scheme()
  local state = M.load()
  if state == nil then
    return nil
  end
  local mode = state.colors.mode
  if mode == "light" or mode == "dark" then
    vim.o.background = mode
  end
  if state.scheme ~= nil and state.scheme ~= "" then
    return state.scheme
  end
  return nil
end

--- Try each candidate with :colorscheme, return the one that worked (or nil).
function M.try_schemes(candidates)
  for _, name in ipairs(candidates) do
    if name ~= nil and name ~= "" then
      if pcall(vim.cmd.colorscheme, name) then
        return name
      end
    end
  end
  return nil
end

function M.fallbacks()
  return FALLBACKS
end

local function pick(colors, ...)
  for _, key in ipairs({ ... }) do
    local v = colors[key]
    if v ~= nil and v ~= "" then
      return v
    end
  end
  return nil
end

--- Paint the Omarchy palette over the active colorscheme:
--- terminal colors, Normal foreground and the selection. Backgrounds are
--- intentionally left alone so the transparent setup in colorscheme.lua
--- (terminal shows the Omarchy wallpaper/background through) keeps working.
function M.apply_palette()
  local state = M.load()
  if state == nil then
    return false
  end
  local c = state.colors

  local fg = pick(c, "foreground", "fg", "bright_foreground", "light_foreground")
  local bg = pick(c, "background", "bg")
  local selection = pick(c, "selection")
  local selection_fg = pick(c, "selection_foreground", "selection_background", "background", "bg")

  -- :terminal palette 0-15. Newer themes ship color0..color15 directly;
  -- older ones only have named colors, which we map onto the palette.
  local term
  if c.color0 ~= nil then
    term = {}
    for i = 0, 15 do
      term[i + 1] = c["color" .. i]
    end
  else
    term = {
      pick(c, "darker_background", "dark_background", "background", "bg"),
      c.red,
      c.green,
      c.yellow,
      c.blue,
      pick(c, "magenta", "purple"),
      c.cyan,
      pick(c, "dark_foreground", "foreground", "fg"),
      pick(c, "muted", "dark_foreground"),
      pick(c, "bright_red", "red"),
      pick(c, "bright_green", "green"),
      pick(c, "bright_yellow", "yellow"),
      pick(c, "bright_blue", "blue"),
      pick(c, "bright_magenta", "magenta", "purple"),
      pick(c, "bright_cyan", "cyan"),
      pick(c, "bright_foreground", "light_foreground", "foreground", "fg"),
    }
  end
  for i, color in ipairs(term) do
    if color ~= nil and color:match("^#%x%x%x%x%x%x$") then
      vim.g["terminal_color_" .. (i - 1)] = color
    end
  end

  if fg ~= nil then
    vim.api.nvim_set_hl(0, "Normal", { fg = fg })
  end
  if selection ~= nil then
    local visual = { bg = selection }
    if selection_fg ~= nil and selection_fg ~= selection then
      visual.fg = selection_fg
    end
    vim.api.nvim_set_hl(0, "Visual", visual)
  end
  if bg ~= nil and fg ~= nil then
    vim.api.nvim_set_hl(0, "Cursor", { bg = pick(c, "bright_foreground", "foreground", "fg"), fg = bg })
  end

  if state.name ~= nil and state.name ~= "" then
    vim.g.omarchy_theme_name = state.name
  end
  return true
end

return M
