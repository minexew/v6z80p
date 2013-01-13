; Test set commander

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "\equates\kernal_jump_table.asm"
include "\equates\osca_hardware_equates.asm"
include "\equates\system_equates.asm"

	org $5000
	
	ld hl,commander_string
	call kjt_set_commander
	
;	ld hl,cancel_commander_string
;	call kjt_set_commander
	
	xor a
	ret
	
commander_string

	db "ECHO COMMANDER!",0
	
cancel_commander_string

	db 0
	