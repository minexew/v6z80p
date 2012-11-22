;-----------------------------------------------------------------------------------------
; Tests: Blitter + CPU writes to non-video area: CPU should not be stopped by blitter
; and should not interfere with it copying top half to lower half of image.
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
	out (sys_mem_select),a		; page in video ram
	
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

	ld hl,test_pal			; write palette
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

	ld a,%00000000
	ld (vreg_vidpage),a
	
	ld hl,test_gfx			;copy test image to top half of bitplane 0 with CPU
	ld de,video_base
	ld bc,40*100
	ldir

	ld a,%00000000
	out (sys_mem_select),a		; ****** page out video ram **********

;-----------------------------------------------------------------------------------------


wvrtstart	

	ld a,(vreg_read)		;wait vrt
	and 1
	jr z,wvrtstart
	
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	ld a,$88
	ld (palette),a
	
	call do_stuff

	ld a,$00
	ld (palette),a

	ld hl,(crap_address)		;inc non-vid data source address
	inc hl
	ld (crap_address),hl

	call kjt_get_key
	cp $76
	jp nz,wvrtstart
	rst 0
	
;-----------------------------------------------------------------------------------------
	
	
do_stuff	

	ld a,(vreg_read)		; wait until video data fetch by video system is occuring
	bit 2,a				; (ie: raster is in display window y)
	jr z,do_stuff
		
	ld a,$4f
	ld (palette),a

	ld hl,0				; copy 100 lines with blitter - top half to
	ld (blit_src_loc),hl		; bottom half
	ld hl,4000
	ld (blit_dst_loc),hl
	ld a,$00
	ld (blit_src_mod),a
	ld a,$00
	ld (blit_dst_mod),a
	ld a,%01000000
	ld (blit_misc),a
	ld a,99
	ld (blit_height),a
	ld a,39
	ld (blit_width),a		;start blit

	nop
	nop
	
	ld a,$69
	ld (palette),a
	
	ld hl,[crap_address]		;CPU writes to ($2000-$3fff) RAM "underneath" video page
	ld de,video_base+(50*40)	
	ld bc,100*40
	ldir		
	
	ret

	
;-----------------------------------------------------------------------------------------

counter       	db 0
position		dw 4000
lines		db 100
crap_address	dw test_gfx

;-------------------------------------------------------------------------------------------

test_gfx	 incbin "FLOS_based_programs\tests\Misc\blitter\data\320x100bitplane.bin"
test_pal 	 incbin "FLOS_based_programs\tests\Misc\blitter\data\320x100bitplane_12bit_palette.bin"
		
;-------------------------------------------------------------------------------------
