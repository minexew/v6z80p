; Demonstration of displaying the error requester using the Load Requester library
;
; Requires FLOS v562
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------
	
	ld b,8			; x coord of requester (in characters)
	ld c,2			; y coord ""
	ld hl,my_filename		; default filename

	call load_requester
	
	call hw_error_requester	; we dont care about the real disk return code
				; we're just forcing the appearance of the requester here.
	xor a
	ret
	
	
;----------------------------------------------------------------------------
include	"requesters\inc\file_requesters.asm"
;----------------------------------------------------------------------------

my_filename

	db "Blah.txt",0
	
	
load_buffer

	db 0

;---------------------------------------------------------------------------	
	


