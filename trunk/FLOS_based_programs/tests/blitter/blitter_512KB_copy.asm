;-----------------------------------------------------------------------------------------
; v6 Test: Blitter Copies pic @ vram 0-7999 to entire video ram.
;          Bitplane pointer 0 then scrolls through 512KB video ram
;-----------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------
include "OSCA_hardware_equates.asm"
include "system_equates.asm"
;-----------------------------------------------------------------------------------------

	org OS_location+$10		

	jp start

;-----------------------------------------------------------------------------------------

	org $4000			;keep code out the way of bank switched areas
	
;-----------------------------------------------------------------------------------------

start	

; Initialize video hardware

	ld a,0
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
	cp 64
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
	ld hl,test_gfx		;copy test image to Video RAM address 0-7999 with CPU
	ld de,video_base
	ld bc,200*40
	ldir
	
	ld de,8000
	ld c,0			;copy VRAM 0-7999 to every 8000 byte boundary with blitter	
	ld b,64
nxtblit	push bc	
	ld hl,0
	ld b,0
	call blit_copy
	ex de,hl
	ld de,8000
	add hl,de
	jr nc,ndadc
	inc c
ndadc	ex de,hl
	ld a,c
	pop bc
	ld c,a
	djnz nxtblit
	
;-----------------------------------------------------------------------------------------


wvrtstart	ld a,(vreg_read)		;wait vrt
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	ld hl,(positionl)
	ld (bitplane0a_loc),hl
	ld hl,(positionh)
	ld (bitplane0a_loc+2),hl

	ld a,$88
	ld (palette),a
	
	call do_stuff

	ld a,$00
	ld (palette),a

	in a,(sys_keyboard_data)
	cp $29
	jr nz,wvrtstart		; loop if SPACE key not pressed

	jp 0			; reboot
	

;-----------------------------------------------------------------------------------------
	
blit_copy	
				;copy 40 bytes x 200 lines
	ld (blit_src_loc),hl
	ld a,b
	ld (blit_src_msb),a

	ld (blit_dst_loc),de
	ld a,c
	ld (blit_dst_msb),a

	ld a,$00
	ld (blit_src_mod),a
	ld a,$00
	ld (blit_dst_mod),a
	ld a,%01000000		;blitter in ascending mode, legacy msbs = 0
	ld (blit_misc),a
	ld a,199
	ld (blit_height),a
	ld a,39
	ld (blit_width),a
	nop			;ensures blit has begun
	nop
	
waitblit	ld a,(vreg_read)		;wait for blit to complete
	bit 4,a 
	jr nz,waitblit
	ret


;-----------------------------------------------------------------------------------------

do_stuff
	ld hl,(positionl)
	ld de,160
	add hl,de
	ld (positionl),hl
	jr nc,hwok
	ld hl,(positionh)
	inc hl
	ld a,l
	cp 8
	jr nz,ok
	ld hl,0
	ld (positionl),hl	
ok	ld (positionh),hl	
hwok	ret

;-------------------------------------------------------------------------------------------

positionl		dw 0
positionh		dw 0
counter       	db 0
save_sp		dw 0

test_gfx	 	incbin "320x200bitplane.bin"
test_pal 		incbin "320x200bitplane_12bit_palette.bin"
		
;-------------------------------------------------------------------------------------
