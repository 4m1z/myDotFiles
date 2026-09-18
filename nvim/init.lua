-- Core
require("sets")
require("plugins")
require("remap")

-- LSP & completion
require("lsp")
require("lsp_mason")
require("angular_conf")
require("null_ls")
require("prettier_conf")

-- Languages
require("rust")
require("go_conf")
require("cp_go")

-- UI
require("colorscheme")
require("solarized")
require("kanagawa_conf")
require("rose_pine_conf")
require("lualine")
require("treesitter")
require("tree_sitter_context")
require("no_neck_pain_conf")
require("smear_conf")
require("icons")

-- Navigation & files
require("telescope_conf")
require("harpoon_conf")
require("nvim_tree_conf")
require("outline_conf")
require("trouble_conf")

-- Git
require("git_config")
require("neo_git")
require("lazygit_conf")
require("github_conf")

-- Tools
require("neo_test_tree")
require("md_preview")
require("op_code_config")
require("config.remote_clipboard").setup()

-- Disabled: DAP stack (debugger.lua) is kept but unwired; enabling it
-- rebinds <leader><leader>, which remap.lua already uses for `:so`.
-- require("debugger")
