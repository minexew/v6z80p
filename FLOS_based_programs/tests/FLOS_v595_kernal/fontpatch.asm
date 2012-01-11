
; Tests the kjt_get/set_colours routines

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	ld hl,text
	call kjt_print_string
	
	ld hl,my_char
	ld a,128
	call kjt_patch_font
	ld hl,my_char2
	ld a,129
	call kjt_patch_font
	ld hl,text
	call kjt_print_string
	
	ret
	
;--------------------------------------------------------------------------------------

text	db "Char 128: ",128,11
	db "Char 129: ",129,11,0


my_char	db 255,129,129,129,129,129,129,255
my_char2	db $55,$aa,$55,$aa,$55,$aa,$55,$aa

	