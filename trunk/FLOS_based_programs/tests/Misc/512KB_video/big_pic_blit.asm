
; Tests blitter access to entire 512KB video RAM

; Loads large pic into video RAM (64KB upwards), uses blitter to copy
; a 256x256 area of it to the display window (0-64KB). Chunky mode.

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;------- Load big pic ----------------------------------------------------------------------

	ld hl,pic_filename
	call kjt_find_file
	jp nz,fferror
	ld a,8
	ld (bank),a
	ld b,56
loadloop	push bc
	ld ix,$0000
	ld iy,$2000
	call kjt_set_load_length
	ld hl,buffer
	ld b,0
	call kjt_force_load
	jp nz,lferror
	ld a,(bank)
	ld (vreg_vidpage),a
	inc a
	ld (bank),a
	call kjt_page_in_video
	ld hl,buffer
	ld de,$2000
	ld bc,$2000
	ldir
	call kjt_page_out_video
	pop bc
	djnz loadloop

	
;-------- Initialize video --------------------------------------------------------------------

	ld hl,0
	ld (palette),hl
	ld a,%00000100
	ld (vreg_vidctrl),a		; disable video whilst setting up
	
	ld a,%00000000		; select y window pos register
	ld (vreg_rasthi),a		; 
	ld a,$2e			; set 256 line display
	ld (vreg_window),a
	ld a,%00000100		; switch to x window pos register
	ld (vreg_rasthi),a		
	ld a,$bb
	ld (vreg_window),a		; set 256 pixels wide window

	ld hl,colours
	ld de,palette		; upload spectrum palette
	ld bc,512
	ldir
	
	ld ix,bitplane0a_loc	; Show video buffer 0 or 1 
	ld hl,0			; Video window start address		
	ld a,0 
set_vaddr	ld (ix),l			;\ 
	ld (ix+1),h		;- Video fetch start address for this frame
	ld (ix+2),a		;/
		
	ld a,%10000000
	ld (vreg_vidctrl),a		; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)	

;---------------------------------------------------------------------------------------------------

	ld hl,sin_table		; upload sine table to math unit
	ld de,mult_table
	ld bc,$200
	ldir	

;---------------------------------------------------------------------------------------------------

	ld ix,ytable		; fill in ytable of offsets
	ld hl,0
	ld c,1
	ld de,672			; pic width
	ld b,0
ytloop	ld (ix),l
	ld (ix+1),h
	ld (ix+2),c
	add hl,de
	jr nc,ytok1
	inc c
ytok1	inc ix
	inc ix
	inc ix
	inc ix
	ld (ix),l
	ld (ix+1),h
	ld (ix+2),c
	add hl,de
	jr nc,ytok2
	inc c
ytok2	inc ix
	inc ix
	inc ix
	inc ix
	djnz ytloop
	

;--------- Main Loop ---------------------------------------------------------------------------------


wvrtstart	ld a,(vreg_read)		; wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend
	
;	ld hl,$f00
;	ld (palette),hl

	call vrt_routines

;	ld hl,0
;	ld (palette),hl
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		;loop if ESC key not pressed
	xor a
	ld a,$ff			;quit (restart OS)
	ret


;-------------------------------------------------------------------------------------------

	speed equ 2

vrt_routines

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
xminok	ld de,672-256
	xor a
	sbc hl,de
	jr c,xdone
	add hl,de
	ld (xpos),hl
	ld de,65536-speed
	ld (xdisp),de
xdone
	
	ld hl,672-256
	ld (mult_write),hl
	ld a,(y_angle)
	ld (mult_index),a
	ld hl,(mult_read)
	ld (ypos),hl
	inc a
	and $7f
	ld (y_angle),a


	ld hl,(ypos)		;calculate source address for blit
	add hl,hl
	add hl,hl
	ld de,ytable
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld a,(hl)
	ex de,hl
	ld de,(xpos)
	add hl,de
	jr nc,nococa
	inc a
nococa	ld (blit_src_loc),hl	;source address
	ld (blit_src_msb),a		;source address msb
	ld a,$a0			;source modulo (low byte)
	ld (blit_src_mod),a

	ld de,0
	ld (blit_dst_loc),de
	ld a,$00
	ld (blit_dst_msb),a
	ld a,$00
	ld (blit_dst_mod),a
	ld a,%01000001		;blitter in ascending mode, legacy msbs = 0, src mod msb =1
	ld (blit_misc),a
	ld a,255
	ld (blit_height),a
	ld a,255
	ld (blit_width),a
	nop			;ensure blit has begun before testing busy flag
	nop
	
waitblit	ld a,(vreg_read)		;wait for blit to complete
	bit 4,a 
	jr nz,waitblit
	ret

;-------------------------------------------------------------------------------------------


lferror 	pop bc
fferror	ld hl,error_txt
	call kjt_print_string
	xor a
	ret

	
;-------------------------------------------------------------------------------------------

pic_filename	db "tut_chunky.bin",0

error_txt		db "Load error. Missing File?",11,11,0

buffer		ds 8192,0

bank 		db 0

colours		incbin "tut_palette.bin"

xpos		dw 128
ypos		dw 0

xdisp		dw speed
y_angle		db 0

ytable		ds 4*512

sin_table		incbin "sin_table.bin"

;--------------------------------------------------------------------------------------------