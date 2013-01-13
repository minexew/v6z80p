; Test launch string

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "\equates\kernal_jump_table.asm"
include "\equates\osca_hardware_equates.asm"
include "\equates\system_equates.asm"
	
	org $5000
	
	ld hl,launch_string
	ld a,$fe
	ret

launch_string

	db "ECHO LAUNCHED ON EXIT!",0
	
	