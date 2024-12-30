local status, packer = pcall(require, 'packer')

if (not status) then
    print('packer is not installed')
    return
end

vim.cmd [[packadd packer.nvim]]

packer.startup(function(use)
    -- packer
    use 'wbthomason/packer.nvim'
    -- Common utilities
    use 'nvim-lua/plenary.nvim'

    -- telescope

    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.4',
        -- or                            , branch = '0.1.x',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }


    -- lsp configs
    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v1.x',
        requires = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },

            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },
        }
    }

    --
    use 'eandrju/cellular-automaton.nvim'

    -- git
    use {
        'lewis6991/gitsigns.nvim',
    }
    use {
        'dinhhuy258/git.nvim'
    }
    use 'rbong/vim-flog'

    -- lualine
    use 'nvim-lualine/lualine.nvim'

    -- treesitter
    use {
        'nvim-treesitter/nvim-treesitter',
        run = function()
            local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
            ts_update()
        end,
    }
    use("theprimeagen/harpoon")
    use {
        'nvim-tree/nvim-tree.lua',
        requires = {
            'nvim-tree/nvim-web-devicons',
        },
    }

    --undotree
    use 'mbbill/undotree'

    -- format code
    use('jose-elias-alvarez/null-ls.nvim')
    use('MunifTanjim/prettier.nvim')

    -- devicons
    use 'nvim-tree/nvim-web-devicons'


    --nerd commenter
    use 'scrooloose/nerdcommenter'

    -- debugger
    use("mfussenegger/nvim-dap")
    use("rcarriga/nvim-dap-ui")
    use("theHamsta/nvim-dap-virtual-text")
    use 'leoluz/nvim-dap-go' -- Install the plugin with Packer


    --copilot.vim
    use 'github/copilot.vim'

    -- rustlang
    use 'simrat39/rust-tools.nvim'

    -- golang
    use 'ray-x/go.nvim'
    use 'ray-x/guihua.lua'
    use {
        'edolphin-ydf/goimpl.nvim',
        requires = {
            { 'nvim-lua/plenary.nvim' },
            { 'nvim-lua/popup.nvim' },
            { 'nvim-telescope/telescope.nvim' },
            { 'nvim-treesitter/nvim-treesitter' },
        },
        config = function()
            require 'telescope'.load_extension 'goimpl'
        end,
    }

    -- test tree
    use {
        "nvim-neotest/neotest",
        requires = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "antoinemadec/FixCursorHold.nvim",
            "rouge8/neotest-rust",
            "nvim-neotest/neotest-go",
        }
    }

    -- themes
    use {
        'svrana/neosolarized.nvim',
        requires = { 'tjdevries/colorbuddy.nvim' }
    }
    use { 'luisiacc/gruvbox-baby' }
    use({ 'rose-pine/neovim', as = 'rose-pine' })
    use 'craftzdog/solarized-osaka.nvim'
    use { "folke/tokyonight.nvim" }
    use 'fxn/vim-monochrome'






    use('justinmk/vim-sneak')
    use("folke/zen-mode.nvim")
    -- use("eandrju/cellular-automaton.nvim")
    -- use("laytan/cloak.nvim")
    -- use 'jose-elias-alvarez/null-ls.nvim'

    -- md file preview
    use "henriklovhaug/Preview.nvim"

    use 'sbdchd/neoformat'

    use "hedyhli/outline.nvim"

    -- trouble  
    use { "folke/trouble.nvim", requires = "nvim-tree/nvim-web-devicons" }
end)
