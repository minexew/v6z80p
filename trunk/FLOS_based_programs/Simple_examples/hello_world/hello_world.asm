;---------------------------------------------------------------------------
;---Standard header for OSCA and FLOS --------------------------------------
;---------------------------------------------------------------------------

include "kernal_jump_table.asm"         ;useful equates
include "osca_hardware_equates.asm"     ; ""	""
include "system_equates.asm"            ; ""	""

;==========================================================================

	org $5000
	
	
	ld hl,my_text			; location of ASCII string
	call kjt_print_string		; use OS print ascii string routine
    	
	xor a				; show no error on return 
	ret				; back to FLOS
		
;--------------------------------------------------------------------------
	
my_text	db "Hello World!",11,0	; Text followed by <CR+LF> and zero

;----------------------------------------------------------------------------
;----- End of program  ------------------------------------------------------
;----------------------------------------------------------------------------


