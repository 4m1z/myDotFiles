-- Kanagawa (rebelot/kanagawa.nvim) setup for the sunny Omarchy theme:
-- https://github.com/bjarneo/omarchy-kanagawa-lotus-theme
--
-- That Omarchy theme ships a `neovim.lua` asking for `kanagawa-lotus`, but
-- Omarchy does not stage *.lua from third-party cloned themes, so the live
-- staged theme resolves to the generic `aether` template. `lua/omarchy.lua`
-- maps the theme name back to `kanagawa-lotus`; this file just configures the
-- plugin so the scheme looks right (transparent like the rest of this config,
-- terminal colors on, lotus bg matching the Omarchy colors.toml).
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
