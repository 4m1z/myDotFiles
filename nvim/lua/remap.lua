vim.g.mapleader = " "
vim.g.localmapleader = " "
vim.keymap.set("n", "sf", "<cmd>NvimTreeFindFile<CR>")

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "<leader>vwm", function()
    require("vim-with-me").StartVimWithMe()
end)
vim.keymap.set("n", "<leader>svwm", function()
    require("vim-with-me").StopVimWithMe()
end)

-- greatest remap ever
vim.keymap.set("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- This is going to get me cancelled
vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)


vim.api.nvim_command("autocmd BufWritePre *.go lua vim.lsp.buf.format()")
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.cpp,*.h",
  callback = function() vim.lsp.buf.format() end,
})


vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set("n", "<leader>mr", "<cmd>CellularAutomaton make_it_rain<CR>");

vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end)


vim.keymap.set("n", "<leader>h", "<cmd>wincmd h<CR>")
vim.keymap.set("n", "<leader>j", "<cmd>wincmd j<CR>")
vim.keymap.set("n", "<leader>k", "<cmd>wincmd k<CR>")
vim.keymap.set("n", "<leader>l", "<cmd>wincmd l<CR>")

vim.keymap.set("n", "<leader>+", "<cmd>vertical resize +5<CR>")
vim.keymap.set("n", "<leader>-", "<cmd>vertical resize -5<CR>")
vim.keymap.set("n", "<leader>rp", "<cmd>vertical resize 100<CR>")

vim.keymap.set("n", "<leader>u", "<cmd>UndotreeShow<CR>")





vim.cmd('cnoreabbrev W! w!')
vim.cmd('cnoreabbrev Q! q!')
vim.cmd('cnoreabbrev Qall! qall!')
vim.cmd('cnoreabbrev Wq wq')
vim.cmd('cnoreabbrev Wa wa')
vim.cmd('cnoreabbrev wQ wq')
vim.cmd('cnoreabbrev WQ wq')
vim.cmd('cnoreabbrev W w')
vim.cmd('cnoreabbrev W1 w')
vim.cmd('cnoreabbrev w1 w')
vim.cmd('cnoreabbrev Q q')
vim.cmd('cnoreabbrev Qall qall')


vim.keymap.set("n", "<leader>a", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<CR>")
vim.keymap.set("n", "<leader>m", "<cmd>lua require('harpoon.mark').add_file()<CR>")



function generateErrorCheck()
    local current_line = vim.api.nvim_win_get_cursor(0)[1]

    local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]

    if line_content:match("^%s*$") then
        vim.api.nvim_buf_set_lines(0, current_line - 1, current_line, false, {
            "if err != nil {",
            "    ",
            "}"
        })

        vim.api.nvim_win_set_cursor(0, {current_line + 1, 5})
    else
        vim.api.nvim_command("normal! o")
        vim.api.nvim_buf_set_lines(0, current_line, current_line, false, {
            "if err != nil {",
            "    ",
            "}"
        })

        vim.api.nvim_win_set_cursor(0, {current_line + 1, 5})
    end
end

vim.api.nvim_set_keymap('n', '<Leader>ee', ':lua generateErrorCheck()<CR>', { noremap = true, silent = true })
