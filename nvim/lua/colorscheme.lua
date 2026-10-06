local theme_ok, theme = pcall(require, "system_theme")

local function base_scheme()
	-- Follow the system light/dark mode; safe default when unavailable.
	if theme_ok then
		local ok, preferred = pcall(theme.preferred_scheme)
		if ok and preferred ~= nil and preferred ~= "" then
			return preferred
		end
	end
	return "monochrome"
end

function ColorMYVim(color)
	color = color or base_scheme()

	-- The intended scheme may not be installed. Walk the fallbacks instead
	-- of erroring out.
	local applied = color
	if not pcall(vim.cmd.colorscheme, color) then
		applied = nil
		if theme_ok then
			local candidates = { color }
			for _, fallback in ipairs(theme.fallbacks()) do
				table.insert(candidates, fallback)
			end
			applied = theme.try_schemes(candidates)
		else
			pcall(vim.cmd.colorscheme, "monochrome")
			applied = "monochrome"
		end
	end
	vim.g.active_colorscheme = applied or color

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NvimTreeNormalNC", { bg = "none" })
	vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { bg = "none" })
	vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { bg = "none" })
	vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })

	-- Paint the system palette (terminal colors, fg, selection) on top.
	if theme_ok then
		theme.apply_palette()
		vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	end
end

ColorMYVim()

-- Keep the palette on top if something changes the scheme later.
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		if theme_ok then
			theme.apply_palette()
			vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
		end
	end,
})

-- Re-read system theme state (after toggling light/dark) without restarting.
vim.api.nvim_create_user_command("SystemTheme", function()
	if theme_ok then
		theme.reload()
	end
	ColorMYVim()
	local name = vim.g.active_colorscheme
	print("Theme synced: " .. tostring(name) .. " (" .. vim.o.background .. ")")
end, {})

-- Legacy alias (Omarchy-era muscle memory). Prefer :SystemTheme.
vim.api.nvim_create_user_command("OmarchyTheme", function()
	vim.cmd("SystemTheme")
end, {})
