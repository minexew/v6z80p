; Lower page test - tests reset button when ROM is paged out
; (OSCA 659 clears port "sys_alt_write_page" when reset button is pressed)

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------

	ld hl,info_txt
	call kjt_print_string
	di
	jp test
	
;------------------------------------------------------------------------------

	org $8000
	
test	ld a,$f
	out (sys_low_page),a	; page 78000-7ffff into Z80 0000-7fff
	ld a,%11000000
	out (sys_alt_write_page),a	; sysram at $000-$7ff (no rom/video regs)
	
	ld b,0
lp2	ld hl,0			; sit in a loop, writing to $000-$7ff
	ld de,$800
lp1	ld a,e
	xor b
	ld (hl),a
	inc hl
	dec de
	ld a,d
	or e
	jr nz,lp1
	inc b
	
	xor a			; border changes colour between
	out (sys_alt_write_page),a	; each write burst (to allow a crash
	ld (palette),bc		; to be detected)
	ld a,%11000000
	out (sys_alt_write_page),a
	jr lp2

;------------------------------------------------------------------------------

info_txt	db 11,"Tests RESET when ROM is paged out.",11
	db 11,"Press reset button now! (System",11
	db "should restart OK)",0
	
;------------------------------------------------------------------------------

