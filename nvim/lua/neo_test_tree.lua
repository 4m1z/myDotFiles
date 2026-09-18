local status, neotest = pcall(require, "neotest")
if not status then
	print("neotest is not installed")
	return
end

local neo_test_go_status, neo_test_go = pcall(require, "neotest-go")
if not neo_test_go_status then
	print("neotest-go is not installed")
	return
end

local neo_test_rust_status, neo_test_rust = pcall(require, "neotest-rust")
if not neo_test_rust_status then
	print("neotest-rust is not installed")
	return
end

neotest.setup({
	adapters = {
		neo_test_go({
			experimental = {
				test_table = true,
			},
			args = { "-count=1", "-timeout=60s" },
		}),
		neo_test_rust({
			args = { "--nocapture" },
		}),
	},
})

-- remaps
-- run the nearest test
vim.keymap.set("n", "<leader>tn", function()
	neotest.run.run()
end, { noremap = true, silent = true })

-- run the current file
vim.keymap.set("n", "<leader>ta", function()
	neotest.run.run(vim.fn.expand("%"))
end, { noremap = true, silent = true })

-- debug the nearest test
vim.keymap.set("n", "<leader>td", function()
	neotest.run.run({ strategy = "dap" })
end, { noremap = true, silent = true })
