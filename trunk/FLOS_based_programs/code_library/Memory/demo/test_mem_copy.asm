; ---------------------------------------
; Test of flat system memory copy routine
; ---------------------------------------

;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000

;------------------------------------------------------------------------------
	
	ld hl,$0100		;source b:hl
	ld b,$2
	
	ld de,$0200		;dest c:de
	ld c,$4
	
	ld ix,$ffff		;bytes to copy a:ix
	ld a,$0
	call flat_mem_copy
	
	xor a
	ret
	
;----------------------------------------------------------------------------
include	"flos_based_programs\code_library\memory\inc\flat_mem_copy.asm"
;----------------------------------------------------------------------------

