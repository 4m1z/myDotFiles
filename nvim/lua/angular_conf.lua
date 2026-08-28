local capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.lsp.config("angularls", {
	capabilities = capabilities,
})

vim.lsp.enable("angularls")
