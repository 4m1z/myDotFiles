-- Distro-neutral system theme bridge (replaces the legacy distro-specific one).
--
-- Resolution order for the light/dark mode:
--   1. $MYDOTFILES_THEME_FILE override, else
--      ~/.local/state/mydotfiles/theme  (written by mydotfiles-theme-toggle
--      and by cachyos/install.sh; simple `mode=dark|light` lines, optional
--      palette keys below),
--   2. live `noctalia msg theme-mode-get` when the noctalia binary exists,
--   3. $NOCTALIA_THEME_MODE environment variable,
--   4. safe default (dark).
--
-- Guarantees: never errors, never blocks startup, works over SSH, in
-- Docker, headless, and when no desktop theme information exists.
local M = {}

M._cache = nil

local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function state_file()
	local override = os.getenv("MYDOTFILES_THEME_FILE")
	if override ~= nil and override ~= "" then
		return override
	end
	local home = os.getenv("HOME") or ""
	if home == "" then
		return nil
	end
	return home .. "/.local/state/mydotfiles/theme"
end

local function read_kv(path)
	local out = {}
	local fh = io.open(path, "r")
	if fh == nil then
		return nil
	end
	for raw in fh:lines() do
		local line = trim(raw)
		if line ~= "" and line:sub(1, 1) ~= "#" then
			local key, val = line:match("^([A-Za-z0-9_]+)%s*=%s*(.-)%s*$")
			if key ~= nil and val ~= nil then
				out[key] = trim(val)
			end
		end
	end
	fh:close()
	return out
end

local function executable(name)
	if vim.fn.executable(name) == 1 then
		return true
	end
	return false
end

local function noctalia_mode()
	if not executable("noctalia") then
		return nil
	end
	local handle = io.popen("noctalia msg theme-mode-get 2>/dev/null")
	if handle == nil then
		return nil
	end
	local out = handle:read("*l")
	handle:close()
	if out == nil then
		return nil
	end
	out = trim(out):lower()
	if out == "dark" or out == "light" then
		return out
	end
	return nil
end

--- Load (and cache) the theme state. Always returns a table.
--- Shape: { mode = "dark"|"light", scheme = <name>|nil, colors = {...} }
function M.load()
	if M._cache ~= nil then
		return M._cache
	end
	local state = { mode = nil, scheme = nil, colors = {} }

	local path = state_file()
	if path ~= nil then
		local kv = read_kv(path)
		if kv ~= nil then
			local mode = (kv.mode or ""):lower()
			if mode == "dark" or mode == "light" then
				state.mode = mode
			end
			if kv.scheme ~= nil and kv.scheme ~= "" then
				state.scheme = kv.scheme
			end
			for _, key in ipairs({
				"foreground",
				"background",
				"selection",
				"selection_foreground",
				"cursor",
			}) do
				if kv[key] ~= nil and kv[key] ~= "" then
					state.colors[key] = kv[key]
				end
			end
			for i = 0, 15 do
				local key = "color" .. i
				if kv[key] ~= nil and kv[key] ~= "" then
					state.colors[key] = kv[key]
				end
			end
		end
	end

	if state.mode == nil then
		state.mode = noctalia_mode()
	end
	if state.mode == nil then
		local env = os.getenv("NOCTALIA_THEME_MODE")
		if env ~= nil then
			env = trim(env):lower()
			if env == "dark" or env == "light" then
				state.mode = env
			end
		end
	end
	if state.mode == nil then
		state.mode = "dark"
	end

	M._cache = state
	return state
end

--- Drop the cached state so the next call re-reads disk.
--- Used by :SystemTheme after toggling the mode in a running session.
function M.reload()
	M._cache = nil
	return M.load()
end

local FALLBACKS = { "monochrome", "aether", "solarized-osaka", "tokyonight-night" }

-- Dedicated schemes per mode (each requires its plugin in plugins.lua;
-- the fallback chain below covers machines where one is missing).
-- Light default mirrors the old sunny kanagawa-lotus setup; dark default
-- mirrors the old rose-pine setup.
local MODE_SCHEME = {
	light = "kanagawa-lotus",
	dark = "rose-pine",
}

--- Pick the colorscheme to use. Sets `vim.o.background` from the mode
--- as a side effect. Always returns a non-empty string.
function M.preferred_scheme()
	local state = M.load()
	if vim.o.background ~= state.mode then
		vim.o.background = state.mode
	end
	if state.scheme ~= nil and state.scheme ~= "" then
		return state.scheme
	end
	local mapped = MODE_SCHEME[state.mode]
	if mapped ~= nil and mapped ~= "" then
		return mapped
	end
	return FALLBACKS[1]
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

--- Paint the system palette over the active colorscheme: terminal colors,
--- Normal foreground and selection. Backgrounds stay transparent (see
--- colorscheme.lua). No-op when the state file carries no colors, so plain
--- light/dark following works without any palette plumbing.
function M.apply_palette()
	local state = M.load()
	local c = state.colors
	if c == nil or next(c) == nil then
		return false
	end

	local fg = pick(c, "foreground", "fg")
	local bg = pick(c, "background", "bg")
	local selection = pick(c, "selection")
	local selection_fg = pick(c, "selection_foreground", "background", "bg")

	if c.color0 ~= nil then
		for i = 0, 15 do
			local color = c["color" .. i]
			if color ~= nil and color:match("^#%x%x%x%x%x%x$") then
				vim.g["terminal_color_" .. i] = color
			end
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
		vim.api.nvim_set_hl(0, "Cursor", { bg = fg, fg = bg })
	end

	return true
end

return M
