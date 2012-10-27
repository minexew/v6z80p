;-----------------------------------------------------------------------------------------
; Tests: Blitter / CPU to video RAM contention: Start blitter (copy 75 lines) and then immediately
; access VRAM with CPU. Should force the CPU to WAIT until end of a scanline when blitter is
; stopped so that CPU can be out of WAIT state when DMA (audio) requests happen at start of
; next scanline. Blitter should restart when DMA is over and the gfx data fetch is complete.
; The CPU copies the last 25 lines (working very slowly at first IE: during the blitter
; pause periods)
;
; The top half image should be copied to the bottom of the display.
; No animation on this test 
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

	ld a,%00000000
	ld (vreg_vidpage),a
	
;	ld hl,test_gfx
;	ld bc,40*100
;lp33	ld a,(hl)
;	cpl
;	ld (hl),a
;	inc hl
;	dec bc
;	ld a,b
;	or c
;	jr nz,lp33
	
	
	ld hl,test_gfx		;copy test image to top half of bitplane 0 with CPU
	ld de,video_base
	ld bc,40*100
	ldir

;-----------------------------------------------------------------------------------------


wvrtstart	ld a,(vreg_read)		;wait vrt
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	ld hl,$444		;dark grey
	ld (palette),hl

	call do_stuff

	ld hl,$00
	ld (palette),hl

	jp wvrtstart
	

;-----------------------------------------------------------------------------------------
	
	
do_stuff	

	xor a
	ld (video_base+8000-39),a	; wipe CPU written test bytes
	ld (video_base+8000-40),a

	ld b,70
waitlp	call waitline
	djnz waitlp
		
	call waitline
			
	ld hl,$c0			;green
	ld (palette),hl

	ld hl,0			;copy 75 lines with blitter
	ld (blit_src_loc),hl
	ld hl,4000
	ld (blit_dst_loc),hl
	ld a,$00
	ld (blit_src_mod),a
	ld a,$00
	ld (blit_dst_mod),a
	ld a,%01000000
	ld (blit_misc),a
	ld a,74
	ld (blit_height),a
	ld a,39
	ld (blit_width),a		;start blit request

	ld hl,$0f			
	ld (palette),hl

waitblits	ld a,(vreg_read)		; wait for blit to start (blue)
	bit 4,a 
	jr z,waitblits

	

	call var_delay2
	
	
	ld hl,$f0f		; (purple)
	ld (palette),hl
	

	ld a,$aa			;immediately access vram with CPU, should cause CPU to WAIT
	ld (video_base+8000-39),a	;until the end of a scanline
	
				
	ld hl,$f00
	ld (palette),hl		;(red)

	
	ld hl,video_base+(75*40)	;copy last 25 lines with CPU
	ld de,video_base+4000+(75*40)
	ld bc,24*40		;TEST: ONLY COPY 24 LINES!!!
	ldir		
	
waitblite	ld a,(vreg_read)		; ensure blit has ended
	bit 4,a 
	jr nz,waitblite

	ret



waitline	ld de,vreg_read		;wait whilst raster in display window
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


var_delay1

	ld a,(temp)
	inc a
	ld (temp),a
	and 1
	jr nz,more
	nop
	ret
more	ld a,(hl)
	ret


var_delay2

	ld a,(temp)
	inc a
	ld (temp),a
	and $3f
	inc a
	ld b,a
lp5	djnz lp5
	ret
	
;-----------------------------------------------------------------------------------------

temp		db 0
counter       	db 0
position		dw 4000
lines		db 100

;-------------------------------------------------------------------------------------------

test_gfx	 	incbin "320x100bitplane.bin"
test_pal 		incbin "320x100bitplane_12bit_palette.bin"
		
;-------------------------------------------------------------------------------------
