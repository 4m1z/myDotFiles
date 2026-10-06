-- myDotFiles personal overrides for the official CachyOS Hyprland + Noctalia
-- desktop. Installed by cachyos/install.sh as
--   ~/.config/hypr/config/personal.lua
-- and required from hyprland.lua (idempotent marker line).
--
-- Small overrides only: keyboard layouts, personal keybindings, opaque
-- terminals, Notes window rule. Everything else stays on CachyOS defaults.
-- Blur for Noctalia layers and terminal opacity are already covered by the
-- official cachyos-hypr-noctalia config; rules below only ADD foot (used by
-- Speedy) to the opaque-terminal set.

-- English, Persian and German, cycled with Alt + Shift.
hl.config({
	input = {
		kb_layout = "us,ir,de",
		kb_options = "compose:caps,shift:both_capslock_cancel,grp:alt_shift_toggle",
	},
})

local noctCall = "noctalia msg "
local home = os.getenv("HOME") or ""
local helperDir = home .. "/.local/bin"

-- Manual light/dark toggle. SUPER + SHIFT + T is unbound in the official
-- CachyOS binds.lua (verified Oct 2026), so this cannot shadow a default.
-- The helper also records the resolved mode for Neovim/system_theme.lua.
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd(helperDir .. "/mydotfiles-theme-toggle"))

-- Speedy (SUPER + SHIFT + I, also unbound in official binds). Focuses the
-- existing Speedy window, otherwise launches it. No Omarchy dependency.
hl.bind("SUPER + SHIFT + I", hl.dsp.exec_cmd(helperDir .. "/mydotfiles-speedy"))

-- NOTE: SUPER + SHIFT + W (Notes) is patched into config/binds.lua by the
-- installer because the official config binds it to the wallpaper menu
-- (moved to SUPER + SHIFT + B). See cachyos/install.sh patch_binds().

-- Opaque terminals for readability. Official config already forces
-- kitty/ghostty/Alacritty opaque; add foot (Speedy's terminal).
hl.window_rule({ match = { class = "^(foot|org.codeberg.dnkl.foot)$" }, opacity = "1.0 override" })

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
