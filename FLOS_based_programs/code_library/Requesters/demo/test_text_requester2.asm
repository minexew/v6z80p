;-----------------------------------------------------------------------------
; Demo of using "message_requester.asm" to show disk error messages
;-----------------------------------------------------------------------------
;
;Requires FLOS v562
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------

	ld a,$25			;example error code in A
	ld b,3			;x coord of window
	ld c,2			;y coord of window
	call show_req1
	
	ld b,16			;x coord of window
	ld c,10			;y coord of window
	call show_req2
	xor a
	ret
	
;------------------------------------------------------------------------------
	
show_req1

	ld d,17			;x size in chars
	ld e,5			;y size in chars
	ld hl,text1		;location of text for window
	call message_requester	
	ret
	
		
show_req2
	ld d,13			;x size in chars
	ld e,2			;y size in chars
	ld hl,text2		;location of text for window
	call message_requester	
	ret
	

text1	db "   A Requester",11,11," With some text",11,"  in it.. Wow!",11,"    Crikey!",0

text2	db " And another",11,"     One!",0
		
;---------------------------------------------------------------------------------

	include	"requesters\inc\message_requester.asm"
	
;---------------------------------------------------------------------------------


