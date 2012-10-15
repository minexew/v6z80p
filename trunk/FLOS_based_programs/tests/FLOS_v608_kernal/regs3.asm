;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "\equates\kernal_jump_table.asm"
include "\equates\osca_hardware_equates.asm"
include "\equates\system_equates.asm"

	org $5000
	
	ld a,$5
	call kjt_set_bank
	
	call kjt_page_in_video
	
my_loop	inc bc
	jp my_loop
	
	
	