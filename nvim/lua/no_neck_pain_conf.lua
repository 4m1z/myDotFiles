local status, nnp = pcall(require, 'no-neck-pain')

if (not status) then
    print('no-neck-pain is not installed')
    return
end

nnp.setup({
    width = 120,
    autocmds = {
        enableOnVimEnter = false,
        enableOnTabEnter = true,
    },
})

-- Toggle no-neck-pain
vim.keymap.set('n', '<leader>np', '<cmd>NoNeckPain<CR>', { desc = 'Toggle NoNeckPain' })
