
; Test low-level sector access routines

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	ld bc,0			;BC:DE = sector required
	ld de,0
	ld a,0			;A = device (0=SD_Card)
	call kjt_read_sector	
	ret
	
;--------------------------------------------------------------------------------------
