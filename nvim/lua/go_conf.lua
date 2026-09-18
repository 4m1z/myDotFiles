local ok, go = pcall(require, "go")
if not ok then
	return
end

go.setup()

vim.keymap.set("n", "<leader>fg", function()
	require("go.format").gofmt()
end, { desc = "Format Go buffer" })
