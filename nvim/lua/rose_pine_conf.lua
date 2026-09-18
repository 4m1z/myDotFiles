local ok, rose_pine = pcall(require, "rose-pine")
if not ok then
	return
end

rose_pine.setup({
	variant = "auto", -- auto follows vim.o.background (set from Omarchy mode)
	dark_variant = "main", -- dark mode = Rosé Pine main
	dim_inactive_windows = false,
	extend_background_behind_borders = true,
	enable = {
		terminal = true,
		legacy_highlights = true,
		migrations = true,
	},
	styles = {
		bold = true,
		italic = true,
		transparency = true, -- keep the wallpaper showing through (see colorscheme.lua)
	},
})
