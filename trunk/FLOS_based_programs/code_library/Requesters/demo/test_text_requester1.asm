;-----------------------------------------------------------------------------
; Demo of using "message_requester.asm"
;-----------------------------------------------------------------------------
;
; Requires FLOS v562
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"


	org $5000

;------------------------------------------------------------------------------
	
	ld b,8			;x coord of window
	ld c,2			;y coord of window
	ld d,15			;x size in chars
	ld e,5			;y size in chars
	ld hl,my_text		;location of text for window
	call message_requester	
	xor a
	ret


my_text	db "Here is some text for the requester",0
		
;---------------------------------------------------------------------------------

	include "message_requester.asm"
	
;---------------------------------------------------------------------------------


