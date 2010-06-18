
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $8000

;=======================================================================================

	ld b,$00			;pen colour / loop count

testloop	push bc

	ld a,b
	call kjt_set_pen		;select pen colour
	
	ld hl,test_text		
	call kjt_print_string	;print ascii string routine

	pop bc

	inc b			;next pen colour
	
pen_ok	jr nz,testloop


	ld a,$07
	call kjt_set_pen		;select pen colour

	xor a			;no error on return 
	ret
	
;--------------------------------------------------------------------------------------
	
test_text	db "Hello World 8000! ",0

;--------------------------------------------------------------------------------------
