-- Launch or focus Speedy in a dedicated Foot window.
o.bind("SUPER + SHIFT + I", "Speedy", 'omarchy-launch-or-focus SpeedyApp "uwsm app -- foot --app-id SpeedyApp --title Speedy $HOME/.cargo/bin/speedy"')

-- Notes webapp (https://amirahmadzadeh.com/p/notes, launcher name "note").
-- Takes over SUPER + SHIFT + W from Omawrite; focuses the window on repeat.
hl.unbind("SUPER + SHIFT + W")
o.bind("SUPER + SHIFT + W", "Notes", { webapp = "https://amirahmadzadeh.com/p/notes", focus = true })

-- Centered floating Notes window with a reasonable desktop size.
o.window("chrome-amirahmadzadeh\\.com__p_notes-Default", { float = true, center = true, size = { 1200, 800 } })
