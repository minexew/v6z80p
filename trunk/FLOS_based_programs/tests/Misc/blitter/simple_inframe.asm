;-----------------------------------------------------------------------------------------
; Tests blitter - ascending mode (blit occurs midframe)
; CPU copies test pic to top half of display
; Blitter copies to bottom half (1 line more per frame)
;-----------------------------------------------------------------------------------------

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "\equates\kernal_jump_table.asm"
include "\equates\osca_hardware_equates.asm"
include "\equates\system_equates.asm"

	org $5000

;--------------------------------------------------------------------------------------

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
	
	ld e,0
	ld a,e
clrabp	ld (vreg_vidpage),a

	ld hl,video_base		; clear all bitplanes
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
	ld (vreg_yhws_bplcount),a	;1 bitplane display

	ld hl,0
	ld (bitplane0a_loc),hl
	ld (bitplane0a_loc+2),hl

;-----------------------------------------------------------------------------------------

	ld hl,palette
	ld (hl),0
	inc hl
	ld (hl),0
	inc hl
	ld (hl),$ff
	inc hl
	ld (hl),$ff
	inc hl
	
	ld a,$8e
	ld c,$04
	ld b,254
pwloop	ld (hl),a
	inc hl
	ld (hl),c
	inc hl
	djnz pwloop

;-----------------------------------------------------------------------------------------

	ld a,%00000000
	ld (vreg_vidpage),a
	
	ld hl,test_gfx		;copy test image to top half of bitplane 0 with CPU
	ld de,video_base
	ld bc,40*100
	ldir

;-----------------------------------------------------------------------------------------


wvrtstart	

	ld a,(vreg_read)
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
	
	ld hl,(position)
	ld de,40
	add hl,de
	ld (position),hl

	ld a,(lines)
	inc a
	cp 100
	jr nz,lineok
	ld hl,4000
	ld (position),hl
	ld a,1
lineok	ld (lines),a
	

	call kjt_get_key
	cp $76
	jp nz,wvrtstart
	rst 0
	

;-----------------------------------------------------------------------------------------
	
	
do_stuff

	ld b,70
waitlp	call waitline
	djnz waitlp

	ld a,$4c
	ld (palette),a
	
	ld hl,0
	ld (save_sp),sp			;clear bitplane lower half with CPU
	ld sp,$2fa0+(40*100) 
	ld b,250
clrlp	push hl
	push hl
	push hl
	push hl
	push hl
	push hl
	push hl
	push hl
	djnz clrlp
	ld sp,(save_sp)
	

	ld a,$88
	ld (palette),a
	
	ld hl,0				; copy image to bottom half of bitplane 0  
	ld (blit_src_loc),hl		; (ie: vram locations 0-3999 to 4000-7999)
	ld hl,4000		
	ld (blit_dst_loc),hl
	ld a,$00
	ld (blit_src_mod),a
	ld a,$00
	ld (blit_dst_mod),a
	ld a,%01000000
	ld (blit_misc),a
	ld a,(lines)		
	dec a
	ld (blit_height),a		; (reg requires height - 1)
	ld a,39
	ld (blit_width),a		; (reg requires width - 1)

	nop				; ensures blit has begun
	nop
	
waitblit	

	ld a,(vreg_read)		; wait for blit to complete
	bit 4,a 
	jr nz,waitblit
	ret



waitline	

	ld de,vreg_read			;wait whilst raster in display window
xwait1	ld a,(de)
	and 2
	jp nz,xwait1
	nop
	nop
	nop

xwait2	ld a,(de)			;wait whilst raster in border
	and 2
	jp z,xwait2
	nop
	nop
	nop
	ret	

;-----------------------------------------------------------------------------------------

counter       	db 0

position	dw 4000
lines		db 1

save_sp		dw 0

;-------------------------------------------------------------------------------------------

test_gfx	 incbin "FLOS_based_programs\tests\Misc\blitter\data\320x100bitplane.bin"
test_pal 	 incbin "FLOS_based_programs\tests\Misc\blitter\data\320x100bitplane_12bit_palette.bin"
		
;-------------------------------------------------------------------------------------
