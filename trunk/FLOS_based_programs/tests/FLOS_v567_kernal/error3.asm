

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

		
	ld b,$12			;should report driver error bits	
	ld a,1
	or a
	ld a,0
	ret


;--------------------------------------------------------------------------------------
