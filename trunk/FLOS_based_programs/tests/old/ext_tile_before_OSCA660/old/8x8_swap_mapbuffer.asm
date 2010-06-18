
; Tests Extended Tile Mode - Single Playfield, 8x8 tiles

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
	ld (vreg_window),a		; Start = 96 Stop = 480 (Window Width = 368 pixels)

	ld hl,my_colours
	ld de,palette		; upload colour palette
	ld bc,512
	ldir

	ld a,%00000001
	ld (vreg_ext_vidctrl),a	; select extended tile mode
	
	ld a,%00001001		
	ld (vreg_vidctrl),a		; select 8x8 tile mode / single pf / normal border 

	ld a,0
	ld (vreg_yhws_bplcount),a	; set h/w scroll
	
;---------------------------------------------------------------------------------------------------
;clear ALL 8x8 tilemaps (VRAM $00000-$03fff)
;---------------------------------------------------------------------------------------------------

	ld a,0			 
	ld (vreg_vidpage),a		; VRAM $00000 @ CPU $2000
	call kjt_page_in_video
	ld hl,video_base
	ld bc,$2000
	xor a
	call kjt_bchl_memfill
	ld a,1
	ld (vreg_vidpage),a		; VRAM $02000 @ CPU $2000
	ld hl,video_base
	ld bc,$2000
	xor a
	call kjt_bchl_memfill	

;---------------------------------------------------------------------------------------------------
;copy 128 8x8 tile block definitins to VRAM $04000
;---------------------------------------------------------------------------------------------------
	
	ld a,2			
	ld (vreg_vidpage),a		; VRAM $04000 @ CPU $2000
	ld hl,my_tiles
	ld de,video_base
	ld bc,$2000		; 128 * 64bytes = 8192
	ldir

;---------------------------------------------------------------------------------------------------
;Write some map data to the Tilemap 0, Playfield A
;---------------------------------------------------------------------------------------------------

	ld a,0			 
	ld (vreg_vidpage),a		; VRAM $00000 @ CPU $2000
	call kjt_page_in_video

	ld hl,video_base		; write in some map data
	ld e,$00			; first block = $100
	ld c,8
lp2	ld b,8
lp1	ld (hl),e			; write LSB of tile index
	set 3,h
	ld (hl),1			; write MSB of tile index
	res 3,h
	inc hl
	inc e
	djnz lp1
	ld a,l			; move to next line of tile map
	add a,64-8		; theres 64 bytes per tilemap line in 8x8 mode
	ld l,a
	jr nc,hi_ok
	inc h
hi_ok	dec c
	jr nz,lp2
	
	call kjt_page_out_video

;---------------------------------------------------------------------------------------------------
;Write some map data to the Tilemap 1, Playfield A
;---------------------------------------------------------------------------------------------------

	ld a,0			 
	ld (vreg_vidpage),a		; VRAM $02000 @ CPU $2000
	call kjt_page_in_video

	ld hl,video_base+$1400	; write in some map data (2nd tilemap, halfway down)
	ld e,$40			; first block = $140
	ld c,8
blp2	ld b,8
blp1	ld (hl),e			; write LSB of tile index
	set 3,h
	ld (hl),1			; write MSB of tile index
	res 3,h
	inc hl
	inc e
	djnz blp1
	ld a,l			; move to next line of tile map
	add a,64-8		; theres 64 bytes per tilemap line in 8x8 mode
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
	or %00001001
	ld (vreg_vidctrl),a		; tilemap / extend
	ret

;------------------------------------------------------------------------------------------

timer	db 0
	
;-------------------------------------------------------------------------------------------

my_tiles		incbin "8x8_tiles.bin"
my_tiles2		incbin "8x8_tiles2.bin"

my_colours	incbin "8x8_tiles_palette.bin"

;--------------------------------------------------------------------------------------------