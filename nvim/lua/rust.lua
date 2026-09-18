--
-- DON't forget this =>  rustup component add rust-analyzer
--require('rust-tools').setup(opts)
local status, rs_tools = pcall(require, "rust-tools")
if not status then
	return
end

rs_tools.setup({
	-- rust-tools options
	tools = {
		autoSetHints = true,
		--hover_with_actions = true,
		on_attach = true,

		inlay_hints = {
			show_parameter_hints = true,
			parameter_hints_prefix = "",
			other_hints_prefix = "",
		},
	},

	-- all the opts to send to nvim-lspconfig
	-- these override the defaults set by rust-tools.nvim
	-- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
	-- https://rust-analyzer.github.io/manual.html#features
	server = {
		settings = {
			["rust-analyzer"] = {
				assist = {
					importEnforceGranularity = true,
					importPrefix = "crate",
				},
				cargo = {
					allFeatures = true,
				},
				checkOnSave = {
					-- default: `cargo check`
					command = "clippy",
				},
			},
			inlayHints = {
				lifetimeElisionHints = {
					enable = true,
					useParameterNames = true,
				},
			},
		},
	},
})

require("lspconfig").rust_analyzer.setup({
	capabilities = vim.lsp.protocol.make_client_capabilities(),
})
