--local status, prettier = pcall(require, "prettier")
--if (not status) then return end

--prettier.setup {
    --bin = 'prettier',
    --filetypes = {
        --"css",
        --"javascript",
        --"javascriptreact",
        --"typescript",
        --"typescriptreact",
        --"json",
        --"scss",
        --"less",
        --"lua",
    --},
    --config_precedence = "prefer-file", -- or "cli-override" or "file-override"
--}




--vim.api.nvim_create_autocmd("BufWritePre", {
  --pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  --callback = function()
    --vim.cmd("EslintFixAll")
    --vim.cmd("Prettier")
  --end,
  ----group = autogroup_eslint_lsp,
--})
--

local status , neoformat = pcall(require, "neoformat")



if (not status) then return end 

neoformat.setup {
    javascript = {
        exe = "prettier",
        args = {"--stdin-filepath", vim.api.nvim_buf_get_name(0)},
        stdin = true
    },
    typescript = {
        exe = "prettier",
        args = {"--stdin-filepath", vim.api.nvim_buf_get_name(0)},
        stdin = true
    },
    javascriptreact = {
        exe = "prettier",
        args = {"--stdin-filepath", vim.api.nvim_buf_get_name(0)},
        stdin = true
    },
    typescriptreact = {
        exe = "prettier",
        args = {"--stdin-filepath", vim.api.nvim_buf_get_name(0)},
        stdin = true
    },
    css = {
        exe = "prettier",
        args = {"--stdin-filepath", vim.api.nvim_buf_get_name(0)},
        stdin = true
    },
    scss = {
        exe = "prettier",
        args = {"--stdin-filepath", vim.api.nvim_buf_get_name(0)},
        stdin = true
    },
    less = {
        exe = "prettier",
        args = {"--stdin-filepath", vim.api.nvim_buf_get_name(0)},
        stdin = true
    },
    json = {
        exe = "prettier",
        args = {"--stdin-filepath", vim.api.nvim_buf_get_name(0)},
        stdin = true
    },
    lua = {
        exe = "stylua",
        args = {"-"},
        stdin = true
    }
}
