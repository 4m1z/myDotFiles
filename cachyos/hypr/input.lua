-- English, Persian and German, cycled with Alt + Shift.
-- grp_led:caps lights the Caps Lock LED while a non-first layout is
-- active, so it is obvious which one you are typing in.
hl.config({
	input = {
		kb_layout = "us,ir,de",
		kb_options = "compose:caps,shift:both_capslock_cancel,grp:alt_shift_toggle,grp_led:caps",
	},
})
