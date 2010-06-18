; Demonstration of displaying the error requesters in the Load Requester library
;
; Requires FLOS v562
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------
	
	ld b,8			; x coord of requester (in characters)
	ld c,2			; y coord ""
	ld hl,my_filename		; default filename

	call load_requester
	
	call file_error_requester	; we dont care about the real disk return code
				; we're just forcing the appearance of the requester here.
	xor a
	ret
	
	
;----------------------------------------------------------------------------
include	"file_requesters.asm"
;----------------------------------------------------------------------------

my_filename

	db "Blah.txt",0
	
	
load_buffer

	db 0

;---------------------------------------------------------------------------	
	


