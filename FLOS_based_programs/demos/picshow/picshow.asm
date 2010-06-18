
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;--------------------------------------------------------------------------------------
; Slideshow demo v2.00
;--------------------------------------------------------------------------------------

; Press ESC to quit
;
; Pics should be numbered in decimal from "01" IE: ***01***.bmp, ***02***.bmp, ***03***.bmp etc
; ****** can be anything, but should be same for all pics. Digits can be anywhere in the filename.

;--------- Test FLOS version ---------------------------------------------------------------------

	push hl
	call kjt_get_version		; check running under FLOS v541+ 
	ld de,$547
	xor a
	sbc hl,de
	jr nc,flos_ok
	ld hl,old_flos_txt
	call kjt_print_string
	pop hl
	xor a
	ret

old_flos_txt

	db "Program requires FLOS v547+",11,11,0

flos_ok	pop hl


;--------- Initialize --------------------------------------------------------------------------
		
	ld hl,pics_dir_txt		;change to pics subdirectory
	call kjt_change_dir
	jp c,hw_error
	jp nz,no_subdir
		
	call kjt_dir_list_first_entry	

getfile	call kjt_dir_list_get_entry	;scan directory for a file with a 0 in the filename
	jp c,hw_error
	cp $24
	jp z,no_files
	bit 0,b
	jr z,gotfile
nxtfile	call kjt_dir_list_next_entry 
	cp $24
	jp z,no_files
	jr getfile

gotfile	ld de,pfilename
exfnlp	ld a,(hl)			;look for a "0" in the filename
	ld (de),a
	or a
	jr z,nxtfile
	cp $30
	jr z,gotdigit
	inc hl
	inc de
	jr exfnlp

gotdigit	ld (fn_digit_loc),de
gd_loop	inc hl			;copy rest of filename
	inc de
	ld a,(hl)
	ld (de),a
	or a
	jr nz,gd_loop
	
	ld hl,(fn_digit_loc)	; put digits "01" into filename for first pic
	ld (hl),$30
	inc hl
	ld (hl),$31

	ld e,32
	call clear128kvram		;clear buffer A

	ld hl,loading_txt
	call kjt_print_string

	call load_pic
	jp nz,load_error

	call kjt_wait_vrt

	ld a,2
	ld (vreg_palette_ctrl),a	; clear palette A
	ld hl,palette
	ld bc,512
	xor a
	call kjt_bchl_memfill
	
	ld ix,bitplane0a_loc	;initialize bitplane pointer buf A = $40000
	ld (ix+0),0
	ld (ix+1),0
	ld (ix+2),4
	ld (ix+3),0
	ld ix,bitplane0b_loc	;initialize bitplane pointer buf B = $60000
	ld (ix+0),0
	ld (ix+1),0
	ld (ix+2),6
	ld (ix+3),0
	
	xor a
	ld (vreg_sprctrl),a		; disable sprites

	ld a,%10000100		
	ld (vreg_vidctrl),a		; select bitmap mode - disable video
	ld a,%00000000		; Switch to y window pos reg
	ld (vreg_rasthi),a		
	ld a,$2e			; 	
	ld (vreg_window),a		; 256 line display
	ld a,%00000100		; Switch to x window pos reg
	ld (vreg_rasthi),a		
	ld a,$7e			
	ld (vreg_window),a		; Start = 112 Stop = 480 (Window Width = 368 pixels)

	call set_up_linecop_lists
	call reveal_pic
	call wait_pic
	call next_pic

;---------------------------------------------------------------------------------------------------

ssloop	call load_pic		; main loop
	jr z,loadpok
	cp $ff			; if a = 255, file not found so..
	jr nz,error_quit
	ld hl,(fn_digit_loc)	; ..loop back to first pic
	ld (hl),$30
	inc hl
	ld (hl),$31
	jr ssloop	
	
loadpok	call reveal_pic
	call wait_pic
	call next_pic
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,ssloop		; loop if ESC key not pressed
	
quit	

	call kjt_flos_display	; restore OS screen
	call kjt_parent_dir
	xor a			; clear carry and quit
	ret


load_error
	
	ld hl,load_error_txt
	
error_quit

	push hl
	call kjt_flos_display
	pop hl
	call kjt_print_string
	call kjt_parent_dir
	xor a
	ret
	

;---------------------------------------------------------------------------------

