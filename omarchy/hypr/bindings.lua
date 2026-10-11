-- Launch or focus Speedy in a dedicated Foot window.
o.bind("SUPER + SHIFT + I", "Speedy", 'omarchy-launch-or-focus SpeedyApp "uwsm app -- foot --app-id SpeedyApp --title Speedy $HOME/.cargo/bin/speedy"')

-- Notes webapp (https://amirahmadzadeh.com/p/notes, launcher name "note").
local notes_class = "chrome-amirahmadzadeh.com__p_notes-Default"
local notes_workspace = "special:notes-hidden"

-- Restore the running window so the selected note and editor stay intact.
-- Takes over SUPER + SHIFT + W from Omawrite.
hl.unbind("SUPER + SHIFT + W")
o.bind("SUPER + SHIFT + W", "Notes", function()
  for _, window in ipairs(hl.get_windows()) do
    if window.class == notes_class then
      if window.workspace.name == notes_workspace then
        hl.dispatch(hl.dsp.window.move({ window = window, workspace = hl.get_active_workspace(), follow = false }))
      end
      hl.dispatch(hl.dsp.focus({ window = window }))
      return
    end
  end
  hl.dispatch(hl.dsp.exec_cmd(o.launch_webapp("https://amirahmadzadeh.com/p/notes")))
end)

-- SUPER + W hides Notes; the header's close button still really closes it.
-- Other applications retain Omarchy's normal close-window behavior.
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window (hide Notes)", function()
  local window = hl.get_active_window()
  if window and window.class == notes_class then
    hl.dispatch(hl.dsp.window.move({ window = window, workspace = notes_workspace, follow = false }))
  else
    hl.dispatch(hl.dsp.window.close())
  end
end)

-- Centered floating Notes window with a reasonable desktop size.
o.window("chrome-amirahmadzadeh\\.com__p_notes-Default", { float = true, center = true, size = { 1200, 800 } })
