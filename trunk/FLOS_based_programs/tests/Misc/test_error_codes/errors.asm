
;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000
	
	
	ld a,(codebyte)
	inc a
	ld (codebyte),a
	ret
	
codebyte	db 0

