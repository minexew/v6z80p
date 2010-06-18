
; Tests volume format detection routine

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	ld hl,message_txt		
	call kjt_print_string
	call kjt_get_input_string
	ld a,(hl)
	sub $30
	
	call kjt_change_volume	; volume to change to is in A
	jr nz,failed

	ld hl,ok_txt
	call kjt_print_string
	xor a
	ret

failed	ld hl,bad_txt
	call kjt_print_string
	xor a
	ret

;--------------------------------------------------------------------------------------

message_txt

	db "Enter a volume number to change to.. ",0
	
	
ok_txt	db 11,"Operation successful!",11,0
	

bad_txt	db 11,"Operation failed!",11,0
	
;--------------------------------------------------------------------------------------