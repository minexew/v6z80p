
; Shows all key flags 

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================


	ld hl,message
	call kjt_print_string
	
loopback	call kjt_wait_key_press
	cp $76
	jr z,quit
	
	call kjt_get_key_mod_flags	;returns shift status in A
	
	ld hl,byte
	call kjt_hex_byte_to_ascii
	
	ld hl,byte
	call kjt_print_string
	jr loopback

quit	xor a
	ret
	
	
byte 	db "00",11,0
	
message   db "Press keys, qualifier key status",11,"is reported..",11,11,0

;--------------------------------------------------------------------------------------
