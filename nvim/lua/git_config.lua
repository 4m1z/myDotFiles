-- git
require("gitsigns").setup({})
local status, git = pcall(require, "git")
if not status then
	return
end

git.setup({
	signcolumn = false, -- Toggle with `:Gitsigns toggle_signs`
	default_mappings = false, -- NOTE: `quit_blame` and `blame_commit` are still merged to the keymaps even if `default_mappings = false`
	keymaps = {
		-- Open blame window
		blame = "<Leader>gb",
		-- Open file/folder in git repository
		browse = "<Leader>go",
	},
})
