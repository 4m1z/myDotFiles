local builtin = require('telescope.builtin')


-- keymaps
vim.keymap.set('n', ';f', builtin.find_files, {})
vim.keymap.set('n', ';g', builtin.git_files, {})
vim.keymap.set('n', ';c', builtin.git_status, {})


vim.keymap.set('n', '<leader>ps', function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") })
end)


vim.api.nvim_set_keymap('n', '<leader>im', [[<cmd>lua require'telescope'.extensions.goimpl.goimpl{}<CR>]],
    { noremap = true, silent = true })



vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})
vim.keymap.set('n', ';r', function()
    builtin.live_grep()
end)

vim.keymap.set('n', '<leader>prw', function()
    builtin.grep_string()
end)

vim.keymap.set('n', ';t', function()
    builtin.help_tags()
end)

vim.keymap.set('n', ';;', function()
    builtin.resume()
end)

vim.keymap.set('n', ';e', function()
    builtin.diagnostics()
end)
vim.keymap.set('n', '\\\\', function()
    builtin.buffers()
end)




