; Lower page test - tests IRQ vector replacement at $38
; Should be a raster IRQ colour change halfway down display.

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

	org $8038			; irq_handler, will be located at $38 when paged to $0

	push af
	call change_colour
	pop af
	ei			; re-enable interrupts
	reti			; return to main code

;--------------------------------------------------------------------------------

test	ld a,1
	out (sys_low_page),a	; page 08000-0ffff (also) into Z80 0000-7fff
	ld a,$a0
	ld (vreg_rastlo),a		; split line number req'd
	ld a,%00000010
	ld (vreg_rasthi),a		; rast pos MSB and IRQ enable
	ld a,%10000000
	out (sys_irq_enable),a	; master irq enable
	ld a,%11000000
	out (sys_alt_write_page),a	; sysram at $000-$7ff (no rom/video regs)
	ei
	
;----------------------------------------------------------------------------------

wvrtstart	in a,(sys_vreg_read)	; wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	in a,(sys_vreg_read)
	and 1
	jr nz,wvrtend

	di			; cannot allow IRQs whilst ROM/palette is paged in
	xor a			; cus the IRQ would go to the original system IRQ vector 
	out (sys_alt_write_page),a	; held in the ROM and not the one we've set up here
	ld hl,(colour)
	inc hl
	ld (colour),hl
	ld (palette),hl		; colour 0 = black
	ld a,%11000000
	out (sys_alt_write_page),a	; page out the palette and Vregs again
	ei
	
	jr wvrtstart
	
colour	dw 0

;-----------------------------------------------------------------------------

change_colour

	push hl
	xor a
	out (sys_alt_write_page),a	; page in Palette/ROM and Vregs
	ld hl,$f0f
	ld (palette),hl
	ld a,%10000000
	ld (vreg_rasthi),a		; clear irq flag (leaves rest of register intact)
	ld a,%11000000
	out (sys_alt_write_page),a	; page sys ram back in
	pop hl
	ret
	
	
;------------------------------------------------------------------------------


info_txt	db 11,"Tests lower 32KB paging with",11
	db "$0-$7ff as sysram. Border colour",11
	db "split should occur (raster IRQ)",11
	db "halfway down screen",11,0

;------------------------------------------------------------------------------

