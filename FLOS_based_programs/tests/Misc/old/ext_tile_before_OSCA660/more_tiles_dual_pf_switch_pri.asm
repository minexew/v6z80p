
; Tests Extended Tile Mode - Dual Playfield

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;------- Load large pic tiles ----------------------------------------------------------------------


	ld hl,pic_filename
	call kjt_find_file
	jp nz,fferror
	ld a,1
	ld (bank),a
	ld b,57
loadloop	push bc
	ld ix,$0000
	ld iy,$2000
	call kjt_set_load_length
	ld hl,load_buffer
	ld b,0
	call kjt_force_load		
	ld a,(bank)
	ld (vreg_vidpage),a
	inc a
	ld (bank),a
	call kjt_page_in_video
	ld hl,load_buffer		;upload 8K to VRAM
	ld de,$2000
	ld bc,$2000
	ldir
	call kjt_page_out_video
	pop bc
	djnz loadloop


;------- Load font tiles ----------------------------------------------------------------------


	ld hl,font_filename
	call kjt_find_file
	jp nz,fferror
	ld a,62			;first font tile = 1984
	ld (bank),a
	ld b,2
loadloop2	push bc
	ld ix,$0000
	ld iy,$2000
	call kjt_set_load_length
	ld hl,load_buffer
	ld b,0
	call kjt_force_load
	ld a,(bank)
	ld (vreg_vidpage),a
	inc a
	ld (bank),a
	call kjt_page_in_video
	ld hl,load_buffer		;upload 8K to VRAM
	ld de,$2000
	ld bc,$2000
	ldir
	call kjt_page_out_video
	pop bc
	djnz loadloop2
	
	
;-------- Initialize video --------------------------------------------------------------------


	ld a,%00000000		; Select y window pos reg.
	ld (vreg_rasthi),a		
	ld a,$3d			 	
	ld (vreg_window),a		; 240 line display
	ld a,%00000100		; Switch to x window pos reg.
	ld (vreg_rasthi),a		
	ld a,$6e			
	ld (vreg_window),a		; Start = 96 Stop = 480 (Window Width = 368 pixels with wideborder)

	ld hl,colours
	ld de,palette		; upload colour palette
	ld bc,512
	ldir

	ld a,%00000011
	ld (vreg_ext_vidctrl),a	; select extended tile mode
	
	ld a,%10000011		
	ld (vreg_vidctrl),a		; select tile mode / dual pf / wide border 


;--------- Init demo ------------------------------------------------------------------------------


	ld hl,sin_table		; upload sine table to math unit
	ld de,mult_table
	ld bc,$200
	ldir	
	
	ld a,0			
	ld (vreg_vidpage),a
	call kjt_page_in_video

	ld hl,video_base
	ld bc,$1000
	ld a,$0
	call kjt_bchl_memfill	; clear video mem tilemaps	

	ld de,video_base+$400	; playfield B, map buffer A
	ld hl,text		; put some text chars on this playfield
txtlp	ld a,(hl)
	or a
	jr z,txtdone
	cp 32
	jr z,space
	cp 11
	jr nz,noret
	ld a,e
	add a,32
	jr nc,ncr1
	inc d
ncr1	and $e0
	ld e,a
	jr nchr
noret	sub $30
	push hl
	ld hl,1984		;first font tile number
	add a,l
	jr nc,ncr
	inc h
ncr	res 3,d			;for lower byte address
	ld (de),a
	set 3,d			;for upper byte address
	ld a,h
	ld (de),a
	pop hl
space	inc de
nchr	inc hl
	jr txtlp	

txtdone	call kjt_page_out_video


	ld hl,tile_array+(11*128)+22	; populate tile image buffer (64x64 word table in sys ram)
	ld de,32			; top left tile number
	ld c,42
lp2	push hl
	ld b,42
lp1	ld (hl),e			; low byte
	inc hl
	ld (hl),d			; high byte
	inc hl
	inc de
	djnz lp1
	pop hl
	push de
	ld de,128			;offset to next line in word table
	add hl,de
	pop de
	dec c
	jr nz,lp2
	

;--------- Main Loop ---------------------------------------------------------------------------------


