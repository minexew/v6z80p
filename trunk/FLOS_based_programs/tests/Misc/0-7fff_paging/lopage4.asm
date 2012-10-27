; Lower page test - test write/read of port $20

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

	jp test
	
;------------------------------------------------------------------------------

	org $8000
	
test	ld hl,info_txt
	call kjt_print_string
	di
	ld b,0

lp1	ld a,b
	out (sys_low_page),a

	ld a,$ff

	in a,(sys_low_page)
	and $f
	cp b
	jr nz,bad
	inc b
	ld a,b
	cp $10
	jr nz,lp1
	
	xor a
	out (sys_low_page),a
	ei
	ld hl,ok_text
	call kjt_print_string
	xor a
	ret

bad
	xor a
	out (sys_low_page),a
	ei
	ld hl,bad_text
	call kjt_print_string
	xor a
	ret	
	
;----------------------------------------------------------------------------

info_txt	db 11,"Tests read/write of 'sys_low_page'",11,"(port $20)",11,0

ok_text	db 11,"OK!",11,0

bad_text	db 11,"Failed!",11,0

;-----------------------------------------------------------------------------
