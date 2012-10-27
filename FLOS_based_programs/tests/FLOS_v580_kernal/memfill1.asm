

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000


	ld hl,$8101
	ld bc,$1000
	ld a,$ff
	call kjt_bchl_memfill
	xor a
	ret
	