local status, treesitter = pcall(require, "nvim-treesitter")
if not status then return end

local parsers = {
  "c",
  "lua",
  "rust",
  "go",
  "tsx",
  "toml",
  "yaml",
  "css",
  "html",
  "typescript",
  "json",
  "javascript",
  "markdown",
  "markdown_inline",
}

treesitter.setup()
treesitter.install(parsers)

vim.api.nvim_create_autocmd("FileType", {
  pattern = parsers,
  callback = function()
    pcall(vim.treesitter.start)
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
