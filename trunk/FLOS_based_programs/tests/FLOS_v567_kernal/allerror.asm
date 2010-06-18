; returns a new error code each time it is run
; set $ffff to zero before first run


;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================


	ld a,($ffff)		
	inc a
	ld ($ffff),a
	
	or a			;should report normal OS error ("OK")
	ret	
	
