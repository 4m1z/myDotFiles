-- Centered floating nvim-tree + isolated scratch preview.
-- Keeps the existing tree workflow; only the presentation changes.
-- The preview uses a `nofile` scratch buffer so nvim-tree never treats
-- it as a real file window when opening selections.

local M = {}

local api_ok, api = pcall(require, "nvim-tree.api")
if not api_ok then
	api = nil
end

-- tabpage id -> { win = winid|nil, buf = bufnr|nil, origin = winid|nil }
local previews = {}
local subscribed = false

local MAX_PREVIEW_LINES = 200
local MAX_PREVIEW_BYTES = 500 * 1024

local function is_valid_win(win)
	return type(win) == "number" and vim.api.nvim_win_is_valid(win)
end

local function is_valid_buf(buf)
	return type(buf) == "number" and vim.api.nvim_buf_is_valid(buf)
end

local function current_tab()
	return vim.api.nvim_get_current_tabpage()
end

local function get_state(tab)
	tab = tab or current_tab()
	local st = previews[tab]
	if not st then
		st = {}
		previews[tab] = st
	end
	return st
end

-- Compute a centered combined tree+preview rectangle.
-- Returns nil when the screen is too small to be useful.
function M.layout()
	local columns = vim.o.columns
	local lines = vim.o.lines
	local cmdheight = vim.o.cmdheight
	-- Keep one row for the command line and one for safety/statusline.
	local available_h = lines - cmdheight - 2
	if columns < 40 or available_h < 12 then
		return nil
	end

	local total_w = math.min(math.floor(columns * 0.8), 160)
	total_w = math.min(total_w, columns - 4)
	local total_h = math.floor(available_h * 0.75)
	total_h = math.min(total_h, available_h - 1)
	if total_w < 50 or total_h < 12 then
		return nil
	end

	local row = math.floor((available_h - total_h) / 2)
	local col = math.floor((columns - total_w) / 2)
	if row < 0 then
		row = 0
	end
	if col < 0 then
		col = 0
	end

	-- Narrow screens: stack tree above preview instead of side-by-side.
	if columns < 100 or total_w < 80 then
		local tree_outer_h = math.floor(total_h * 0.5)
		local preview_outer_h = total_h - tree_outer_h - 1
		if tree_outer_h < 6 or preview_outer_h < 5 then
			return nil
		end
		return {
			stacked = true,
			row = row,
			col = col,
			total_w = total_w,
			total_h = total_h,
			tree = {
				row = row,
				col = col,
				width = total_w - 2,
				height = tree_outer_h - 2,
			},
			preview = {
				row = row + tree_outer_h + 1,
				col = col,
				width = total_w - 2,
				height = preview_outer_h - 2,
			},
		}
	end

	local tree_outer_w = math.floor(total_w * 0.38)
	-- One column gap between the two floats.
	local preview_outer_w = total_w - tree_outer_w - 1
	if tree_outer_w < 24 or preview_outer_w < 24 then
		return nil
	end

	return {
		stacked = false,
		row = row,
		col = col,
		total_w = total_w,
		total_h = total_h,
		tree = {
			row = row,
			col = col,
			width = tree_outer_w - 2,
			height = total_h - 2,
		},
		preview = {
			row = row,
			col = col + tree_outer_w + 1,
			width = preview_outer_w - 2,
			height = total_h - 2,
		},
	}
end

-- Config callback used by `view.float.open_win_config`.
function M.tree_win_config()
	local l = M.layout()
	if not l then
		return {
			relative = "editor",
			border = "rounded",
			style = "minimal",
			width = 40,
			height = 20,
			row = 2,
			col = 2,
		}
	end
	return {
		relative = "editor",
		border = "rounded",
		style = "minimal",
		width = l.tree.width,
		height = l.tree.height,
		row = l.tree.row,
		col = l.tree.col,
	}
end

function M.remember_origin()
	local win = vim.api.nvim_get_current_win()
	local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
	if not ok then
		return
	end
	-- Never treat a float (tree, preview, picker) as the editor origin.
	if cfg.relative ~= "" then
		return
	end
	local buf = vim.api.nvim_win_get_buf(win)
	if vim.bo[buf].buftype ~= "" then
		return
	end
	get_state().origin = win
