local ok, neoformat = pcall(require, "neoformat")
if not ok then
	return
end

local function prettier()
	return {
		exe = "prettier",
		args = { "--stdin-filepath", vim.api.nvim_buf_get_name(0) },
		stdin = true,
	}
end

neoformat.setup({
	javascript = prettier(),
	typescript = prettier(),
	javascriptreact = prettier(),
	typescriptreact = prettier(),
	css = prettier(),
	scss = prettier(),
	less = prettier(),
	json = prettier(),
	lua = {
		exe = "stylua",
		args = { "-" },
		stdin = true,
	},
})
