
; Tests reading of "alt_write_page"

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000


;----------------------------------------------------------------------------------------------------------

	di
	
	ld a,$55
	out (sys_alt_write_page),a
	xor a
	in a,(sys_alt_write_page)
	ld ($8000),a
	
	ld a,$aa
	out (sys_alt_write_page),a
	xor a
	in a,(sys_alt_write_page)
	ld ($8001),a
	
	xor a
	out (sys_alt_write_page),a
	
	ei
	
	xor a
	ret

;----------------------------------------------------------------------------------------------------------
		