
; Tests Extended Tile Mode - Single Playfield, 16x16 tiles - map buffer swap test
; OSCA v660 - MAPS at VRAM $70000!


;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;----------------------------------------------------------------------------------------------	
; Initialize video
;----------------------------------------------------------------------------------------------

	ld a,%00000000		; Select y window pos reg.
	ld (vreg_rasthi),a		
	ld a,$3d			 	
	ld (vreg_window),a		; 240 line display
	ld a,%00000100		; Switch to x window pos reg.
	ld (vreg_rasthi),a		
	ld a,$7e			
	ld (vreg_window),a		; (Window Width = 368 pixels)

	ld hl,my_colours
	ld de,palette		; upload colour palette
	ld bc,512
	ldir

	ld a,%00000001
	ld (vreg_ext_vidctrl),a	; select extended tile mode
	
	ld a,%00000001		
	ld (vreg_vidctrl),a		; select 16x16 tile mode / single pf / normal border 

	ld a,0
	ld (vreg_xhws),a
	ld (vreg_yhws_bplcount),a
		
;---------------------------------------------------------------------------------------------------
;clear ALL tilemaps (VRAM $70000-$73fff)
;---------------------------------------------------------------------------------------------------

	ld a,$38			 
	ld (vreg_vidpage),a		; VRAM $70000 @ CPU $2000
	call kjt_page_in_video
	ld hl,video_base
	ld bc,$2000
	xor a
	call kjt_bchl_memfill
	ld a,$39
	ld (vreg_vidpage),a		; VRAM $72000 @ CPU $2000
	ld hl,video_base
	ld bc,$2000
	xor a
	call kjt_bchl_memfill	

;---------------------------------------------------------------------------------------------------
;copy 16 tile block definitins to VRAM $00000
;---------------------------------------------------------------------------------------------------
	
	ld a,0			
	ld (vreg_vidpage),a		; VRAM $00000 @ CPU $2000
	ld hl,my_tiles
	ld de,video_base
	ld bc,$1000		; 16 * 256 bytes = 4096
	ldir

;---------------------------------------------------------------------------------------------------
;Write some map data to Tilemap 0, Playfield A
;---------------------------------------------------------------------------------------------------

	ld a,$38			 
	ld (vreg_vidpage),a		; VRAM $70000 @ CPU $2000
	call kjt_page_in_video

	ld hl,video_base		; write in some map data
	ld e,0
	ld c,4
lp2	ld b,4
lp1	ld (hl),e			; write LSB of tile index
	set 3,h
	ld (hl),0			; write MSB of tile index
	res 3,h
	inc hl
	inc e
	djnz lp1
	ld a,l			; move to next line of tile map
	add a,32-4		; theres 32 bytes per tilemap line in 16x16 mode
	ld l,a
	jr nc,hi_ok
	inc h
hi_ok	dec c
	jr nz,lp2
	
	call kjt_page_out_video

;---------------------------------------------------------------------------------------------------
;Write some map data to Tilemap 1, Playfield A
;---------------------------------------------------------------------------------------------------

	ld a,$38			 
	ld (vreg_vidpage),a		; VRAM $70000 @ CPU $2000
	call kjt_page_in_video

	ld hl,video_base+$300	; write in some map data (halfway down)
	ld e,0
	ld c,4
blp2	ld b,4
blp1	ld (hl),e			; write LSB of tile index
	set 3,h
	ld (hl),0			; write MSB of tile index
	res 3,h
	inc hl
	inc e
	djnz blp1
	ld a,l			; move to next line of tile map
	add a,32-4		; theres 32 bytes per tilemap line in 16x16 mode
	ld l,a
	jr nc,bhi_ok
	inc h
bhi_ok	dec c
	jr nz,blp2
	
	call kjt_page_out_video
	
	
;--------- Main Loop ---------------------------------------------------------------------------------


wvrtstart	ld a,(vreg_read)		; wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend
	
	ld hl,$f00
;	ld (palette),hl

	call do_stuff	

	ld hl,0
;	ld (palette),hl
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		;loop if ESC key not pressed
	xor a
	ld a,$ff			;quit (restart OS)
	ret


;-------------------------------------------------------------------------------------------

do_stuff	ld hl,timer
	inc (hl)
	ld a,(hl)
	and $20			; isolate playfield A buffer select bit
	or %00000001
	ld (vreg_vidctrl),a		; tilemap / extend
	ret
	

;------------------------------------------------------------------------------------------

timer	db 0
	
;-------------------------------------------------------------------------------------------

my_tiles		incbin "16x16_tiles.bin"

my_colours	incbin "16x16_tiles_palette.bin"

;--------------------------------------------------------------------------------------------