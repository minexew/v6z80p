; Test "any_page" mode, IE: $0000-$8000 can appear at $8000-$ffff
; when bit 5 of sys_alt_writepage is set

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------
	
	ld hl,info_txt
	call kjt_print_string
	di
	
	xor a
	out (sys_mem_select),a	;fill $08000-$0ffff with $55
	ld hl,$8000
lp1	ld (hl),$55
	inc hl
	ld a,h
	or l
	jr nz,lp1
	
	ld a,%00100000		
	out (sys_alt_write_page),a	;00000-$07fff should now be @ $8000
	
	ld hl,$0800		;compare 0800-7fff with 8800-ffff
	ld de,$8800
lp2	ld a,(de)
	cp (hl)
	jr nz,bad
	inc hl
	inc de
	ld a,d
	or e
	jr nz,lp2
	
	ld a,0		
	out (sys_alt_write_page),a
	ei
	ld hl,ok_text
	call kjt_print_string
	xor a
	ret

bad	ld a,0		
	out (sys_alt_write_page),a
	ei
	ld hl,bad_text
	call kjt_print_string
	xor a
	ret

	
;------------------------------------------------------------------------------

info_txt	db 11,"Tests 'any page' mode",11,"IE: $00000-$07fff at $8000-$ffff",11
	db 11,"Testing. Please Wait...",11,0
	
ok_text	db 11,"OK!",11,0

bad_text	db 11,"FAILED!",11,0

;--------------------------------------------------------------------------------

