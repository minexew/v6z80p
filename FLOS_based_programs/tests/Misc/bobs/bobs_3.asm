; A BOB (Blitter Object Block) Routine 1.03 - Phil @ retroleum 09
; ---------------------------------------------------------------
;
; Demonstration of using the blitter to move graphics around smoothly on a chunky-mode
; bitmap, (as an alternative to hardware sprites)
;
; There are three video buffers: 
; $00000-$1ffff is reserved for buffer A (bobs + background)
; $20000-$3ffff is reserved for buffer B (bobs + background)
; $40000-$5ffff is reserved for "clean" background only
; $60000-$7ffff is reserved for the bob images
;
; Source bob image pic is 256 x Y pixels (where y is 1 to 512)
; Individual bob sizes and image location within source pic are definable
;
;
; Limitations:
; ------------
; Bobs are not clipped at display window edges
; Bob plot coords go from the top left pixel of bob (ie: not centre origin based)
; Naturally, the number of bobs that be plotted per frame is limited by the size of the bobs.
; Code is not optimized - its possible to rearrange it so the CPU can do useful work whilst the blitter is busy.
; Max bob size = 255 x 255



;---Standard header for OSCA and FLOS ---------------------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;--------- Initialize ------------------------------------------------------------------------

	di			; disable IRQs (for the all-writes-to-VRAM sections)

	call clear_vram
	
	call set_up_display
	call set_up_sine_table
	call set_up_bobs
	

;--------- Main loop -------------------------------------------------------------------------	

wvrtstart	ld a,(vreg_read)		; wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	ld hl,$8f8
	ld (palette),hl
	call per_frame_routines
	ld hl,0
	ld (palette),hl

	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		; quit if ESC key pressed
	xor a
	ld a,$ff
	ret
	
;---------------------------------------------------------------------------------------------

per_frame_routines

	call flip_page
	call delete_old_bobs
	call draw_new_bobs

	call make_new_bob_coords
	ret

;---------------------------------------------------------------------------------------------

set_up_display


display_width	equ 368		; must be an even number of pixels


	ld a,%00000000		; select y window pos register
	ld (vreg_rasthi),a			 
	ld a,$2e			; set 236 line display
	ld (vreg_window),a
	ld a,%00000100		; switch to x window pos register
	ld (vreg_rasthi),a		
	ld a,$7e
	ld (vreg_window),a		; set 368 pixels wide window

	ld ix,bitplane0a_loc	; initialize datafetch start address HW pointer.
	ld hl,$0000		; datafetch start address (15:0)
	ld c,0			; data fetch start address (16)
	ld (ix),l
	ld (ix+1),h
	ld (ix+2),c

	ld a,%10000000
	ld (vreg_vidctrl),a		; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)

	ld hl,my_colours
	ld de,palette
	ld bc,256*2
	ldir
	
	ld ix,y_addr_list		; build y line offset list
	ld hl,0
	ld de,display_width/2	; (offset values doubled in bob routine)
	ld b,0
myl_loop	ld (ix),l
	ld (ix+1),h
	add hl,de
	inc ix
	inc ix
	djnz myl_loop
	
	ld a,48			; copy test background tile to VRAM $60000 - IRQs must be disabled
	ld (vreg_vidpage),a
	ld a,%00100000		
	out (sys_mem_select),a	; all writes to VRAM mode
	ld hl,my_tile
	ld de,0
	ld bc,end_of_my_tile-my_tile
	ldir
	ld a,%00000000
	out (sys_mem_select),a	; return to normal memory mode
	ld ix,blit_width
	ld hl,0			; tessellate tile to make background in buffers A, B and C
	ld (blit_src_loc),hl	
	ld a,6
	ld (blit_src_msb),a		; tile source is always VRAM $60000
	xor a
	ld (blit_src_mod),a		; tile source modulo is always zero
	ld hl,display_width-tile_width
	ld a,l
	ld (blit_dst_mod),a		; calc dest window modulo
	ld a,h
	rlca
	rlca
	or %01000000
	ld (blit_misc),a		; ascending, no transparency
	ld a,tile_height-1
	ld (blit_height),a		; set height of blits
	ld c,0			; first tile y start pos
	exx
	ld b,4			; number of tile copies vertically
nvtile	exx
	ld de,24			; first tile x start pos			
	ld b,5			; number of tile copies horizontally
nhtile	push de
	ld l,c
	ld h,0
	add hl,hl
	ld de,y_addr_list
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	ld a,0			; dest = first buffer
	add hl,hl
	jr nc,noca1
	inc a