end

local function close_preview_win(st)
	if st and is_valid_win(st.win) then
		pcall(vim.api.nvim_win_close, st.win, true)
	end
	if st then
		st.win = nil
	end
end

function M.close_preview(tab)
	local st = previews[tab or current_tab()]
	if not st then
		return
	end
	close_preview_win(st)
	if is_valid_buf(st.buf) then
		pcall(vim.api.nvim_buf_delete, st.buf, { force = true })
	end
	st.buf = nil
end

local function ensure_preview_buf(st)
	if is_valid_buf(st.buf) then
		return st.buf
	end
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].buflisted = false
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
	st.buf = buf
	return buf
end

local function set_preview_lines(buf, lines, ft)
	vim.bo[buf].modifiable = true
	pcall(vim.api.nvim_buf_set_lines, buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	if ft and ft ~= "" and vim.bo[buf].filetype ~= ft then
		pcall(function()
			vim.bo[buf].filetype = ft
		end)
	end
end

local function loaded_buffer_lines(abs_path)
	local target = vim.fn.fnamemodify(abs_path, ":p")
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) then
			local name = vim.api.nvim_buf_get_name(buf)
			if name ~= "" and vim.fn.fnamemodify(name, ":p") == target then
				local ok, lines = pcall(vim.api.nvim_buf_get_lines, buf, 0, MAX_PREVIEW_LINES, false)
				if ok and lines and #lines > 0 then
					return lines
				end
			end
		end
	end
	return nil
end

