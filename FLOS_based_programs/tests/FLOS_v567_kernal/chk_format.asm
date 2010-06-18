
; Tests volume format detection routine

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	call kjt_check_volume_format
	jr nz,not_fat16

	ld hl,fat16_volume_txt
	call kjt_print_string
	xor a
	ret

not_fat16	ld hl,not_fat16_volume_txt
	call kjt_print_string
	xor a
	ret

;--------------------------------------------------------------------------------------

fat16_volume_txt

	db "Volume is FAT16",11,0
	

not_fat16_volume_txt

	db "Volume is NOT FAT16",11,0
	
;--------------------------------------------------------------------------------------