noca1	pop de
	add hl,de
	jr nc,noca2
	inc a
noca2	ld (blit_dst_loc),hl
	ld (blit_dst_msb),a
	ld (ix),tile_width-1	;blit the tile to first buffer
	ld hl,vreg_read
bw1	bit 4,(hl)
	jr nz,bw1
	set 1,a
	ld (blit_dst_msb),a
	ld (ix),tile_width-1	;blit the tile to second buffer
	nop
	nop
bw2	bit 4,(hl)
	jr nz,bw2
	res 1,a
	set 2,a
	ld (blit_dst_msb),a
	ld (ix),tile_width-1	;blit the tile to "background only" buffer
	nop
	nop
bw3	bit 4,(hl)
	jr nz,bw3
	
	ex de,hl
	ld de,tile_width		;move to next x tile postioin
	add hl,de
	ex de,hl
	djnz nhtile
	
	ld a,c
	add a,tile_height		;move to next y tile position
	ld c,a	
	exx
	djnz nvtile
	
	ret

	
;---------------------------------------------------------------------------------------------

set_up_sine_table

	ld hl,my_sine_table		; upload sine table to math unit
	ld de,mult_table
	ld bc,512
	ldir	
	ret
	
;---------------------------------------------------------------------------------------------

set_up_bobs

	
	ld a,48			; copy bobs to VRAM $60000 - IRQs must be disabled
	ld (vreg_vidpage),a
	ld a,%00100000		
	out (sys_mem_select),a	; all writes to VRAM mode
	ld hl,my_bobs
	ld de,0
	ld bc,end_of_bobs-my_bobs
	ldir
	ld a,%00000000
	out (sys_mem_select),a	; normal memory mode
	
	
	ld ix,bob_info_list+4	;put some test definitions into bob info list
	ld b,max_bobs		
	ld a,1
bdloop	ld (ix),a
	ld (ix+1),0	
	inc a
	cp 20			;max bob info supplied
	jr nz,bdefok
	ld a,1
bdefok	ld de,8
	add ix,de
	djnz bdloop

	ret

;-----------------------------------------------------------------------------------------------

clear_vram

	xor a	
	ld (vreg_vidpage),a		; clear vram $0-$ffff - IRQs must be disabled
	ld a,%00100000		
	out (sys_mem_select),a	; all writes to VRAM mode
	ld hl,0
	xor a
wvlp1	ld (hl),a
	inc l
	jr nz,wvlp1
	inc h
	jr nz,wvlp1
	ld a,%00000000
	out (sys_mem_select),a	; normal memory mode
	
	ld hl,0			; copy vram 0-$ffff to all other vram 64K pages
	ld (blit_src_loc),hl	; with blitter for speed
	ld (blit_dst_loc),hl
	xor a
	ld (blit_src_msb),a
	ld (blit_src_mod),a
	ld (blit_dst_mod),a
	ld a,%01000000
	ld (blit_misc),a
	ld a,$ff
	ld (blit_height),a
	ld c,1
copyvlp	ld a,c
	ld (blit_dst_msb),a
	ld a,$ff
	ld (blit_width),a
waitblit	ld a,(vreg_read)
	and $10
	jr nz,waitblit
	inc c
	ld a,c
	cp 8
	jr nz,copyvlp
	ret


;===============================================================================================


flip_page
	ld ix,bitplane0a_loc	; Display buffer 0 or 1 
	ld hl,$0000		
	ld a,(buffer)
	sla a		
	ld (ix),l
	ld (ix+1),h
	ld (ix+2),a

	ld a,(buffer)		; flip buffer flag	
	xor 1
	ld (buffer),a
	ret
	