local function preview_content_for(node)
	if not node or not node.absolute_path then
		return { "-- no preview --" }, nil, "No preview"
	end
	local abs_path = node.absolute_path
	local stat_ok, stat = pcall(vim.uv.fs_stat, abs_path)
	if not stat_ok or not stat then
		return { "-- unreadable --" }, nil, vim.fn.fnamemodify(abs_path, ":t")
	end

	if stat.type == "directory" then
		local ok, entries = pcall(vim.fn.readdir, abs_path)
		if not ok or type(entries) ~= "table" then
			return { "-- unreadable directory --" }, nil, vim.fn.fnamemodify(abs_path, ":t") .. "/"
		end
		local dirs, files = {}, {}
		for _, name in ipairs(entries) do
			if vim.fn.isdirectory(abs_path .. "/" .. name) == 1 then
				table.insert(dirs, name .. "/")
			else
				table.insert(files, name)
			end
		end
		table.sort(dirs)
		table.sort(files)
		local lines = { vim.fn.fnamemodify(abs_path, ":t") .. "/" }
		for _, name in ipairs(dirs) do
			table.insert(lines, "  " .. name)
			if #lines >= MAX_PREVIEW_LINES then
				break
			end
		end
		for _, name in ipairs(files) do
			table.insert(lines, "  " .. name)
			if #lines >= MAX_PREVIEW_LINES then
				break
			end
		end
		if #lines == 1 then
			table.insert(lines, "  <empty>")
		end
		return lines, nil, vim.fn.fnamemodify(abs_path, ":t") .. "/"
	end

	if stat.type == "link" then
		local target = vim.fn.resolve(abs_path)
		return { (node.name or abs_path) .. " -> " .. target }, nil, node.name or "link"
	end

	if stat.type ~= "file" then
		return { node.name .. " (" .. stat.type .. ")" }, nil, node.name or "preview"
	end

	if stat.size > MAX_PREVIEW_BYTES then
		return { "<file too large to preview>" }, nil, vim.fn.fnamemodify(abs_path, ":t")
	end

	-- Prefer in-memory contents so unsaved edits are visible.
	local mem_lines = loaded_buffer_lines(abs_path)
	if mem_lines then
		local ft = vim.filetype.match({ filename = abs_path })
		return mem_lines, ft, vim.fn.fnamemodify(abs_path, ":t")
	end

	local ok, lines = pcall(vim.fn.readfile, abs_path, "", MAX_PREVIEW_LINES)
	if not ok or type(lines) ~= "table" then
		return { "-- unreadable file --" }, nil, vim.fn.fnamemodify(abs_path, ":t")
	end
	if #lines == 0 then
		return { "<empty file>" }, vim.filetype.match({ filename = abs_path }), vim.fn.fnamemodify(abs_path, ":t")
	end
	-- Cheap binary guard: NUL byte in the first lines.
	for i = 1, math.min(#lines, 5) do
		if lines[i]:find("\0", 1, true) then
			return { "<binary file>" }, nil, vim.fn.fnamemodify(abs_path, ":t")
		end
	end
	return lines, vim.filetype.match({ filename = abs_path }), vim.fn.fnamemodify(abs_path, ":t")
end

function M.update_preview()
	if api == nil then
		return
	end
	local tree_win = nil
	pcall(function()
		tree_win = api.tree.winid()
	end)
	if not is_valid_win(tree_win) then
		return
	end
	-- Only update while focus is in the tree or our own preview.
	local cur = vim.api.nvim_get_current_win()
	local st = get_state()
	if cur ~= tree_win and cur ~= st.win then
		return
	end

	local ok, node = pcall(api.tree.get_node_under_cursor)
	if not ok or not node then
		M.close_preview()
		return
	end

	local l = M.layout()
	if not l then
		M.close_preview()
		return
	end

	local buf = ensure_preview_buf(st)
	local lines, ft, title = preview_content_for(node)
	set_preview_lines(buf, lines, ft)

	local cfg = {
		relative = "editor",
		style = "minimal",
		border = "rounded",
		focusable = false,
		width = l.preview.width,
		height = l.preview.height,
		row = l.preview.row,
		col = l.preview.col,
		title = title and (" " .. title .. " ") or nil,
		title_pos = "center",
	}
	if is_valid_win(st.win) then
		pcall(vim.api.nvim_win_set_config, st.win, cfg)
		pcall(vim.api.nvim_win_set_buf, st.win, buf)
	else
		local win_ok, win = pcall(vim.api.nvim_open_win, buf, false, cfg)
		if win_ok and is_valid_win(win) then
			st.win = win
			pcall(function()
				vim.wo[win].wrap = false
				vim.wo[win].number = false
				vim.wo[win].relativenumber = false
				vim.wo[win].signcolumn = "no"
				vim.wo[win].cursorline = false
				vim.wo[win].scrolloff = 0
			end)
		end
	end
end

function M.recenter()
	if api == nil then
		return
	end
	local tree_win = nil
	pcall(function()
		tree_win = api.tree.winid()
	end)
	local st = get_state()
	local l = M.layout()
	if not l then
		return
	end
	if is_valid_win(tree_win) then
		pcall(vim.api.nvim_win_set_config, tree_win, {
			relative = "editor",
			style = "minimal",
			border = "rounded",
			width = l.tree.width,
			height = l.tree.height,
			row = l.tree.row,
			col = l.tree.col,
		})
	end
	if is_valid_win(st.win) and is_valid_buf(st.buf) then
		pcall(vim.api.nvim_win_set_config, st.win, {
			relative = "editor",
			style = "minimal",
			border = "rounded",
			width = l.preview.width,
			height = l.preview.height,
			row = l.preview.row,
			col = l.preview.col,
		})
	end
end

-- `q` inside the tree: close preview first, then the tree, then go home.
function M.close_from_tree()
	if api == nil then
		return
	end
	local tab = current_tab()
	local st = get_state(tab)
	local origin = st.origin
	M.close_preview(tab)
	pcall(api.tree.close)
	-- TreeClose autocmd also cleans up; keep this idempotent.
	M.close_preview(tab)
	if is_valid_win(origin) then
		local ok, cfg = pcall(vim.api.nvim_win_get_config, origin)
		if ok and cfg.relative == "" then
			pcall(vim.api.nvim_set_current_win, origin)
			return
		end
	end
	-- Fallback: focus the first normal window in this tab.
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
		if vim.api.nvim_win_is_valid(win) then
			local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
			if ok and cfg.relative == "" then
				local buf = vim.api.nvim_win_get_buf(win)
				if vim.bo[buf].buftype == "" then
					pcall(vim.api.nvim_set_current_win, win)
					return
				end
			end
		end
	end
end

function M.open_find_file()
	if api == nil then
		vim.cmd("NvimTreeFindFile")
		return
	end
	M.remember_origin()
	pcall(api.tree.find_file, { open = true, focus = true })
	vim.schedule(function()
		M.update_preview()
	end)
end

function M.open_on_directory(dirname)
	if api == nil or type(dirname) ~= "string" or vim.fn.isdirectory(dirname) == 0 then
		return
	end
	local dir_buf = vim.api.nvim_get_current_buf()
	local dir_name = vim.api.nvim_buf_get_name(dir_buf)
	M.remember_origin()
	pcall(api.tree.open, { path = dirname })
	vim.schedule(function()
		M.update_preview()
		-- Replace the leftover directory buffer behind the popup so closing
		-- the popup reveals a normal empty editor, not a directory listing.
		if
			is_valid_buf(dir_buf)
			and vim.api.nvim_buf_get_name(dir_buf) == dir_name
			and vim.fn.isdirectory(dir_name) == 1
		then
			local replaced = false
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_is_valid(win) then
					local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
					if ok and cfg.relative == "" and vim.api.nvim_win_get_buf(win) == dir_buf then
						pcall(vim.api.nvim_win_call, win, function()
							vim.cmd("enew")
						end)
						replaced = true
					end
				end
			end
			if replaced then
				pcall(vim.api.nvim_buf_delete, dir_buf, { force = true })
			end
		end
	end)
end

function M.setup()
	if api == nil then
		local ok, mod = pcall(require, "nvim-tree.api")
		if ok then
			api = mod
		end
	end
	if subscribed or api == nil then
		return
	end
	subscribed = true

	local group = vim.api.nvim_create_augroup("NvimTreePopup", { clear = true })

	-- Keep preview in sync while browsing. Scheduled + guarded so fast
	-- cursor movement cannot reopen a closed popup from a stale event.
	vim.api.nvim_create_autocmd("CursorMoved", {
		group = group,
		pattern = "NvimTree_*",
		callback = function()
			vim.schedule(function()
				M.update_preview()
			end)
		end,
	})

	vim.api.nvim_create_autocmd("VimResized", {
		group = group,
		callback = function()
			vim.schedule(function()
				M.recenter()
			end)
		end,
	})

	-- Uniform popup for `nvim .`: nvim-tree's own directory hijack is
	-- disabled in our setup (it opens docked), so bridge it to the float.
	vim.api.nvim_create_autocmd({ "BufEnter", "BufNewFile" }, {
		group = group,
		callback = function(ev)
			if not is_valid_buf(ev.buf) then
				return
			end
			local ft = vim.bo[ev.buf].filetype
			if ft == "NvimTree" or ft == "no-neck-pain" then
				return
			end
			local name = vim.api.nvim_buf_get_name(ev.buf)
			if name == "" or vim.fn.isdirectory(name) == 0 then
				return
			end
			-- Avoid fighting nvim-tree internals while it is already open.
			local visible = false
			pcall(function()
				visible = api.tree.is_visible()
			end)
			if visible then
				return
			end
			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(ev.buf) then
					return
				end
				if vim.api.nvim_get_current_buf() ~= ev.buf then
					return
				end
				M.open_on_directory(name)
			end)
		end,
	})

	local Event = api.events and api.events.Event or nil
	if Event then
		pcall(api.events.subscribe, Event.TreeOpen, function()
			vim.schedule(function()
				M.update_preview()
			end)
		end)
		pcall(api.events.subscribe, Event.TreeRendered, function()
			vim.schedule(function()
				M.update_preview()
			end)
		end)
		pcall(api.events.subscribe, Event.TreeClose, function()
			vim.schedule(function()
				-- Close previews in every tab whose tree just went away.
				for tab, st in pairs(previews) do
					local win = nil
					pcall(function()
						win = api.tree.winid({ tabpage = tab })
					end)
					if not is_valid_win(win) then
						M.close_preview(tab)
						if st then
							st.origin = nil
						end
					end
				end
			end)
		end)
	end
end

return M
