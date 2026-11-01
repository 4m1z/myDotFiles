-- English, Persian and German, cycled with Alt + Shift.
-- grp_led:scroll lights the Scroll Lock LED while a non-first layout is
-- active, so it is obvious which one you are typing in. The Caps Lock LED
-- stays reserved for Caps Lock itself.
-- Never re-add compose:caps or shift:both_capslock_cancel: they move the
-- Caps Lock function off the Caps Lock key onto Shift, and Shift is half
-- of the Alt + Shift language shortcut, so the layout stops switching.
hl.config({
	input = {
		kb_layout = "us,ir,de",
		kb_options = "grp:alt_shift_toggle,grp_led:scroll",
	},
})
