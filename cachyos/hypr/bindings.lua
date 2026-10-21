-- Personal keybindings and Notes window rules.
local home = os.getenv("HOME") or ""
local helperDir = home .. "/.local/bin"

-- Absolute workspace shortcuts: 1..9, then 0 for workspace 10.
-- Replace the stock SUPER+1/2/3 monitor-focus bindings. Unbind both
-- keysym and keycode variants to support older and newer CachyOS defaults.
-- Physical number-row keys keep working across us/ir/de layouts.
for workspace = 1, 10 do
	local digit = workspace % 10
	local code = digit == 0 and 19 or (9 + digit)
	local key = "SUPER + code:" .. code
	hl.unbind("SUPER + " .. digit)
	hl.unbind(key)
	hl.bind(key, hl.dsp.focus({ workspace = workspace }))
end

-- Manual light/dark toggle. SUPER + SHIFT + T is unbound in the official
-- CachyOS binds.lua (verified Oct 2026), so this cannot shadow a default.
-- The helper also records the resolved mode for Neovim/system_theme.lua.
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd(helperDir .. "/mydotfiles-theme-toggle"))

-- Speedy (SUPER + SHIFT + I, also unbound in official binds). Focuses the
-- existing Speedy window, otherwise launches it.
hl.bind("SUPER + SHIFT + I", hl.dsp.exec_cmd(helperDir .. "/mydotfiles-speedy"))

-- NOTE: SUPER + SHIFT + W (Notes) is patched into config/binds.lua by the
-- installer because the official config binds it to the wallpaper menu
-- (moved to SUPER + SHIFT + B). See cachyos/install.sh patch_binds().

-- Terminal: foot instead of the distro default (kitty). Kitty is heavy and
-- slow to start; foot is a tiny, fast terminal. The official config binds
-- SUPER + Return to TERMINAL, so unbind it first.
hl.unbind("SUPER + Return")
hl.bind("SUPER + Return", hl.dsp.exec_cmd("uwsm app -- foot"))

-- Browser: the system default is Zen Browser (xdg-settings reports
-- zen.desktop), while the distro config still hardcodes firefox.
hl.unbind("SUPER + W")
hl.bind("SUPER + W", hl.dsp.exec_cmd("uwsm app -- zen-browser"))

-- Notes PWA (https://amirahmadzadeh.com/p/notes): floating, centered,
-- desktop-sized at ~1200x800. Matches the Chromium --app window launched
-- by mydotfiles-notes (WM_CLASS NotesApp) and, as a fallback, any window
-- whose title points at the Notes URL (e.g. opened in Firefox).
hl.window_rule({
	match = { class = "^(NotesApp)$" },
	float = true,
	center = true,
	size = { "1200", "800" },
})
hl.window_rule({
	match = { title = "(?i)(amirahmadzadeh\\.com.*notes|notes.*amirahmadzadeh\\.com)" },
	float = true,
	center = true,
	size = { "1200", "800" },
})
