
; Tests volume format

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	ld hl,message_txt		;confirm op
	call kjt_print_string
	call kjt_get_input_string
	ld a,(hl)
	cp "Y"
	jr z,start
	xor a
	ret
	
start	ld hl,message2_txt		;ask what device		
	call kjt_print_string
	call kjt_get_input_string

	ld a,(hl)
	sub $30			;a = device
	ld hl,label_txt		;hl = label
	call kjt_format_device	
	ld ($8000),a
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

	db "Sure you want to format WHOLE DEVICE?",11,"(y/n)",11,0
	
message2_txt

	db 11,"Format what device? (0-3) ",0
	
	
ok_txt	db 11,"Operation successful!",11,0
	

bad_txt	db 11,"Operation failed!",11,0


label_txt	db "My_Test",0
		
	
;--------------------------------------------------------------------------------------