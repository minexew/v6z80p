
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	ld hl,test_text
	call kjt_print_string
	
	ld a,0
	ex af,af'
	ld a,$ff
	ex af,af'
	
	ld bc,$1234
	ld de,$5678
	ld hl,$9abc

	exx
	ld bc,$1111
	ld de,$2222
	ld hl,$3333
	exx
	
loop	call wibble
	jr loop
		
	xor a			;no error on return 
	ret


wibble	nop
	nop
	nop
	ret
		
;--------------------------------------------------------------------------------------
	
test_text	db "Press the button, Mr Locke.",0

;--------------------------------------------------------------------------------------
