local ok, opencode = pcall(require, "opencode")
if not ok then
	return
end

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

-- Tmux prefix+y handoff: publish visual selection to the current tmux pane.
-- Normal mode publishes nothing (prefix+y stays as-is, empty box).
-- Visual mode publishes pane-local @opencode_context="visual:/abs/file:S-E"
-- plus @opencode_context_at=epoch; launch.sh consumes it when fresh and
-- opens a NEW opencode session prefilled via `opencode --prompt`.
do
	if vim.env.TMUX_PANE == nil then
		return
	end

	local group = vim.api.nvim_create_augroup("OpencodeTmuxContext", { clear = true })

	local function tmux_set(opt, val)
		vim.fn.jobstart({ "tmux", "set-option", "-p", opt, val }, { detach = true })
	end

	local function publish()
		local mode = vim.fn.mode()
		if not mode:match("[vV\22]") then
			return
		end
		local file = vim.fn.expand("%:p")
		if file == nil or file == "" then
			return
		end
		local s = vim.fn.line("v")
		local e = vim.fn.line(".")
		if s > e then
			s, e = e, s
		end
		tmux_set("@opencode_context", string.format("visual:%s:%d-%d", file, s, e))
		tmux_set("@opencode_context_at", tostring(os.time()))
	end

	local function clear()
		tmux_set("@opencode_context", "")
		tmux_set("@opencode_context_at", "0")
	end

	-- Entering/updating visual selection.
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		pattern = "*:[vV\22]*",
		callback = publish,
	})
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorHold" }, {
		group = group,
		callback = publish,
	})
	-- Leaving visual -> normal press must behave as before (no prefill).
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		pattern = "[vV\22]*:*",
		callback = clear,
	})
	vim.api.nvim_create_autocmd("VimLeave", {
		group = group,
		callback = clear,
	})
end
