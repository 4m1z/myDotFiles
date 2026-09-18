local ok, icons = pcall(require, "nvim-web-devicons")
if not ok then
	return
end

icons.setup({
	override = {},
	default = true,
})
