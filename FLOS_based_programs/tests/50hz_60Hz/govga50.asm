
;Force VGA mode to 50Hz

;---Standard header for V5Z80P and OS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

	ld a,%00001000
	out (sys_hw_settings),a		; enable 50Hz VGA mode timing
	xor a
	ret
	