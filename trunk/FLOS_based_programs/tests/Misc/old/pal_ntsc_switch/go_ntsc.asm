
;---Standard header for V5Z80P and OS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

	ld a,%00000100
	out (sys_hw_settings),a		; enable 60Hz NTSC TV timing
	xor a
	ret
	