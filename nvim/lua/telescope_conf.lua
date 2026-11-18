local ok, builtin = pcall(require, "telescope.builtin")
if not ok then
	return
end

vim.api.nvim_create_autocmd("VimEnter", {
	group = vim.api.nvim_create_augroup("TelescopeStartup", { clear = true }),
	once = true,
	callback = function()
		if vim.fn.argc() > 1 or vim.bo.buftype ~= "" or vim.bo.modified then
			return
		end
		local path = vim.api.nvim_buf_get_name(0)
		if path ~= "" then
			if vim.fn.isdirectory(path) == 0 then
				return
			end
			vim.api.nvim_buf_delete(0, { force = true })
		end
		vim.schedule(function()
			local opts = { cwd = path ~= "" and path or nil }
			if not pcall(builtin.git_files, opts) then
				builtin.find_files(opts)
			end
		end)
	end,
})

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
