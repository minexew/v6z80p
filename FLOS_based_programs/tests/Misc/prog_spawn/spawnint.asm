
; This spawns an internal command on exit...


;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================


	ld hl,test_txt
	call kjt_print_string

;         ...
;         ...
;         ...
	
	xor a			;clear carry = no disk h/w error
	ld a,$fe			;A = $FE launch new command from string at HL
	ld hl,command_txt		;location of command string
	ret
	
;--------------------------------------------------------------------------------------
	
test_txt	db 11,11,"This program has run and quit.. ",11,0

command_txt db "COLOUR 7 333 444 f80",0

;--------------------------------------------------------------------------------------
