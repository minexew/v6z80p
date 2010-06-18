
; Tests palette swap

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000


;----------------------------------------------------------------------------------------------------------

	ld a,%00000000		; select y window pos register
	ld (vreg_rasthi),a		; 
	ld a,$2e			; set 256 line display
	ld (vreg_window),a
	ld a,%00000100		; switch to x window pos register
	ld (vreg_rasthi),a		
	ld a,$bb
	ld (vreg_window),a		; set 256 pixels wide window

	ld ix,bitplane0a_loc	;initialize datafetch start address HW pointer.
	ld hl,$0000		;datafetch start address (15:0)
	ld c,0			;data fetch start address (16)
	ld (ix),l
	ld (ix+1),h
	ld (ix+2),c
	
	ld a,%10000000
	ld (vreg_vidctrl),a		; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)

	ld a,%00000000
	ld (vreg_vidpage),a		; video page access msb = 0
	
	di
	ld a,%00100001
	out (sys_mem_select),a	; select direct vram write mode
		
	ld hl,pic			; copy pic to vram
	ld de,0
	ld bc,32768
	ldir
	ld hl,pic
	ld bc,32768
	ldir

	ld a,%00000000
	out (sys_mem_select),a	; deselect direct vram write mode
	ei

	ld a,%00000010
	ld (vreg_palette_ctrl),a	; select write to palette 0
		
	ld hl,colours		; write normal colours to palette 1
	ld de,palette
	ld bc,512
	ldir

	ld a,%00000011
	ld (vreg_palette_ctrl),a	; select write to palette 1

	ld hl,colours		; write inverted colours to palette 2
	ld de,palette
	ld b,0
plp1	ld a,(hl)
	cpl
	ld (de),a
	inc hl
	inc de
	ld a,(hl)
	cpl
	ld (de),a
	inc hl
	inc de
	djnz plp1
	
;------------------------------------------------------------------------------------------------------

wvrtstart	ld a,(vreg_read)		;wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	call do_stuff
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		; loop if ESC key not pressed
	
	ld a,%00000010
	ld (vreg_palette_ctrl),a	; select write to palette 0
	ld a,%00000000
	ld (vreg_palette_ctrl),a	; use palette 0
	
	ld a,$ff			; and quit (restart OS)
	ret


;--------------------------------------------------------------------------------------------------------

do_stuff	ld hl,counter
	inc (hl)
	ld a,(hl)
	rlca
	rlca 
	and 1
	ld (vreg_palette_ctrl),a	; select "live" palette
	ret

;------------------------------------------------------------------------------------------------------

counter		db 0

colours		incbin "testpic_pal.bin"

pic		incbin "testpic.bin"

;---------------------------------------------------------------------------------------------------------
