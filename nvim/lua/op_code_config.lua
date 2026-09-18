local opencode = require("opencode")

local opencode_buf = nil
local opencode_win = nil

local function open_opencode_float()
    if opencode_win and vim.api.nvim_win_is_valid(opencode_win) then
        vim.api.nvim_win_close(opencode_win, true)
        opencode_win = nil
        return
    end

    local width = math.floor(vim.o.columns * 0.85)
    local height = math.floor(vim.o.lines * 0.85)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    if not opencode_buf or not vim.api.nvim_buf_is_valid(opencode_buf) then
        opencode_buf = vim.api.nvim_create_buf(false, true)

        vim.api.nvim_buf_call(opencode_buf, function()
            vim.fn.termopen("opencode")
        end)
    end

    opencode_win = vim.api.nvim_open_win(opencode_buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })

    vim.cmd("startinsert")
end

vim.keymap.set("n", "<leader>oo", open_opencode_float, { desc = "Toggle OpenCode Float" })

vim.keymap.set("n", "<leader>oa", function()
    opencode.ask()
end, { desc = "Ask OpenCode" })

vim.keymap.set("v", "<leader>oa", function()
    opencode.prompt("Ask about @this")
end, { desc = "Ask OpenCode Selection" })

vim.keymap.set("n", "<leader>or", function()
    opencode.prompt("Review @buffer")
end, { desc = "Review buffer" })

vim.keymap.set("n", "<leader>of", function()
    opencode.prompt("Fix @diagnostics")
end, { desc = "Fix diagnostics" })

vim.keymap.set("n", "<leader>og", function()
    opencode.prompt("Review @diff")
end, { desc = "Review git diff" })
