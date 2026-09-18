local ok, builtin = pcall(require, "telescope.builtin")
if not ok then
	return
end

-- keymaps
vim.keymap.set("n", ";f", builtin.find_files, {})
vim.keymap.set("n", ";g", builtin.git_files, {})
vim.keymap.set("n", ";c", builtin.git_status, {})

vim.keymap.set("n", "<leader>ps", function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end)

vim.keymap.set("n", "<leader>im", function()
	require("telescope").extensions.goimpl.goimpl({})
end, { noremap = true, silent = true, desc = "Go: implement interface" })

vim.keymap.set("n", "<leader>vh", builtin.help_tags, {})
vim.keymap.set("n", ";r", function()
	builtin.live_grep()
end)

vim.keymap.set("n", "<leader>prw", function()
	builtin.grep_string()
end)

vim.keymap.set("n", ";t", function()
	builtin.help_tags()
end)

vim.keymap.set("n", ";;", function()
	builtin.resume()
end)

vim.keymap.set("n", ";e", function()
	builtin.diagnostics()
end)
vim.keymap.set("n", "\\\\", function()
	builtin.buffers()
end)
