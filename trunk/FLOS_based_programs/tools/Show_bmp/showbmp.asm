
; App: Shows .bmp pictures  - v1.02 By Phil '09
;
; Usage: showbmp [filename]
;
; Notes:
; Max dimensions of pic = 368 x 256
; Pic must be Windows format bmp, uncompressed, 256 colours. x width multiple of 8 pixels


;---Standard header for OSCA and FLOS ----------------------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

required_flos	equ $547
include 		"test_flos_version.asm"

	
;-------- Parse command line arguments ---------------------------------------------------------
	

	ld a,(hl)			; examine argument text, if encounter 0: show use
	or a			
	jp z,show_use

	push hl			; copy args to working filename string
	ld de,filename
	ld b,16
fnclp	ld a,(hl)
	or a
	jr z,fncdone
	cp " "
	jr z,fncdone
	ld (de),a
	inc hl
	inc de
	djnz fnclp
fncdone	xor a
	ld (de),a			; null terminate filename
	pop hl



;---------Load and Show Picture -----------------------------------------------------------------


	ld hl,loading_txt
	call kjt_print_string
	
	call get_palette
	jp nz,error_quit
	call get_image_data
	jp nz,error_quit

	call show_pic
		
	call kjt_wait_key_press

	call kjt_flos_display
	xor a			;restore OS display on exit
	ret


error_quit

	call kjt_print_string
	xor a
	ret



show_use

	ld hl,usage_txt
	call kjt_print_string
	xor a
	ret
	
	
;-------------------------------------------------------------------------------------------

get_palette


	ld hl,filename		; does filename exist?
	call kjt_find_file
	jp nz,pic_load_error

	ld ix,0
	ld iy,1024+54
	call kjt_set_load_length	; load in .bmp header bytes
	ld hl,header_buffer
	call kjt_force_load
	jp nz,pic_load_error

	ld hl,(header_buffer)	; check header info
	ld de,$4d42
	xor a
	sbc hl,de
	jp nz,pic_not_bmp
	
	ld hl,(header_buffer+28)
	ld de,8
	xor a
	sbc hl,de
	jp nz,pic_not_256cols
	
	ld hl,(header_buffer+30)
	ld a,h
	or l
	jp nz,pic_not_uncompressed
	
	ld hl,(header_buffer+18)
	ld (pic_width),hl
	ld a,l
	and 7
	jp nz,pic_not_xmult8
	
	ld hl,(pic_width)
	ld de,369
	xor a
	sbc hl,de
	jr nc,pic_too_big
			
	ld hl,(header_buffer+22)
	ld (pic_height),hl
	dec hl
	ld a,h
	or a
	jp nz,pic_too_big	
	
	ld de,palette_buffer	;convert palette from 24bit to 12bit
	ld hl,header_buffer+54	;start of 24 bit palette
	ld b,0			;256 colours to do
palclp	ld c,(hl)
	inc hl
	srl c
	srl c
	srl c
	srl c			;12 bit blue
	ld a,(hl)
	inc hl
	and $f0			;12 bit green << 4
	or c
	ld (de),a
	inc de
	ld a,(hl)
	inc hl
	inc hl
	srl a
	srl a
	srl a
	srl a
	ld (de),a
	inc de
	djnz palclp
	xor a
	ret
	
	

pic_load_error

	ld hl,load_error_txt
err_end	xor a
	inc a
	ret
	
pic_not_bmp

	ld hl,not_bmp_txt
	jr err_end
	
pic_not_256cols

	ld hl,not_256cols_txt
	jr err_end

pic_not_uncompressed

	ld hl,not_uncompressed_txt
	jr err_end

pic_not_xmult8

	ld hl,not_xmult8_txt
	jr err_end
	
pic_too_big

	ld hl,too_big_txt
	jr err_end
			
;--------------------------------------------------------------------------------------------

get_image_data

	ld a,16
	ld (vid_bank),a		; pic data to load at video RAM $20000 onwards

	ld hl,filename		; does filename exist?
	call kjt_find_file
	jp nz,pic_load_error

	ld ix,0
	ld iy,1024+54
	call kjt_set_file_pointer	; skip palette and header
	
imgloadlp	ld ix,0
	ld iy,8192
	call kjt_set_load_length	; load buffer (in system RAM) is 8k
	
	ld hl,image_buffer
	ld b,0
	call kjt_force_load		; load 8k of pic into buffer
	
	push af
	ld a,(vid_bank)
	ld (vreg_vidpage),a
	call kjt_page_in_video	; copy buffer to VRAM
	ld hl,image_buffer
	ld de,video_base
	ld bc,8192
	ldir
	call kjt_page_out_video
	pop af
	jr nz,load_done		; will give EOF error at end of file 
	
	ld a,(vid_bank)
	inc a
	ld (vid_bank),a
	jr imgloadlp
	
load_done

	ld e,32			;clear VRAM $40000-$60000
	ld a,e
cmlp3	ld (vreg_vidpage),a
	call kjt_page_in_video
	ld hl,video_base
	ld c,$10
	xor a
