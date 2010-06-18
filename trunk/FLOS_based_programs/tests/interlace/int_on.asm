
;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

	ld a,%00000100
	ld (vreg_ext_vidctrl),a		; enable interlace mode
	xor a
	ret

;-----------------------------------------------------------------------------
	