
; Tests the kjt_get/set_colours routines

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================


	call kjt_get_colours	

	ld de,my_colour_list
	ld bc,18*2
	ldir
	
	ld hl,$f00
	ld (my_colour_list+(17*2)),hl		;change pen 15 colour

	ld hl,my_colour_list	
	call kjt_set_colours
	xor a
	ret
	
my_colour_list

	ds 18*2,0

;--------------------------------------------------------------------------------------

