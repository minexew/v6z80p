
; Just tests that G and RX ! start with HL = argument location

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	call kjt_print_string	; show args at HL
	xor a
	ret
	
;--------------------------------------------------------------------------------------
