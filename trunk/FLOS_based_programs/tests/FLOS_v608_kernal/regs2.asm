;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "\equates\kernal_jump_table.asm"
include "\equates\osca_hardware_equates.asm"
include "\equates\system_equates.asm"

	org $5000
	
	ld bc,$0000
	ld de,$5678
	ld hl,$98ab
	ld ix,$cdef
	ld iy,$0246
	
	exx
	ld bc,$a1b2
	ld de,$aa55
	ld hl,$7799
	exx
	
	ld a,$56
	ld i,a
	ld a,0
	ld r,a
	
	ld a,$7f
	ex af,af'
	ld a,$23
	ex af,af'
	
my_loop	inc bc
	jp my_loop
	
	
	