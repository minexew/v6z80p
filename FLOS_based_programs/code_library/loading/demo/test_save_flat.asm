; ----------------------------
; Test of "save_flat" routine
; ----------------------------

;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000

;------------------------------------------------------------------------------
	
	ld iy,filename			; filename location: IY
	
	ld hl,$ff00			; source a:hl
	ld a,$2
	
	ld c,$1				; length c:de
	ld de,$ffff
	call save_flat			; save the data
	
	ret
	
filename

	db "testdata.bin",0
	
;----------------------------------------------------------------------------
include	"flos_based_programs\code_library\loading\inc\load_save_flat.asm"
;----------------------------------------------------------------------------

