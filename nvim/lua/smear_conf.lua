local status, smear = pcall(require, "smear_cursor")

if not status then
	return
end

smear.setup({
	-- Zed-like smooth caret glide (less smear trail than default)
	smear_between_buffers = true,
	smear_between_neighbor_lines = true,
	scroll_buffer_space = true,
	smear_insert_mode = true,
})