;-----------------------------------------------------------------------------------------------
;
; BOB routine
; -----------
; Display buffers (background + bobs, double buffered) = $00000 & $20000
; Clean buffer (background data only)                  = $40000
; BOB image page (width = 256 pixels                   = $60000
;
; Max BOB size = 255 x 255 pixels
;
; ----------------------------------------------------------------------------------------------

max_bobs	equ 64

; ------------------------------------------------------------------------------------------------


delete_old_bobs


; Replaces data on "hidden" display buffer with data from clean background buffer at $40000

	
	call get_delete_list		; IY = location of delete table (5 bytes per bob)	
	
	ld b,max_bobs

del_nextb	ld a,(iy+2)			; If bit 7 of dest MSB = 1, its the end of the erase list
	bit 7,a
	ret nz
	ld e,(iy)				; Get VRAM location bob was drawn at..
	ld d,(iy+1)
	ld (blit_dst_loc),de		; this is the wipe destination
	ld (blit_dst_msb),a
	and 1
	or 4
	ld (blit_src_loc),de		; and the wipe source (except range $40000-$5FFFF)
	ld (blit_src_msb),a

	ld hl,display_width			; calculate dest modulo (window size - bob width)
	ld e,(iy+3)			; get previously drawn bob's width
	xor a
	ld d,a
	sbc hl,de
	ld a,l
	ld (blit_dst_mod),a			; set blit dest modulo [0:7]
	ld (blit_src_mod),a			; set blit source modulo [0:7]
	ld a,h				; calc MSBs for dest & source 
	rlca
	rlca
	or h
	or %01000000			; Transparency = off, ascending = 1 
	ld (blit_misc),a		

	ld a,(iy+4)			; get previously drawn bob's height - 1
	ld (blit_height),a			; set blit height
	ld a,(iy+3)			; get bob width
	dec a
	ld (blit_width),a			; start the blit
	ld de,5
	add iy,de

waitblit1	ld a,(vreg_read)			; wait for blit to end
	and $10
	jr nz,waitblit1

	djnz del_nextb
	ret
	

;--------------------------------------------------------------------------------------------------
	
get_delete_list

	ld iy,bob_delete_info1		
	ld a,(buffer)
	or a
	ret z
	ld iy,bob_delete_info2
	ret

;--------------------------------------------------------------------------------------------------

	
draw_new_bobs


; Draws bobs on hidden display buffer (depends on flip buffer bit) and saves information
; on the blits to a list so the bobs can be deleted later.
	
	
	call get_delete_list		; IY = location of delete table (5 bytes per bob)
	
	ld ix,bob_info_list			; IX = User's bob info table (8 bytes per bob)
	ld b,max_bobs			; IE: The max number of bob registers to scan
draw_next	ld l,(ix+4)			; Get definition number that this bob uses
	ld h,(ix+5)
	ld a,l
	or h
	jr nz,bob_on			; If def = $0000, no bob is plotted
	ld de,8
	add ix,de				; next bob description location
	djnz draw_next
	jp bob_end

bob_on	dec hl				; hl = def - 1  
	add hl,hl				; hl = def - 1 * 2
	push hl
	add hl,hl				; hl = def - 1 * 4
	ld de,bob_location_list
	add hl,de				
	ld e,(hl)				; e = bob image's x coord in source page
	inc hl				; following byte not used
	inc hl				; move to bob image's y coord in source page
	ld d,(hl)				; d = bob images' y coord in source page [0:7]				
	inc hl				; move to image source y coord MSB
	ld a,(hl)				; a = bob image's y coord in source page MSB
	add a,6				; blit source bobs start at VRAM 64KB page 6
	ld (blit_src_msb),a			; set blit source address MSB		
	ld (blit_src_loc),de		; set blit source address [0:15]

	pop hl				; hl = def - 1 * 2
	ld de,bob_size_list			
	add hl,de
	ld e,(hl)				; a = this bob definition's width
	inc hl				; move to bob def's height
	ld a,(hl)				; a = height of bob
	dec a				; blit reg requires height - 1
	ld (blit_height),a			; set blit height
	ld (iy+4),a			; store blit height for bob delete routine
	ld a,e				; a - bob width
	ld (bob_width_temp),a		; temp store bob width for later
	neg 				; calculate source modulo (256 - bob width)	
	ld (blit_src_mod),a			; set blit source modulo
	ld hl,display_width			; calculate dest modulo (window size - bob width)
	xor a
	ld d,a				
	sbc hl,de
	ld a,l
	ld (blit_dst_mod),a			; set blit dest modulo [0:7]
	ld a,h				; calc dest modulo MSB bits
	rlca
	rlca
	or %11000000			; Transparency = on, ascending = 1 
	ld (blit_misc),a		

	ld a,(buffer)			; plot bobs on vram + $0 or vram + $20000 depending on 'buffer'
	rlca				; calculate vram dest address (from 0)
	ld l,(ix+2)			; get bob plot y coord [7:0]
	ld h,0
	add hl,hl
	ld de,y_addr_list			; get display offset for y coord
	add hl,de
	ld e,(hl)		
	inc hl
	ld d,(hl)				; de = (left edge display window offset for y coord / 2)
	ex de,hl
	add hl,hl				; hl = left edge display window offset
	jr nc,bobaddrl1
	inc a				; VRAM dest address bit 16
bobaddrl1	ld e,(ix)
	ld d,(ix+1)			; de = bob plot x coord
	add hl,de				; add to left edge location to get final blit address
	jr nc,bobaddrl2
	inc a
bobaddrl2	ld (blit_dst_loc),hl	
	ld (blit_dst_msb),a
	ld (iy),l
	ld (iy+1),h
	ld (iy+2),a			; store destination address for bob delete routine
	ld a,(bob_width_temp)
	ld (iy+3),a			; store blit width for bob delete routine
	dec a				; blit width register requires blit size - 1
	ld (blit_width),a			; start the blit
	ld de,8
	add ix,de				; next bob description location
	ld de,5
	add iy,de				; next entry in bob delete table

waitblit2	ld a,(vreg_read)			; wait for blit operation to finish
	and $10
	jr nz,waitblit2

	dec b
	jp nz,draw_next
	
bob_end	set 7,(iy+2)			; Mark end of erase table (set dest MSB bit 7)
	ret
	
	
		
;--------------------------------------------------------------------------------------------------	
; Test routine - make a simple sine pattern
;--------------------------------------------------------------------------------------------------	


make_new_bob_coords

;use math module to generate new coordinates


	ld ix,bob_info_list		;update x coordinates	
	ld hl,150			
	ld ($208),hl		;sinus max pos amplitude
	ld b,max_bobs		;number of coords
	ld a,(bx_start_offset)
bxloop	ld ($20a),a		;set scale index
	ld hl,($704)
	ld de,168			;origin x
	add hl,de			;centre coords on screen
	ld (ix),l
	ld (ix+1),h
	ld de,8
	add ix,de
	sub 4			;sine table displacement
	djnz bxloop

	ld ix,bob_info_list+2	;update y coordinates
	ld hl,108
	ld ($208),hl		;sinus max pos amplitude
	ld b,max_bobs		;number of coords
	ld a,(by_start_offset)
	add a,64			;move to cos list
byloop	ld ($20a),a		;set scale index
	ld hl,($704)
	ld de,110			;origin y
	add hl,de			;centre coords on screen
	ld (ix),l
	ld (ix+1),h	
	ld de,8
	add ix,de
	add a,3			;cos table displacement
	djnz byloop

	ld a,(bx_start_offset)	;sine position displacements
	add a,1
	ld (bx_start_offset),a
	ld a,(by_start_offset)
	add a,1
	ld (by_start_offset),a
	ret
	

;-------- Bob variables (Internals) ------------------------------------------------------	

buffer		db 0

bob_width_temp	db 0

bob_delete_info1	ds (max_bobs+1)*5,$ff	;$0000=dest [15:0],$00=dest[msb],$00=width,$00 = height
bob_delete_info2	ds (max_bobs+1)*5,$ff	;$0000=dest [15:0],$00=dest[msb],$00=width,$00 = height

y_addr_list	ds 256*2,0	;holds y line offsets / 2

;------------------------------------------------------------------------------------------





;-------- BOB data (user) -----------------------------------------------------------------	

; info (per bob definition) about where each bob image is located on the source image page

bob_location_list	dw 0,46
		dw 11,46
		dw 24,46
		dw 36,46
		dw 48,46
		dw 60,46
		dw 72,46
		dw 84,46
		dw 96,46
		dw 108,46
		dw 0,0
		dw 26,0
		dw 46,0
		dw 46,27
		dw 65,0
		dw 81,0
		dw 118,0
		dw 160,0
		dw 193,0


; info (per bob definition) about the size of each bob
			
bob_size_list	db 11,11
		db 11,11
		db 11,11
		db 11,11
		db 11,11
		db 11,11
		db 11,11
		db 11,11
		db 11,11
		db 11,11
		db 25,22
		db 19,38
		db 18,26
		db 20,18
		db 15,15
		db 36,23
		db 41,38
		db 32,36
		db 45,31

; data structure for each bob to be drawn (IE: "bob register list") 8 bytes per possible bob
		
bob_info_list	ds max_bobs*8,0	;$0000=x,$0000=y,$0000=def (0=off), $0000=spare

;--------------------------------------------------------------------------------------------






	
;---------Test app data ---------------------------------------------------------------------

my_sine_table	incbin "sin_table.bin"

my_bobs		incbin "testbobs_chunky.bin"
end_of_bobs	db 0

my_colours 	incbin "testbobs_palette.bin"

bx_start_offset	db 0
by_start_offset	db 0

tile_width	equ 64
tile_height	equ 64

my_tile		incbin "64x64_tile_chunky.bin"
end_of_my_tile	db 0

;-------------------------------------------------------------------------------------------