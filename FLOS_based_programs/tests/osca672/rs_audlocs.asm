;-------------------------------------------------------------------------------
; Sets all location hi ports [bits 16:17 of location regs] to $01 ($20000-$3ffff)
;--------------------------------------------------------------------------------

;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000


	ld a,$01
	out ($24),a
	out ($25),a
	out ($26),a
	out ($27),a
	
	ld hl,text
	call kjt_print_string
	
	xor a
	ret
	
	
text	db "Ports $24-$27 set to $01",11,0
