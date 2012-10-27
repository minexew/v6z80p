
;----------------------
; Test #1 mirror sprite
;----------------------

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;--------- Set up video -------------------------------------------------------------------------------------

	ld a,%00000000		; select y window pos register
	ld (vreg_rasthi),a		; 
	ld a,$2e			; set 256 line display
	ld (vreg_window),a
	ld a,%00000100		; switch to x window pos register
	ld (vreg_rasthi),a		
	ld a,$bb
	ld (vreg_window),a		; set 256 pixels wide window

	ld ix,bitplane0a_loc	; initialize datafetch start address HW pointer.
	ld hl,$0000		; datafetch start address (15:0)
	ld c,0			; data fetch start address (16)
	ld (ix),l
	ld (ix+1),h
	ld (ix+2),c
	
	ld a,%10000000
	ld (vreg_vidctrl),a		; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)

	ld a,%00000000
	ld (vreg_vidpage),a		; video page access msb = 0
	
	ld hl,colours		; write palette
	ld de,palette
	ld bc,512
	ldir

	di
	ld a,%00100001
	out (sys_mem_select),a	; select direct vram write mode
		
	ld hl,pic			; copy 32kb pic to vram
	ld de,0
	ld bc,32768
	ldir
	ld hl,pic			; copy to lower half of display too
	ld bc,32768
	ldir

	ld a,%00000000
	out (sys_mem_select),a	; deselect direct vram write mode
	ei
	

;-------- Set up sprites --------------------------------------------------------------------------------

	ld hl,spr_registers  	; zero all sprite registers
	ld b,0
wsprrlp 	ld (hl),0
	inc hl
	ld (hl),0
	inc hl
	djnz wsprrlp

	ld a,%10000000
	ld (vreg_vidpage),a		; select sprite page 0

	ld a,%10000000
	out (sys_mem_select),a
	ld hl,sprites
	ld de,sprite_base
	ld bc,4096
	ldir			; copy sprites to sprite RAM
	xor a
	out (sys_mem_select),a

	ld a,1
	ld (vreg_sprctrl),a		; Bit 0 = Enable sprites

	ld ix,spr_registers		; Set default position etc of sprite 0
	ld (ix+0),$7f		; x coord
	ld (ix+1),$f0		; size / control bits
	ld (ix+2),$19		; y coor
	ld (ix+3),$0		; def LSB


;----------------------------------------------------------------------------------------------------------


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
	ld a,$ff			; and quit (restart OS)
	ret


;--------------------------------------------------------------------------------------------------------

do_stuff	ld ix,spr_registers
	ld hl,counter
	inc (hl)
	
	ld b,0
	ld a,(hl)
	add a,$90
	ld (ix),a			; move sprite across screen (update x coord)
	jr nc,nocarry
	inc b
nocarry	rrca			; use one of the high bits of the count to cycle x-mirror 
	rrca
	rrca
	and $08			; bit 3 is the mirror bit 
	or $f0			; OR in the height bits
	or b			; OR in the x coord MSB
	ld (ix+1),a		; set the size / control bits
	ret

;------------------------------------------------------------------------------------------------------

counter		db 0

colours		incbin "palette.bin"

pic		incbin "pic.bin"

sprites		incbin "sprites.bin"

;---------------------------------------------------------------------------------------------------------