wait_pic	ld b,50
waitplp	call kjt_wait_vrt
	in a,(sys_keyboard_data)
	cp $76
	ret z			; quit early if ESC key pressed	
	djnz waitplp
	ret
		
;---------------------------------------------------------------------------------
		
next_pic	ld ix,(fn_digit_loc)	;decimal count filename: 01..02..03..
	inc (ix+1)
	ld a,(ix+1)
	cp $3a
	jr nz,nopwrap
	ld (ix+1),$30
	inc (ix)
	ld a,(ix)
	cp $3a
	jr nz,nopwrap
	ld (ix),$30
	ld (ix+1),$31
nopwrap	ret
	
;--------------------------------------------------------------------------------

reveal_pic

	ld hl,$110		;new pic scrolls up from bottom of screen
	ld (flipline),hl		;using linecop to split screen / switch palettes
	
	call kjt_wait_vrt
	
	ld ix,1			;if buffer = 0 use linecop list A (show A, with B rising)
	ld a,(buffer)		;if buffer = 1 use linecop list B (show B, with A rising)
	or a
	jr z,buf0
	ld ix,$101
buf0	ld (vreg_linecop_lo),ix
	ld bc,$7fff		;convert linecop address to Z80 address
	add ix,bc

revloop	ld a,14
	out (sys_mem_select),a	
	ld hl,(flipline)
	ld (ix+10),l
	ld a,h
	or $c0
	ld (ix+11),a
	inc hl
	ld (ix+20),l
	ld a,h
	or $c0
	ld (ix+21),a
	xor a
	out (sys_mem_select),a
	dec hl
	
	ld de,4
	xor a
	sbc hl,de
	ld (flipline),hl
	ld de,$09
	xor a
	sbc hl,de
	jr c,revdone
	
	call kjt_wait_vrt
	in a,(sys_keyboard_data)
	cp $76
	jr nz,revloop
	ret
	
revdone	ld a,(buffer)		;flip buffers
	xor 1
	ld (buffer),a
	ret
	

;------------------------------------------------------------------------------------------


set_up_linecop_lists

	ld a,%00010010
	out (sys_mem_select),a	;use alternative write page, source page = 1
	ld a,14
	out (sys_alt_write_page),a

linecopl1	ld hl,$8000
	ld (hl),$04		;wait for line $4
	inc hl			;
	ld (hl),$c0
	inc hl

	ld (hl),$01		;reg = $0201 vreg_vidctrl 
	inc hl
	ld (hl),$82		
	inc hl
	ld (hl),$80		;use bpl reg A
	inc hl
	ld (hl),$00		
	inc hl

	ld (hl),$0f		;reg = $020f vreg_palette_ctrl 
	inc hl
	ld (hl),$82		
	inc hl
	ld (hl),$00		;show palette A
	inc hl
	ld (hl),$00		
	inc hl

	ld (hl),$a0		;wait for line y (dynamic)
	inc hl			
	ld (hl),$c0
	inc hl

	ld (hl),$01		;reg = $0201 vreg_vidctrl 
	inc hl
	ld (hl),$82		
	inc hl
	ld (hl),$a0		;use bpl reg B
	inc hl
	ld (hl),$00		
	inc hl

	ld (hl),$43		;reg = $0243 reset datafetch counter 
	inc hl
	ld (hl),$82		
	inc hl
	ld (hl),$00		
	inc hl
	ld (hl),$00		
	inc hl

	ld (hl),$a1		;wait for line y+1 (dynamic)
	inc hl			
	ld (hl),$c0
	inc hl

	ld (hl),$0f		;reg = $020f vreg_palette_ctrl 
	inc hl
	ld (hl),$82		
	inc hl
	ld (hl),$01		;show palette B
	inc hl
	ld (hl),$00		
	inc hl

	ld (hl),$ff		;wait for $1ff - end list
	inc hl			
	ld (hl),$c1
	inc hl
	
	
