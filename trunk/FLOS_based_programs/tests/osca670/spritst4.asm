;--------------------------------------------
; Tests improved sprite priorities in OSCA670
;--------------------------------------------
;
; Custom Priority registers set, but interleave mode is disabled - 
; sprite should pass in front of everything
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

	ld a,%10000000
	out (sys_mem_select),a
	ld hl,sprites
	ld de,sprite_base
	ld bc,4096
	ldir			; copy sprites to sprite RAM
	xor a
	out (sys_mem_select),a

	ld ix,spr_registers		; Set default position etc of sprite 0
	ld (ix+0),$7f		; x coord
	ld (ix+1),$f0		; size / control bits
	ld (ix+2),$19		; y coor
	ld (ix+3),$0		; def LSB

	ld hl,$280		; set priority registers
	ld b,8			
	ld c,0			; here alternate 16-colour groups (background) occlude the sprite
sprilp1	ld (hl),1			
	inc hl
	ld (hl),2
	inc hl
	djnz sprilp1
	

;----------------------------------------------------------------------------------------------------------


	call test1
	
	ld a,$ff			
	ret


;--------------------------------------------------------------------------------------------------------

test1	ld a,%00000001		; Bit 6 = keep colours between 0-127? (off)
	ld (vreg_sprctrl),a		; Bit 4 = use priority toggle? (off) Bit 1 = priority interleave? (off)

	ld hl,0
	ld ix,spr_registers
	ld (ix+3),$0		; definition LSB
	
testlp1	call kjt_wait_vrt
	push hl
	ld de,$90
	add hl,de
	ld (ix),l			; move sprite across screen (update x coord)
	ld a,h
	or $10			
	ld (ix+1),a		
	pop hl
	inc hl
	ld a,h
	cp 2
	jr nz,testlp1
	ret
	


;------------------------------------------------------------------------------------------------------

colours		incbin "palette.bin"

pic		incbin "pic.bin"

sprites		incbin "sprites.bin"

;---------------------------------------------------------------------------------------------------------
