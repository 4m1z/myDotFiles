local status, nnp = pcall(require, 'no-neck-pain')

if (not status) then
    print('no-neck-pain is not installed')
    return
end

nnp.setup({
    width = 200,
    autocmds = {
        enableOnVimEnter = "safe",
        enableOnTabEnter = true,
        skipEnteringNoNeckPainBuffer = true,
    },
})

-- Toggle no-neck-pain, guarded against floating windows (tree/preview,
-- pickers). Toggling while focused in a float can miscount normal windows.
vim.keymap.set('n', '<leader>np', function()
    local ok, cfg = pcall(vim.api.nvim_win_get_config, vim.api.nvim_get_current_win())
    if ok and cfg.relative ~= "" then
        vim.notify("NoNeckPain: close the popup first", vim.log.levels.INFO)
        return
    end
    vim.cmd("NoNeckPain")
end, { desc = 'Toggle NoNeckPain' })
