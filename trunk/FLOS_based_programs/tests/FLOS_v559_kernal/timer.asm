
; wait with os timer

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================


	ld hl,message
	call kjt_print_string

	ld b,244
lp1	xor a
	call kjt_timer_wait
	djnz lp1

	ld hl,message2
	call kjt_print_string
	xor a
	ret
	
		
message   db "Should pause a second..",11,11,0

message2  db "There we go..",0

;--------------------------------------------------------------------------------------
