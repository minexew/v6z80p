
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	
	xor a
	ld a,$fe			; spawn
	ld hl,comline
	ret


;--------------------------------------------------------------------------------------

comline	db "cd hats",0