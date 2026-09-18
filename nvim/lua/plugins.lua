local status, packer = pcall(require, "packer")

if not status then
	print("packer is not installed")
	return
end

vim.cmd([[packadd packer.nvim]])

packer.startup(function(use)
	-- packer
	use("wbthomason/packer.nvim")
	-- Common utilities
	use("nvim-lua/plenary.nvim")

	-- telescope
	use("vim-scripts/zenesque.vim")
	use("jaredgorski/Mies.vim")
	use("jaredgorski/fogbell.vim")

	use({
		"nvim-telescope/telescope.nvim",
		tag = "v0.2.2",
		-- or                          , branch = '0.1.x',
		requires = { { "nvim-lua/plenary.nvim" } },
	})

	-- lsp configs
	use({
		"VonHeikemen/lsp-zero.nvim",
		branch = "v1.x",
		requires = {
			-- LSP Support
			{ "neovim/nvim-lspconfig" },
			{ "williamboman/mason.nvim" },
			{ "williamboman/mason-lspconfig.nvim" },

			-- Autocompletion
			{ "hrsh7th/nvim-cmp" },
			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-path" },
			{ "saadparwaiz1/cmp_luasnip" },
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "hrsh7th/cmp-nvim-lua" },

			-- Snippets
			{ "L3MON4D3/LuaSnip" },
			{ "rafamadriz/friendly-snippets" },
		},
	})
	--
	use("eandrju/cellular-automaton.nvim")

	-- git
	use({
		"lewis6991/gitsigns.nvim",
	})
	use({
		"dinhhuy258/git.nvim",
	})
	use("rbong/vim-flog")

	-- lualine
	use("nvim-lualine/lualine.nvim")

	-- treesitter
	use({
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		run = function()
			require("nvim-treesitter")
				.install({
					"c",
					"lua",
					"rust",
					"go",
					"tsx",
					"toml",
					"yaml",
					"css",
					"html",
					"angular",
					"typescript",
					"json",
					"javascript",
					"markdown",
					"markdown_inline",
				}, { force = true })
				:wait(300000)
		end,
	})
	use("theprimeagen/harpoon")
	use({ "nvim-tree/nvim-tree.lua", requires = { "nvim-tree/nvim-web-devicons" } })

	--undotree
	use("mbbill/undotree")

	-- format code
	use("nvimtools/none-ls.nvim")
	use("MunifTanjim/prettier.nvim")

	--nerd commenter
	use("scrooloose/nerdcommenter")

	-- debugger
	use("mfussenegger/nvim-dap")
	use("rcarriga/nvim-dap-ui")
	use("theHamsta/nvim-dap-virtual-text")
	use("leoluz/nvim-dap-go")

	-- rustlang
	use("simrat39/rust-tools.nvim")

	-- golang
	use("ray-x/go.nvim")
	use("ray-x/guihua.lua")
	use({
		"edolphin-ydf/goimpl.nvim",
		requires = {
			{ "nvim-lua/plenary.nvim" },
			{ "nvim-lua/popup.nvim" },
			{ "nvim-telescope/telescope.nvim" },
			{ "nvim-treesitter/nvim-treesitter" },
		},
		config = function()
			require("telescope").load_extension("goimpl")
		end,
	})

	-- test tree
	use({
		"nvim-neotest/neotest",
		requires = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"nvim-neotest/nvim-nio",
			"antoinemadec/FixCursorHold.nvim",
			"rouge8/neotest-rust",
			"nvim-neotest/neotest-go",
		},
	})

	-- themes
	use("folke/tokyonight.nvim")
	use("fxn/vim-monochrome")
	use("craftzdog/solarized-osaka.nvim")
	use("nlknguyen/papercolor-theme")
	-- Omarchy's canonical theme engine: template-generated Omarchy themes
	-- (like omablue, which ships only a colors.toml) resolve to the `aether`
	-- colorscheme, so this must be installed for the theme sync to be exact.
	use({ "bjarneo/aether.nvim", branch = "v3" })

	use({ "ellisonleao/gruvbox.nvim" })

	-- Sunny/light counterpart: https://github.com/bjarneo/omarchy-kanagawa-lotus-theme
	-- (Omarchy drops *.lua from cloned themes, so its staged neovim.lua is the
	-- generic aether template; nvim maps the theme name back to kanagawa-lotus
	-- in lua/omarchy.lua). Provides kanagawa-lotus / kanagawa-wave / kanagawa-dragon.
	use("rebelot/kanagawa.nvim")

	-- Dark counterpart for Tokyo Night: https://github.com/rose-pine/neovim
	-- (Omarchy Tokyo Night ships `tokyonight-night`; nvim maps the theme name
	-- back to rose-pine in lua/omarchy.lua so dark mode uses Rosé Pine).
	-- Provides rose-pine / rose-pine-main / rose-pine-moon / rose-pine-dawn.
	use({ "rose-pine/neovim", as = "rose-pine" })

	use("justinmk/vim-sneak")

	-- md file preview
	use("henriklovhaug/Preview.nvim")

	use("sbdchd/neoformat")

	use("hedyhli/outline.nvim")

	-- center buffer / no neck pain
	use("shortcuts/no-neck-pain.nvim")

	-- trouble
	use({ "folke/trouble.nvim", requires = "nvim-tree/nvim-web-devicons" })

	-- smooth cursor animation (Zed-like cursor glide)
	use("sphamba/smear-cursor.nvim")

	-- Deps
	use("MunifTanjim/nui.nvim")
	use("nvim-tree/nvim-web-devicons")
	use("HakonHarnes/img-clip.nvim")
	use("zbirenbaum/copilot.lua")
	use("stevearc/dressing.nvim")
	-- open code
	use("folke/snacks.nvim")
	use("nickjvandyke/opencode.nvim")

	use("esmuellert/codediff.nvim")

	-- nvim v0.7.2
	use({
		"kdheepak/lazygit.nvim",
		-- optional for floating window border decoration
		requires = {
			"nvim-lua/plenary.nvim",
		},
	})

	use("idr4n/github-monochrome.nvim")
end)
