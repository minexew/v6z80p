;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "\equates\kernal_jump_table.asm"
include "\equates\osca_hardware_equates.asm"
include "\equates\system_equates.asm"

	org $5000
	
	ld hl,test_hex
	call kjt_ascii_to_hex32
	ret
	
test_hex	db "f3v.",0

