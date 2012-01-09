
; Tests the kjt_get/set_colours routines

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	ld a,(message_number)
	inc a
	ld (message_number),a
	or a
	ret
	
;--------------------------------------------------------------------------------------

message_number	db 0