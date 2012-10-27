;--------------------------------------------
; Tests improved sprite priorities in OSCA670
;--------------------------------------------
;
; Test MSB replacement (was previously OR'd when modify MSB was set,
; now the bit is actually replaced by bit 7 from the height register)
;
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

	ld a,%10000000		; copy sprites to sprite RAM
	out (sys_mem_select),a	; making sure the colour indexes are 128+
	ld hl,sprites		; as this is testing the MSB swap
	ld de,sprite_base
	ld bc,4096
cstsrlp	ld a,(hl)
	or a
	jr z,transp
	or 128
transp	ld (de),a
	inc hl
	inc de
	dec bc
	ld a,b
	or c
	jr nz,cstsrlp
	xor a
	out (sys_mem_select),a

	ld ix,spr_registers		; Set default position etc of sprite 0
	ld (ix+0),$7f		; x coord
	ld (ix+1),$f0		; size / control bits
	ld (ix+2),$19		; y coor
	ld (ix+3),$0		; def LSB

	ld hl,$280		; set priority registers to OSCA < 670 standard
	ld b,16			; IE: Background colours 128-255 can occlude sprite 
	ld c,0			; colours 0-127
sprilp1	ld (hl),c			
	inc hl
	ld a,b
	cp 8
	jr nz,nochspri
	ld c,1
nochspri	djnz sprilp1
	

;----------------------------------------------------------------------------------------------------------


	call test1
	call test2
	call test3
	
	ld a,$ff			
	ret


;--------------------------------------------------------------------------------------------------------

test1	ld a,%00010011		; Bit 6 = keep colours between 0-127 (off)
	ld (vreg_sprctrl),a		; Bit 4 = enable priority toggle (on) Bit 1 = priority interleave (on)

	ld hl,0
	ld ix,spr_registers
	ld (ix+3),$0		; definition LSB
	
testlp1	call kjt_wait_vrt
	push hl
	ld de,$90
	add hl,de
	ld (ix),l			; move sprite across screen (update x coord)
	ld a,h
	or $10			; bit 7 = reset, this sprite's colours are changed from normal (128+)
	ld (ix+1),a		; to 1-127, and occluded by the background colours 128-255
	pop hl			; colours should appear in range 1-127
	inc hl
	ld a,h
	cp 2
	jr nz,testlp1
	ret
	
;--------------------------------------------------------------------------------------------------------

test2	ld a,%00010011		; Bit 6 = keep colours between 0-127 (off)
	ld (vreg_sprctrl),a		; Bit 4 = enable priority toggle (on) Bit 1 = priority interleave (on)

	ld hl,0
	ld ix,spr_registers
	ld (ix+3),$1		; definition LSB
	
testlp2	call kjt_wait_vrt
	push hl
	ld de,$90
	add hl,de
	ld (ix),l			; move sprite across screen (update x coord)
	ld a,h
	or $90
	ld (ix+1),a		; bit 7 = set: the sprite's colours are high on this pass
	pop hl			; sprite should appear in front of all background colours
	inc hl			; sprite colour should appear 128-255
	ld a,h
	cp 2
	jr nz,testlp2
	ret

;--------------------------------------------------------------------------------------------------------

test3	ld a,%01010011		; Bit 6 = keep colours between 0-127 (on)
	ld (vreg_sprctrl),a		; Bit 4 = enable priority toggle (on) Bit 1 = priority interleave (on)

	ld hl,0
	ld ix,spr_registers
	ld (ix+3),$2		; definition LSB
	
testlp3	call kjt_wait_vrt
	push hl
	ld de,$90
	add hl,de
	ld (ix),l			; move sprite across screen (update x coord)
	ld a,h
	or $90
	ld (ix+1),a		; bit 7 = set: the sprite's colour MSB is high on this pass
	pop hl			; sprite should appear in front of all background colours
	inc hl			; bur sprite colours should appear in range 1-127
	ld a,h
	cp 2
	jr nz,testlp3
	ret


;------------------------------------------------------------------------------------------------------

colours		incbin "palette.bin"

pic		incbin "pic.bin"

sprites		incbin "sprites.bin"

;---------------------------------------------------------------------------------------------------------