cmlp2	ld b,0
cmlp1	ld (hl),a
	inc hl
	ld (hl),a
	inc hl
	djnz cmlp1
	dec c
	jr nz,cmlp2
	inc e
	ld a,e
	cp 48
	jr nz,cmlp3	
	call kjt_page_out_video

	ld hl,0			;now copy pic data to display window VRAM ($40000) with blitter		
	ld (source_lo),hl		
	ld a,2
	ld (source_hi),a
	ld bc,(pic_height)		;bmps are upside down so go to last line of pic for
	dec bc			;first line of display
	ld b,c
	ld de,(pic_width)
gopicll	ld hl,(source_lo)		
	add hl,de
	ld (source_lo),hl
	jr nc,smsb_ok
	ld a,(source_hi)
	inc a
	ld (source_hi),a
smsb_ok	djnz gopicll

	ld hl,368/2
	ld de,(pic_width)
	srl d
	rr e
	xor a
	sbc hl,de
	ld (dest_lo),hl		;centralize pic on display (x)
	ld a,4
	ld (dest_hi),a
	
	ld hl,256/2
	ld de,(pic_height)
	srl d
	rr e
	xor a
	sbc hl,de
	ld a,h
	or l
	jr z,gotmidy
	ld b,l			;centralize pic on display (y)
	ld de,368			
posmidy	ld hl,(dest_lo)	
	add hl,de
	ld (dest_lo),hl
	jr nc,dmsb_ok
	ld a,(dest_hi)
	inc a
	ld (dest_hi),a
dmsb_ok	djnz posmidy

gotmidy	xor a
	ld (blit_src_mod),a		;no modulos required
	ld (blit_dst_mod),a
	ld a,1
	ld (blit_height),a		;height = 1 (one line at a time, but half the width)
	ld a,%01000000
	ld (blit_misc),a		;ascending blits
	ld a,(pic_height)
	ld b,a			;lines to copy

lineloop	call wait_blit
	ld hl,(source_lo)
	ld (blit_src_loc),hl
	ld a,(source_hi)
	ld (blit_src_msb),a
	ld hl,(dest_lo)
	ld (blit_dst_loc),hl
	ld a,(dest_hi)
	ld (blit_dst_msb),a
	
	ld de,(pic_width)		;blit width = half of pic width (as max = 256 pixels) 
	srl d
	rr e
	ld a,e
	dec a
	ld (blit_width),a		;set width and start blit
	
	ld de,(pic_width)
	ld hl,(source_lo)		;for next line, subtract width of pic
	xor a
	sbc hl,de
	ld (source_lo),hl
	jr nc,smsb_ok2
	ld a,(source_hi)
	dec a
	ld (source_hi),a
smsb_ok2
	ld de,368			;width of destination = display line 358 pixels
	ld hl,(dest_lo)	
	add hl,de
	ld (dest_lo),hl
	jr nc,dmsb_ok2
	ld a,(dest_hi)
	inc a
	ld (dest_hi),a
dmsb_ok2
	djnz lineloop
	call wait_blit		; ensure blit has finished on exit (not essential..)
	ret



wait_blit

	ld a,(vreg_read)
	bit 4,a
	jr nz,wait_blit
	ret
		
;--------------------------------------------------------------------------------------------


show_pic
	call kjt_wait_vrt		; for a clean switchover
	
	xor a
	ld (vreg_sprctrl),a		; disable sprites
	ld a,%10000100		
	ld (vreg_vidctrl),a		; select bitmap/chunky mode - disable video
	ld a,%00000000		; Switch to y window pos reg
	ld (vreg_rasthi),a		
	ld a,$2e			; 	
	ld (vreg_window),a		; 256 line display
	ld a,%00000100		; Switch to x window pos reg
	ld (vreg_rasthi),a		
	ld a,$7e			
	ld (vreg_window),a		; Start = 112 Stop = 480 (Window Width = 368 pixels)
	
	ld ix,bitplane0a_loc	; video datafetch = $40000.
	ld (ix+0),0
	ld (ix+1),0
	ld (ix+2),4
	
	ld hl,palette_buffer	; copy pic palette
	ld de,palette
	ld bc,512
	ldir

	call kjt_wait_vrt		; for a clean switchover

	ld a,%10000000		
	ld (vreg_vidctrl),a		; select bitmap/chunky mode - enable video
	ret
	
			
;============================================================================================

loading_txt	db "Loading...",11,0

load_error_txt	db "Load error - File not found?",11,0

not_bmp_txt	db "Not a .bmp file",11,0

not_256cols_txt	db "Not a 256 colour pic",11,0

not_uncompressed_txt db "File is compressed",11,0

not_xmult8_txt	db "Width not multiple of 8 pixels",11,0
	
too_big_txt	db "Dimensions too big",11,0

test_fn		db "pic.bmp",0

usage_txt		db "Use: Showbmp filename.bmp (v1.00)",11,11
		db "BMP file must be 256 colours",11
		db "uncompressed, 368x256 or smaller",11
		db "with width a multiple of 8 pixels",11,11,0
		
filename		ds 32,0

pic_width		dw 0
pic_height	dw 0
source_lo		dw 0
source_hi		db 0
dest_lo		dw 0
dest_hi		db 0

vid_bank 		db 0

header_buffer	ds 1024+54,0	

palette_buffer	ds 512,0

image_buffer	db 0

;-------------------------------------------------------------------------------------------

