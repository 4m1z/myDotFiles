-- Core
require("sets")
require("remap")

-- Plugin manager and plugins are provisioned by cachyos/install.sh, but a
-- first-start/editor invocation can happen before that network setup has
-- completed (SSH, Docker, or headless sessions included). Keep the core
-- editor usable and isolate optional plugin modules until their deps exist.
local packer_ok = pcall(require, "packer")
require("plugins")

local function safe_plugin(module)
	if not packer_ok then
		return
	end
	local ok, err = pcall(require, module)
	if not ok then
		vim.notify("myDotFiles: skipped " .. module .. " (plugin unavailable): " .. tostring(err), vim.log.levels.WARN)
	end
end

-- LSP & completion
safe_plugin("lsp")
safe_plugin("lsp_mason")
safe_plugin("angular_conf")
safe_plugin("null_ls")
safe_plugin("prettier_conf")

-- Languages
safe_plugin("rust")
safe_plugin("go_conf")
safe_plugin("cp_go")

-- UI
safe_plugin("colorscheme")
safe_plugin("solarized")
safe_plugin("kanagawa_conf")
safe_plugin("rose_pine_conf")
safe_plugin("lualine")
safe_plugin("treesitter")
safe_plugin("tree_sitter_context")
safe_plugin("no_neck_pain_conf")
safe_plugin("smear_conf")
safe_plugin("icons")

-- Navigation & files
safe_plugin("telescope_conf")
safe_plugin("harpoon_conf")
safe_plugin("nvim_tree_conf")
safe_plugin("outline_conf")
safe_plugin("trouble_conf")

-- Git
safe_plugin("git_config")
safe_plugin("neo_git")
safe_plugin("lazygit_conf")
safe_plugin("github_conf")

-- Tools
safe_plugin("neo_test_tree")
safe_plugin("md_preview")
safe_plugin("op_code_config")
require("config.remote_clipboard").setup()

-- Disabled: DAP stack (debugger.lua) is kept but unwired; enabling it
-- rebinds <leader><leader>, which remap.lua already uses for `:so`.
-- require("debugger")
