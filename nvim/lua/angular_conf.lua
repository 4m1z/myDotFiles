local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Use nvim-lspconfig's current launcher so Angular can probe both the project
-- and Mason for its TypeScript and Angular language-service dependencies.
vim.lsp.config("angularls", {
	capabilities = capabilities,
})

vim.lsp.enable("angularls")
