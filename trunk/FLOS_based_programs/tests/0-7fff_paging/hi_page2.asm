; Test "any_page" bit set with sysram $08000-$7ffff banked at $8000-$ffff
; (this should pass with all OSCA versions, IE: anypage should not affect
; the banking of pages 1-f)

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------
	
	ld hl,info_txt
	call kjt_print_string
	di
	
	ld hl,$8000
	ld b,1
lp2	ld a,b
	out (sys_mem_select),a	;set upper page
lp1	ld (hl),b			;fill page 1 with 1, page 2 with 2 etc
	inc hl			;(in upper page)
	ld a,h
	or l
	jr nz,lp1
	ld hl,$8000
	inc b
	ld a,b
	cp $10
	jr nz,lp2
	
	ld a,%00100000		
	out (sys_alt_write_page),a	;set "anybank" mode

	ld b,1
	ld hl,$8000		
lp4	ld a,b
	out (sys_mem_select),a	;page the 32KB section into upper bank
lp3	ld a,(hl)
	cp b
	jr nz,bad			;compare all bytes
	inc hl
	ld a,h
	cp $80
	jr nz,lp3
	ld hl,$8000
	inc b
	ld a,b
	cp $10
	jr nz,lp4
	
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

info_txt	db 11,"Tests 'any page' mode",11,"with 08000-7ffff at $8000-$ffff",11
	db 11,"Testing. Please Wait...",11,0
	
ok_text	db 11,"OK!",11,0

bad_text	db 11,"FAILED!",11,0

;--------------------------------------------------------------------------------

