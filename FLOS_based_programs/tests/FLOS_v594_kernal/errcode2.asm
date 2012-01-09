
; Tests the kjt_get/set_colours routines

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	xor a
	inc a
	ld a,0
	ld b,$47	
	ret
	
;--------------------------------------------------------------------------------------

message_number	db 0