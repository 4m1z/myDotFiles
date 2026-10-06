-- Kanagawa (rebelot/kanagawa.nvim) setup. system_theme.lua selects the light
-- lotus variant and dark wave variant according to the current system mode;
-- transparent backgrounds match the rest of this config.
local ok, kanagawa = pcall(require, "kanagawa")
if not ok then
	return
end

kanagawa.setup({
	compile = false,
	undercurl = true,
	commentStyle = { italic = true },
	functionStyle = {},
	keywordStyle = { italic = true },
	statementStyle = { bold = true },
	typeStyle = {},
	transparent = true, -- keep the wallpaper showing through (see colorscheme.lua)
	dimInactive = false,
	terminalColors = true,
	colors = {
		palette = {},
		theme = {
			lotus = {
				ui = {
					-- Match the Omarchy theme's background (#f1e9d2 in colors.toml).
					bg = "#f1e9d2",
				},
			},
			wave = {},
			dragon = {},
			all = {},
		},
	},
	theme = "wave", -- default for dark; background mapping picks lotus on light
	background = {
		dark = "wave",
		light = "lotus",
	},
})
