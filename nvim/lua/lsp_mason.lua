local ok, mason = pcall(require, "mason")
if not ok then
	return
end
local ok_lspconfig, mason_lspconfig = pcall(require, "mason-lspconfig")
if not ok_lspconfig then
	return
end

mason.setup({})

mason_lspconfig.setup({
	ensure_installed = { "lua_ls", "tailwindcss" },
})
