; Lower page test 2 - writes to banks, reads back and verfies

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------
	
	ld hl,info_txt
	call kjt_print_string

	ld hl,firstbyte
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

	xor a
	out (sys_mem_select),a
	jp $8000
	
;---------------------------------------------------------------------------------------

	org $8000

	di
	ld a,%11000000
	out (sys_alt_write_page),a	;$0-$7ff = SYS RAM
	
	ld b,1
	ld hl,0+(firstbyte-$8000)	;skip this code section in the first page
lp4	ld a,b
	out ($20),a		;page the 32KB section into Z80 0-$7fff
lp3	ld a,(hl)
	cp b
	jr nz,bad			;compare all bytes
	inc hl
	ld a,h
	cp $80
	jr nz,lp3
	ld hl,0
	inc b
	ld a,b
	cp $10
	jr nz,lp4
	
	ld a,0
	out ($20),a
	out (sys_alt_write_page),a
	ld hl,ok_text
	call kjt_print_string
	ei	
	xor a
	ret

bad	ld a,0
	out ($20),a
	out (sys_alt_write_page),a
	ld hl,bad_text
	call kjt_print_string
	ei	
	xor a
	ret

	
;------------------------------------------------------------------------------

info_txt	db 11,"Tests lower 32KB paging.",11
	db 11,"Testing. Please Wait...",11,0
	
ok_text	db 11,"OK! Pages 1-F tested @ Z80 $0-$7FFF",11,0

bad_text	db 11,"FAILED!",11,0

;--------------------------------------------------------------------------------

firstbyte	db 0
