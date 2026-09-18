local ok, null_ls = pcall(require, "none-ls")
if not ok then
	return
end

null_ls.setup({
	sources = {
		null_ls.builtins.diagnostics.eslint_d.with({
			diagnostics_format = "[eslint] #{m}\n(#{c})",
		}),
		null_ls.builtins.diagnostics.misspell,
	},
})