linecopl2	ld hl,$8100
	ld (hl),$04		;wait for line $8
	inc hl			;
	ld (hl),$c0
	inc hl

	ld (hl),$01		;reg = $0201 vreg_vidctrl 
	inc hl
	ld (hl),$82		
	inc hl
	ld (hl),$a0		;use bpl reg B
	inc hl
	ld (hl),$00		
	inc hl

	ld (hl),$0f		;reg = $020f vreg_palette_ctrl 
	inc hl
	ld (hl),$82		
	inc hl
	ld (hl),$01		;show palette B
	inc hl
	ld (hl),$00		
	inc hl

	ld (hl),$a0		;wait for line y (dynamic)
	inc hl			
	ld (hl),$c0
	inc hl

	ld (hl),$01		;reg = $0201 vreg_vidctrl 
	inc hl
	ld (hl),$82		
	inc hl
	ld (hl),$80		;use bpl reg A
	inc hl
	ld (hl),$00		
	inc hl
	
	ld (hl),$43		;reg = $0243 reset datafetch counter 
	inc hl
	ld (hl),$82		
	inc hl
	ld (hl),$00		
	inc hl
	ld (hl),$00		
	inc hl

	ld (hl),$a1		;wait for line y+1 (dynamic)
	inc hl			
	ld (hl),$c0
	inc hl

	ld (hl),$0f		;reg = $020f vreg_palette_ctrl 
	inc hl
	ld (hl),$82		
	inc hl
	ld (hl),$00		;show palette A
	inc hl
	ld (hl),$00		
	inc hl
	
	
	ld (hl),$ff		;wait for $1ff - end list
	inc hl			
	ld (hl),$c1
	inc hl

	xor a
	out (sys_mem_select),a	;back to bank 0
	ret


;-------------------------------------------------------------------------------------------


load_pic

	call get_palette
	ret nz
	ld a,(buffer)
	xor 1
	or 2
	ld (vreg_palette_ctrl),a	; copy loaded palette to palette A (buffer = 0)
	ld hl,palette_buffer	; or palette B (buffer = 1)
	ld de,palette
	ld bc,512
	ldir
		
	call get_image_data
	ret



get_palette


	ld hl,pfilename		; does filename exist?
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

	xor a
	dec a
	ret

pic_not_bmp

	ld hl,not_bmp_txt
err_end	xor a
	inc a
	ret
	
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

	ld hl,pfilename		; does filename exist?
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

				
	ld a,(buffer)		;clear VRAM $40000-$60000 (or $60000-$7ffff)
	xor 1			;if "buffer" is 0, load pic to $60000
	rlca			;if "buffer" is 1, load pic to $40000
	rlca
	rlca
	rlca
	or 32
	ld e,a
	call clear128kvram
	
	ld hl,0			;now copy pic data to display window VRAM $40000/$60000 with blitter		
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
	ld a,(buffer)
	xor 1
	rlca
	add a,4
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
		
	
;------------------------------------------------------------------------------------------

clear128kvram

; set e to first vram page to clear

	push de
	call kjt_page_in_video
	pop de
	ld d,16
cmlp3	ld a,e
	ld (vreg_vidpage),a
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
	dec d
	jr nz,cmlp3	
	call kjt_page_out_video
	ret

;------------------------------------------------------------------------------------------

hw_error	ld hl,hw_error_txt
	call kjt_print_string
	xor a
	ret
	
no_files	ld hl,no_files_txt
	call kjt_print_string
	call kjt_parent_dir
	xor a
	ret

no_subdir	ld hl,no_subdir_txt
	call kjt_print_string
	xor a
	ret
		
;------------------------------------------------------------------------------------------

pics_dir_txt	db "pics",0

no_subdir_txt	db "No pics subdirectory",11,0

load_error_txt	db "File not found",11,0

no_files_txt	db "Cant find any numbered pics",11,0

hw_error_txt	db "Disk Hardware error",11,0

loading_txt	db "Loading..",11,0	
	
not_bmp_txt	db "Not a .bmp file",11,0

not_256cols_txt	db "Not a 256 colour pic",11,0

not_uncompressed_txt db "File is compressed",11,0

not_xmult8_txt	db "Width not multiple of 8 pixels",11,0
	
too_big_txt	db "Dimensions too big",11,0

pfilename		ds 32,0

pic_width		dw 0
pic_height	dw 0
source_lo		dw 0
source_hi		db 0
dest_lo		dw 0
dest_hi		db 0
vid_bank 		db 0
buffer		db 0
flipline		dw 0
fn_digit_loc	dw 0

header_buffer	ds 1024+54,0	

palette_buffer	ds 512,0

image_buffer	db 0

;-------------------------------------------------------------------------------------------
