; -------------------------------------
; Test of "load_to_sprite_RAM" routine
; -------------------------------------

;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000

;------------------------------------------------------------------------------
	
	ld hl,filename			; filename location: HL
	
	ld de,$0			; dest C:DE
	ld c,$0
	call load_to_sprite_ram		; get the data

	ret
	
filename

	db "testdata.bin",0
	
;----------------------------------------------------------------------------
include	"flos_based_programs\code_library\loading\inc\load_to_sprite_ram.asm"
;----------------------------------------------------------------------------

