local _, t = pcall(require, "trouble")

t.setup{}


vim.keymap.set("n", "<leader>di", "<cmd>Trouble diagnostics toggle<cr>")
vim.keymap.set("n", "<leader>dI", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>")
vim.keymap.set("n", "<leader>ds", "<cmd>Trouble symbols toggle focus=false<cr>")
vim.keymap.set("n", "<leader>df", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>")
vim.keymap.set("n", "<leader>dl", "<cmd>Trouble loclist toggle<cr>")
vim.keymap.set("n", "<leader>dq", "<cmd>Trouble qflist toggle<cr>")


