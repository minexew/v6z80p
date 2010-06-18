
; Shows dir names to root

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================


my_loop	call kjt_get_dir_name	;returns 0-terminated string in HL
	ret nz
	
	call kjt_print_string
	
	call kjt_parent_dir
	jr z,my_loop
	
	xor a
	ret
	
;--------------------------------------------------------------------------------------
