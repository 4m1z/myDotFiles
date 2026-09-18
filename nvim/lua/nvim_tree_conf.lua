vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.termguicolors = true

local function my_on_attach(bufnr)
	local api = require("nvim-tree.api")

	local function opts(desc)
		return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
	end

	-- default mappings
	api.config.mappings.default_on_attach(bufnr)

	-- custom mappings
	vim.keymap.set("n", "<C-t>", api.tree.change_root_to_parent, opts("Up"))
	vim.keymap.set("n", "?", api.tree.toggle_help, opts("Help"))

	-- `q` closes the whole popup (tree + preview) and returns focus.
	-- This only replaces the buffer-local tree mapping; global `q` is untouched.
	-- `p` stays as paste and `<Tab>` keeps its native behavior.
	vim.keymap.set("n", "q", function()
		require("nvim_tree_popup").close_from_tree()
	end, opts("Close popup"))
end

-- pass to setup along with your other options
require("nvim-tree").setup({
	on_attach = my_on_attach,
	view = {
		preserve_window_proportions = false,
		float = {
			enable = true,
			-- Keep the popup open while create/rename/delete prompts
			-- (vim.ui.input/select) take focus.
			quit_on_focus_loss = false,
			open_win_config = function()
				return require("nvim_tree_popup").tree_win_config()
			end,
		},
	},

	-- Directory startup is bridged to the same centered popup in
	-- `nvim_tree_popup` (nvim-tree's own hijack opens docked).
	hijack_directories = {
		enable = false,
	},

	actions = {
		open_file = {
			resize_window = false,
			-- Close the popup after a file is chosen; `q` cancels instead.
			quit_on_open = true,
		},
	},
})

pcall(require("nvim_tree_popup").setup)
