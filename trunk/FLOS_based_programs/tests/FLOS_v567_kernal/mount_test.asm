
; Test mount

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	ld hl,mount1
	call kjt_print_string
	ld a,0			;test mount with text output
	call kjt_mount_volumes
	
	ld hl,mount2
	call kjt_print_string
	ld a,1			;test mount without text output
	call kjt_mount_volumes

	ld hl,done
	call kjt_print_string

	xor a	
	ret
	
;--------------------------------------------------------------------------------------

mount1	db "Mount, with text output..",11,0

mount2	db "Mount, quietly..",11,0

done	db "OK, test done",11,0
