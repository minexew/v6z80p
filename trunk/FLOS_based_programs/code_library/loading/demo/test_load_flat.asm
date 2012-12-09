; -------------------------------------
; Test of "load_flat" routine
; -------------------------------------

;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000

;------------------------------------------------------------------------------
	
	ld iy,filename			; filename location: HL
	
	ld hl,$6000			; dest a:hl
	ld a,$0
	call load_flat			; get the data

	ret
	
filename

	db "testdata.bin",0
	
;----------------------------------------------------------------------------
include	"flos_based_programs\code_library\loading\inc\load_save_flat.asm"
;----------------------------------------------------------------------------

