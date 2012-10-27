
; Shows key flags and scancodes without waiting

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================


	ld hl,message
	call kjt_print_string

	ld b,0
loopback	
	
	push bc
	
	call kjt_get_key_mod_flags	;returns shift status in A
	
	ld hl,byte
	call kjt_hex_byte_to_ascii
	
	ld hl,byte
	call kjt_print_string
	
	call kjt_get_key
	
	ld hl,byte2
	call kjt_hex_byte_to_ascii
	
	ld hl,byte2
	call kjt_print_string
	
	pop bc
	djnz loopback

quit	xor a
	ret
	
	
byte 	db "00 - ",0
byte2	db "00 ",11,0
	
message   db "Qualifier and keycode reported.",11,11,0

;--------------------------------------------------------------------------------------
