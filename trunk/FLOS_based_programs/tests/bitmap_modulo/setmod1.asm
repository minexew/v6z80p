;writes a modulo value that skips alternate lines on FLOS display
;
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000
	
	
;-----------------------------------------------------------------------------

	ld a,40/2				;skip 40 bytes at end of lines
	ld (bitplane_modulo),a
	
	xor a				;return to FLOS
	ret	
	
;------------------------------------------------------------------------------
