local status, rs_tools = pcall(require, "rust-tools")
if not status then
	return
end

rs_tools.setup({
	-- rust-tools options
	tools = {
		autoSetHints = false,
		--hover_with_actions = true,

		inlay_hints = {
			auto = false,
			show_parameter_hints = false,
			parameter_hints_prefix = "",
			other_hints_prefix = "",
		},
	},

	-- all the opts to send to nvim-lspconfig
	-- these override the defaults set by rust-tools.nvim
	-- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
	-- https://rust-analyzer.github.io/manual.html#features
	server = {
		on_attach = function(_, bufnr)
			-- rust-tools/native inlay hints back on via auto/native defaults,
			-- so force them off for this buffer
			pcall(vim.lsp.inlay_hint.enable, false, { bufnr = bufnr })
			pcall(function()
				require("rust-tools").inlay_hints.disable_inlay_hints()
			end)
			local opts = { buffer = bufnr, remap = false }
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
			vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
			vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
			vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
			vim.keymap.set("n", "[d", function()
				vim.diagnostic.jump({ count = -1, float = true })
			end, opts)
			vim.keymap.set("n", "]d", function()
				vim.diagnostic.jump({ count = 1, float = true })
			end, opts)
			vim.keymap.set("n", "<leader>va", vim.lsp.buf.code_action, opts)
			vim.keymap.set("n", "<leader>r", vim.lsp.buf.references, opts)
			vim.keymap.set("n", "<leader>vr", vim.lsp.buf.rename, opts)
		end,
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
				inlayHints = {
					enable = false,
					parameterHints = { enable = false },
					typeHints = { enable = false },
					chainingHints = { enable = false },
					lifetimeElisionHints = {
						enable = false,
						useParameterNames = false,
					},
				},
			},
		},
	},
})

