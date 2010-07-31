;-----------------------------------------------------------------------------------------
; Tests blitter - modulo and dest addresses
; CPU copies test pic to one buffer
; Blitter copies to visible buffer in rising width increments
; forcing pic right a byte each frame
;-----------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------
include "osca_hardware_equates.asm"
include "system_equates.asm"
;-----------------------------------------------------------------------------------------

	org OS_location+$10		

	jp start

;-----------------------------------------------------------------------------------------

	org $4000			;keep code out the way of bank switched areas
	
;-----------------------------------------------------------------------------------------

; Initialize video hardware

start	ld a,0
	ld (vreg_rasthi),a		; select y window reg
	ld a,$5a
	ld (vreg_window),a		; set y window size/position (200 lines)
	ld a,%00000100
	ld (vreg_rasthi),a		; select x window reg
	ld a,$8c
	ld (vreg_window),a		; set x window size/position (320 pixels)
	
	ld a,%01000000
	out (sys_mem_select),a	; page in video ram
	
	ld e,0			; clear all bitplanes (with CPU)
	ld a,e
clrabp	ld (vreg_vidpage),a
	ld hl,video_base		
	ld bc,$2000
flp	ld (hl),$00
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,flp
	inc e
	ld a,e
	cp 16
	jr nz,clrabp
	
	ld a,0
	ld (vreg_vidctrl),a		;bitmap mode + normal border + video enabled
	ld a,0
	ld (vreg_xhws),a		;x scroll position = 0


;-----------------------------------------------------------------------------------------

	ld hl,test_pal		; write palette
	ld de,palette
	ld b,0
pwloop	ld c,(hl)
	inc hl
	ld a,(hl)
	inc hl
	ld (de),a
	inc de
	ld a,c
	ld (de),a
	inc de
	djnz pwloop

;-----------------------------------------------------------------------------------------

	ld a,%00001000
	ld (vreg_vidpage),a
	
	ld hl,test_gfx		;copy test image to buffer 1, bitplane 0 with CPU
	ld de,video_base
	ld bc,40*100
	ldir
	ld hl,test_gfx		
	ld de,video_base+(40*100)
	ld bc,40*100
	ldir
	
;-----------------------------------------------------------------------------------------


wvrtstart	ld a,(vreg_read)
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

;	ld hl,counter
;	inc (hl)
;	ld a,(hl)
;	and 15
;	jr nz,wvrtstart

	call do_stuff

	ld a,$00
	ld (palette),a
	
	ld a,(width)
	inc a
	cp 41
	jr nz,lineok
	ld a,1
lineok	ld (width),a
	
	jp wvrtstart
	

;-----------------------------------------------------------------------------------------
	
	
do_stuff

	ld a,$4c
	ld (palette),a
	
	ld a,%00000001
	ld (vreg_vidpage),a		;clear bitplane 0 by copying bitplane 1 to it
	ld hl,8192		;copy 40 bytes x 200 lines 
	ld (blit_src_loc),hl
	ld hl,0
	ld (blit_dst_loc),hl
	ld a,$00
	ld (blit_src_mod),a
	ld a,$00
	ld (blit_dst_mod),a
	ld a,%01000000
	ld (blit_misc),a
	ld a,199
	ld (blit_height),a
	ld a,39
	ld (blit_width),a
	nop			;ensures blit has begun
	nop
	nop	
	nop
waitblit1	ld a,(vreg_read)		;wait for blit to complete
	bit 4,a 
	jr nz,waitblit1
	
	ld a,$88
	ld (palette),a
	
	ld a,%01010000
	ld (blit_misc),a		;blitter source msb is 1, dest 0

	ld a,(width)		;copy various widths
	ld e,a
	ld a,40
	sub e
	ld (blit_src_mod),a
	ld (blit_dst_mod),a
	
	ld a,(width)		;push image right x bytes too
	ld e,a
	ld d,0
	ld hl,40
	xor a			
	sbc hl,de
	ld (blit_dst_loc),hl	;vary destination address
	ld hl,0
	ld (blit_src_loc),hl	;source address remains constant
		
	
	ld a,200
	ld (blit_height),a
	ld a,(width)
	sub 1
	ld (blit_width),a		;width reg requires width - 1
	nop			;ensures blit has begun
	nop
	nop
	nop
waitblit	ld a,(vreg_read)		;wait for blit to complete
	bit 4,a 
	jr nz,waitblit
	ret



;-----------------------------------------------------------------------------------------

counter       	db 0

width		db 1

;-------------------------------------------------------------------------------------------

test_gfx	 	incbin "320x100bitplane.bin"
test_pal 		incbin "320x100bitplane_12bit_palette.bin"
		
;-------------------------------------------------------------------------------------
