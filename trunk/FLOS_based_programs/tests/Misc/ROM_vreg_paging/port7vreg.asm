
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

; Tests port 7 - mirror of VREG_READ in OSCA v656+
; Horizontal lines should appear in border 
; (no escape)

;=======================================================================================


loop	in a,(7)
	ld (palette),a
	jr loop
		
	
;--------------------------------------------------------------------------------------
	
