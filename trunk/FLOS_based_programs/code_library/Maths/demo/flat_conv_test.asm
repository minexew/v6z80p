
; Tests "A:HL flat address 0-7FFFF" to "FLOS Bank (B), 32KB Page (HL)" conversion routine. 

;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000
	
;-----------------------------------------------------------------------------
	
	ld ix,$8000				;put results at $8000
	ld de,4
	
	ld a,0
	ld hl,$7fff
	call flat_to_banked_addr		;result returned in B:HL (also A:HL) if range OK
	ret nz
	ld (ix),l
	ld (ix+1),h
	ld (ix+2),a
	ld (ix+3),b
	add ix,de
	
	ld a,1
	ld hl,$2345
	call flat_to_banked_addr
	ret nz
	ld (ix),l
	ld (ix+1),h
	ld (ix+2),a
	ld (ix+3),b
	add ix,de
	
	ld a,1
	ld hl,$8765
	call flat_to_banked_addr
	ret nz
	ld (ix),l
	ld (ix+1),h
	ld (ix+2),a
	ld (ix+3),b
	add ix,de
	
	ld a,7
	ld hl,$89ab
	call flat_to_banked_addr
	ret nz
	ld (ix),l
	ld (ix+1),h
	ld (ix+2),a
	ld (ix+3),b
	add ix,de
	
	ld a,8					;this should return an error - too high
	ld hl,$1111
	call flat_to_banked_addr
	ret nz
	ld (ix),l
	ld (ix+1),h
	ld (ix+2),a
	ld (ix+3),b
	add ix,de
	ret

;-----------------------------------------------------------------------------

	include "FLOS_based_programs\code_library\Maths\inc\flat_to_banked_addr.asm"

