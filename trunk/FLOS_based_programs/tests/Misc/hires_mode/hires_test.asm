
;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

	
;-------- INIT DISPLAY -----------------------------------------------------------------------
	
	xor a
	call clear_64k_video_page

	ld a,0
	ld (vreg_rasthi),a		; select y window reg
	ld a,$5a
	ld (vreg_window),a		; set y window size/position (200 lines)
	ld a,%00000100
	ld (vreg_rasthi),a		; select x window reg
	ld a,$8c
	ld (vreg_window),a		; set x window size/position (320 pixels)

	ld ix,bitplane0a_loc	; Set display window address @ 0
	ld hl,0					
	ld a,0 
	ld (ix),l			
	ld (ix+1),h		
	ld (ix+2),a		

	ld de,palette		; Black / white colour scheme
	ld hl,colours
	ld bc,32
	ldir
	
	ld a,%10000000
	ld (vreg_vidctrl),a		; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)	

	ld a,%00001000
	ld (vreg_ext_vidctrl),a	; Enable hi-res mode
	
	
;--------- HI-RES MODE TEST 1 - COLOURS ----------------------------------------------

	di			
	xor a
	ld (vreg_vidpage),a		; Write to $00000-$0ffff in VRAM	
	ld a,$20
	out (sys_mem_select),a	; Set all CPU writes to VRAM mode

	ld a,$01
lloop	ld c,a
	sla c
	sla c
	sla c
	sla c
	ld b,100			; Draw a diagonal line on the screen
	ld de,320
	ld h,0
	ld l,c
tlp1	ld (hl),c			; left side "half pixel"
	add hl,de
	ld (hl),a			; right side "half pixel"
	add hl,de
	inc hl
	djnz tlp1
	inc a
	cp 16
	jr nz,lloop

	xor a
	out (sys_mem_select),a	; Normal memory mode
	ei


;-------- HIRES TEST 2 - TEXT ---------------------------------------------------

	call setup_print_chars

	ld hl,text		; Print some text
	call print_string

;-------------------------------------------------------------------------------

wait	in a,(sys_keyboard_data)
	cp $76
	jr nz,wait		;loop if ESC key not pressed
	xor a
	ld a,$ff			;quit (restart OS)
	ret


;================================================================================

	
clear_64k_video_page

	di
	ld (vreg_vidpage),a		
	ld a,$20			; Set all CPU writes to VRAM mode
	out (sys_mem_select),a
	ld hl,0
cvlp	ld (hl),0
	inc l
	jr nz,cvlp
	inc h
	jr nz,cvlp
	xor a
	out (sys_mem_select),a
	ei
	ret

;--------------------------------------------------------------------------

window_cols	equ 80
window_rows	equ 25

print_string

; prints ascii at current cursor position
; set hl to start of 0-termimated ascii string
	
	
	ld bc,(cursor_y)		;c = y, b = x
prtstrlp	ld a,(hl)			
	inc hl	
	or a			
	jr nz,noteos
	ld (cursor_y),bc		;updates cursor position on exit
	ret
	
noteos	cp 13			;is character a CR? (13)
	jr nz,nocr
	ld b,0
	jr prtstrlp
nocr	cp 10			;is character a LF? (10)
	jr z,linefeed
	cp 11			;is character a LF+CR? (11)
	jr nz,nolf
	ld b,0
	jr linefeed
	
nolf	call plotchar
	inc b			;move right a character
	ld a,b
	cp window_cols		;right edge of screen?
	jr nz,prtstrlp
	ld b,0
linefeed	inc c
	ld a,c
	cp window_rows		;last line?
	jr nz,prtstrlp
	ld c,0
	jr prtstrlp

		
;---------------------------------------------------------------------------------

plotchar

; a = ascii code of character to plot
; b = x pos, c = ypos

	push hl
	push de
	push bc

	sub 32			
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	ld (blit_src_loc),hl	; set blit source address 

	ld d,0
	ld hl,winy_list
	ld e,c
	add hl,de
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld l,b
	ld h,0
	add hl,hl
	add hl,hl
	add hl,de
	ld (blit_dst_loc),hl	; set blit dest address
	ld a,3
	ld (blit_width),a		; set width-1 and start blit

	pop bc
	pop de
	pop hl

waitblit	ld a,(vreg_read)		; wait for blit to complete
	bit 4,a 
	jr nz,waitblit	
	ret


;-----------------------------------------------------------------------------------------	
	
setup_print_chars

font_width  equ 768		; dots along one line of font
char_height equ 8		; dots vertically per char

	call convert_font

	ld hl,0				;create y-line look up table
	ld de,window_cols*4*char_height
	ld ix,winy_list
	ld b,window_rows
molloop	ld (ix),l
	ld (ix+1),h
	inc ix
	inc ix
	add hl,de
	djnz molloop
	
	ld hl,0+(font_width/2)-4		; set up blitter for character plotting
	ld a,l
	ld (blit_src_mod),a			; calc / set modulos
	ld de,0+(window_cols-1)*4
	ld a,e	
	ld (blit_dst_mod),a
	ld a,%01010000		
	bit 0,h
	jr z,sm_msb0
	or %00000001			; source modulo msb
sm_msb0	bit 0,d
	jr z,dm_msb0			; dest modulo msb
	or %00000100
dm_msb0	ld (blit_misc),a			; Ascending blit, src in bank 1, dst in VRAM bank 0
	ld bc,0
	ld (blit_src_msb),bc		; Not using VRAM > 128KB
	ld a,char_height-1
	ld (blit_height),a			; Set height of blit
	ret
	
;----------------------------------------------------------------------------------
; makes "half pixel" 16:16 colour chunky mode font from single bitplane linear font
;----------------------------------------------------------------------------------

convert_font

	di
	ld a,$8			; put converted font at VRAM $10000
	ld (vreg_vidpage),a		
	ld a,$20			; Set all CPU writes to VRAM mode
	out (sys_mem_select),a

	ld de,bit_font
	ld hl,0
	exx
	ld bc,endoffont-bit_font
fc_loop	exx
	ld b,4	
	ld a,(de)
bylp	ld c,0
	sla a
	jr nc,nba
	set 4,c
nba	sla a
	jr nc,nbb
	set 0,c
nbb	ld (hl),c
	inc hl
	djnz bylp
	inc de
	exx
	dec bc
	ld a,b
	or c
	jr nz,fc_loop

	xor a
	out (sys_mem_select),a
	ei
	ret
	
				
;-----------------------------------------------------------------------------------------	

cursor_x	db 0
cursor_y	db 0
	
;-----------------------------------------------------------------------------

bit_font	 incbin "philfont_1bitplane.bin"

endoffont	 db 0

;-----------------------------------------------------------------------------

colours	dw $000,$fff,$00f,$0f0,$0ff,$f00,$f0f,$ff0
	dw $888,$8ff,$88f,$f8f,$8ff,$f88,$f8f,$ff8

text	db "Blah blah wibble 123456789",11,11
	db "SOME TEXT IN CAPITALS!!!",11,11
	db "And here's a big long line of nonsense, ipsum lorem binary buckets o'fun...",11,11
	db "MESSAGE ENDS.",0
	

winy_list

	ds window_rows*2,0
	
;-----------------------------------------------------------------------------