
vim.keymap.set("n", "<leader>gg", function() vim.cmd.LazyGit() end, { silent = true })
vim.keymap.set("n", "<leader>gc", function() vim.cmd.CodeDiff() end, { silent = true })
vim.keymap.set("n", ";C", function() vim.cmd.LazyGitFilter() end, { silent = true })
