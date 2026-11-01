-- Workspaces 1..10 always exist.
--
-- The official CachyOS config only declares workspaces 1..3, so jumping to
-- an unused workspace (SUPER + 0 -> workspace 10) did nothing and a window
-- could not be moved there. `persistent = true` creates every workspace at
-- startup and keeps it alive, so focus and move work on any of them.
for workspace = 1, 10 do
	local rule = {
		workspace = tostring(workspace),
		monitor = MONITOR1,
		persistent = true,
	}
	if workspace == 1 then
		rule.default = true
	end
	hl.workspace_rule(rule)
end
