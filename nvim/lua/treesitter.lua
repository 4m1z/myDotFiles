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
  "angular",
  "html_tags",
}

treesitter.setup()
treesitter.install(parsers)

vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    local parser = vim.treesitter.language.get_lang(vim.bo.filetype)
    if not vim.tbl_contains(parsers, parser) then return end

    pcall(vim.treesitter.start)
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
