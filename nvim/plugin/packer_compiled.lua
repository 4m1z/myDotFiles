-- Portable loader for Packer's generated machine-local plugin setup.
-- The generated file is stored under stdpath("state") by lua/plugins.lua;
-- it is deliberately not committed because Packer embeds absolute paths.
local generated = vim.fn.stdpath("state") .. "/packer_compiled.lua"
if vim.fn.filereadable(generated) == 1 then
	local ok, err = pcall(dofile, generated)
	if not ok then
		vim.notify("Packer generated config failed: " .. tostring(err), vim.log.levels.WARN)
	end
end