wvrtstart	ld a,(vreg_read)		; wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	ld a,(pri)
	or 1
	ld (vreg_ext_vidctrl),a
	
	ld hl,$f00
	ld (palette),hl

	call update_coords

	ld a,(xpos)		;set x hardware scroll
	cpl
	and $f
	ld (vreg_xhws),a
	ld a,(ypos)
	and $f
	ld (vreg_yhws_bplcount),a	
	
	call plot_tiles
	

	ld hl,0
	ld (palette),hl
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		;loop if ESC key not pressed
	xor a
	ld a,$ff			;quit (restart OS)
	ret


;-------------------------------------------------------------------------------------------

	speed equ 4

update_coords

	ld hl,(xpos)		;update coords
	ld de,(xdisp)
	add hl,de
	ld (xpos),hl
	bit 7,h
	jr z,xminok
	ld hl,0
	ld (xpos),hl
	ld de,speed
	ld (xdisp),de
	jr xdone
xminok	ld de,1024-368		;right side of array
	xor a
	sbc hl,de
	jr c,xdone
	add hl,de
	ld (xpos),hl
	ld de,65536-speed
	ld (xdisp),de
xdone
	ld hl,1024-256		;bottom of array
	ld (mult_write),hl
	ld a,(y_angle)
	ld (mult_index),a
	ld hl,(mult_read)
	ld (ypos),hl
	inc a
	and $7f
	ld (y_angle),a
	ret nz
	ld a,(pri)
	xor 2
	ld (pri),a
	ret
	
;-------------------------------------------------------------------------------------------

plot_tiles

	ld hl,(ypos)		;convert coords to offset in word map
	srl h
	rr l
	srl h
	rr l	
	srl h
	rr l
	srl h
	rr l			;divided by 16 (remove pixel fine bits)
	ld h,l
	ld l,0
	srl h
	rr l
	ld de,(xpos)
	srl d
	rr e
	srl d
	rr e	
	srl d
	rr e
	res 0,e
	add hl,de			
	ld de,tile_array
	add hl,de			;hl = source


	ld a,0			;Copy a section of map to vram tilemap
	ld (vreg_vidpage),a		;tilemaps are always in video page 0

	call kjt_page_in_video
	
	ld de,video_base		;tilemap pf a buffer a - low bytes
	ld c,16			;16 tiles vertically
ylp	ld b,24			;24 tiles horizontally
xlp	ld a,(hl)			;get low byte
	res 3,d			;adjust for low byte
	ld (de),a			;write to low byte of tilemap
	inc hl			
	set 3,d			;adjust for high byte
	ld a,(hl)			;get high byte
	ld (de),a			;write to high byte oftilemap
	inc hl
	inc de
	djnz xlp
	ld a,l			;add on source offset to next line
	add a,128-48
	jr nc,sosok
	inc h
sosok	ld l,a
	ld a,e
	add a,32-24		;add on destination offset to next line
	jr nc,dosok
	inc d
dosok	ld e,a
	dec c
	jr nz,ylp
	
	call kjt_page_out_video
	ret



;-------------------------------------------------------------------------------------------


lferror 	pop bc
fferror	ld hl,error_txt
	call kjt_print_string
	xor a
	ret

	
;-------------------------------------------------------------------------------------------

tile_array	ds 8192,0			;64 * 64 * 2

pic_filename	db "tu_tiles.bin",0
font_filename	db "fo_tiles.bin",0

load_buffer	ds 8192,0

error_txt		db "Load error. Missing File?",11,11,0

colours		incbin "tut_palette.bin"

bank 		db 0

xpos		dw 128
ypos		dw 0
xdisp		dw speed
y_angle		db 0

sin_table		incbin "sin_table.bin"

pri		db 0

text		db 11
		db "   A QUICK TEST OF THE",11
		db "   EXTENDED TILE MODE",11
		db 11
		db "  SOME RANDOM RAMBLINGS",11
		db "  NOW TO FILL UP SPACE",11
		db "   STUFF AND NONSENSE",11
		db "  WIBBLE HUMBUG AND HATS",11
		db "  4 DIMENSIONAL ROTATING",11
		db "    PURPLE PINEAPPLES",11
		db "    HEXAFLEXAGONS AND",11
		db "   INDEED DODECAHEDRONS",11
		db 11
		db "  PYGMIES BUDGIES BEANS",0
		
		
;--------------------------------------------------------------------------------------------