local ok, preview = pcall(require, "preview")
if not ok then
	return
end

preview.setup()
