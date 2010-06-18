
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;--------------------------------------------------------------------------------------
; Tests Line draw system writing to entire 512KB video RAM.
; A triangle is drawn at a new offset each frame.
; The datafetch window scrolls through VRAM (up)
; Press ESC to quit
;--------------------------------------------------------------------------------------

window_width	equ 288
window_height	equ 224

number_of_lines	equ 3


	di			; disable interrupts

	ld a,%00000000
	out (sys_irq_enable),a	; disable all irq sources

	ld a,%00000111
	out (sys_clear_irq_flags),a	; clear all irq flags 

	ld a,%00000000		; select y window pos register
	ld (vreg_rasthi),a		; 
	ld a,$4c			; set 224 line display
	ld (vreg_window),a
	ld a,%00000100		; switch to x window pos register
	ld (vreg_rasthi),a		
	ld a,$9b
	ld (vreg_window),a		; set 288 pixels wide window

	ld a,%10000000
	ld (vreg_vidctrl),a		; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)
	
	call kjt_page_in_video
	xor a
	ld e,a
vploop	ld (vreg_vidpage),a		 
	ld hl,$2000		; clear video ram
	ld bc,$2000
clrbplp	ld (hl),e
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,clrbplp
	inc e
	ld a,e
	cp 64
	jr nz,vploop
	call kjt_page_out_video

	ld ix,palette		; make a test palette
	ld (ix),0
	inc ix
	ld (ix),0
	inc ix
	ld hl,$fff
	ld de,4
	ld b,255
paloop	ld (ix),l
	inc ix
	ld (ix),h
	inc ix
	xor a
	sbc hl,de
	djnz paloop	
	
	call line_draw_setup

;------------------------------------------------------------------------------------------------


wvrtstart	ld a,(vreg_read)		; wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend
	
	ld hl,$f00
	ld (palette),hl

	ld hl,counter
	inc (hl)

	call vrt_routines
	
	ld hl,0
	ld (palette),hl
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		;loop if ESC key not pressed
	
	xor a
	ld a,$ff			;quit (restart OS)
	ret


;-------------------------------------------------------------------------------------------------

vrt_routines

	ld hl,(vid_window_start)	; y line number 	
	inc hl
	ld (vid_window_start),hl
	ld de,1819
	xor a
	sbc hl,de
	jr c,lsok
	ld hl,224
	ld (vid_window_start),hl
	
lsok	ld ix,bitplane0a_loc	; Set datafetch start for display window 
	ld hl,(vid_window_start)	; line number 	
	add hl,hl
	ld de,y_offset_list
	add hl,de
	ld e,(hl)			; e = addr/8 lsb
	inc hl
	ld d,(hl)			; d = addr/8 msb
	ex de,hl			; hl = line offset/8
	sla l			; multiply line offset by 8
	rl h
	rl c
	sla l
	rl h
	rl c
	sla l
	rl h
	rl c	
	ld (ix),l			;\ 
	ld (ix+1),h		;- Video fetch start address for this frame
	ld (ix+2),c		;/

	ld hl,$00f
	ld (palette),hl		;raster time marker

	call make_coords

	ld iy,counter		;use for object colour
	ld ix,coord_list
	ld b,number_of_lines
	call draw_lines

	ld hl,$000
	ld (palette),hl		;raster time marker

	ret

;------------------------------------------------------------------------------------------------------

speed equ 2

make_coords

	ld iy,root_coord_list	;add on an x/y offset to basic shape coords
	ld ix,coord_list
	ld b,number_of_lines+1
mcl_loop	ld l,(iy)
	ld h,(iy+1)
	ld de,(xoffset)
	add hl,de
	ld (ix),l
	ld (ix+1),h
	inc ix
	inc ix
	inc iy
	inc iy
	ld l,(iy)
	ld h,(iy+1)
	ld de,(yoffset)
	add hl,de
	ld (ix),l
	ld (ix+1),h
	inc ix
	inc ix
	inc iy
	inc iy
	djnz mcl_loop


	ld hl,(xoffset)		;update offset
	ld de,(xdisp)
	add hl,de
	ld (xoffset),hl
	bit 7,h
	jr z,xminok
	ld hl,0
	ld (xoffset),hl
	ld de,speed
	ld (xdisp),de
	jr xdone
xminok	ld de,233
	xor a
	sbc hl,de
	jr c,xdone
	add hl,de
	ld (xoffset),hl
	ld de,65536-speed
	ld (xdisp),de
xdone
	ld hl,(yoffset)
	ld de,(ydisp)
	add hl,de
	ld (yoffset),hl
	bit 7,h
	jr z,yminok
	ld hl,0
	ld (yoffset),hl
	ld de,speed
	ld (ydisp),de
	jr ydone
yminok	ld de,1756
	xor a
	sbc hl,de
	jr c,ydone
	add hl,de
	ld (yoffset),hl
	ld de,65536-speed
	ld (ydisp),de
ydone	ret
	
;------------------------------------------------------------------------------------------------------
; V6 Line draw code (512MB VRAM)
;------------------------------------------------------------------------------------------------------

line_draw_setup

; Call once before any line draw operations 


	ld hl,linedraw_constants		; copy the video offset constants to the 
	ld de,linedraw_lut0			; line draw hardware lookup table
	ld bc,16
	ldir
	
	ld bc,1820			; make a list of line offsets. Entries are / 8
	ld ix,y_offset_list			; in order to keep 'em in 16 bits
	ld hl,65520
	ld de,window_width/8
yoloop	ld (ix),l
	ld (ix+1),h
	xor a
	sbc hl,de
	inc ix
	inc ix
	dec bc
	ld a,b
	or c
	jr nz,yoloop
	ret
	
;-------------------------------------------------------------------------------------------------------

draw_lines

; call this routine to draw lines from coord list. 
; Note coord system has y=0 at the highest location in VRAM

; set IY to address holding line colour
; set IX to coord list
; set B to number of lines
		
ld_wait	ld a,(vreg_read)		; ensure any previous line draw / blit op is complete
	and $10			; at start (as an odd number of line draws will recommence
	jr nz,ld_wait		; with the same register set)

next_line	ld c,0			; reset the octant code / address MSBs
	ld l,(ix+2)		; y0 LSB
	ld h,(ix+3)		; hl = index in line offset list
	add hl,hl
	ld de,y_offset_list
	add hl,de
	ld e,(hl)			; e = addr/8 lsb
	inc hl
	ld d,(hl)			; d = addr/8 msb
	ex de,hl			; hl = line offset/8
	sla l			; multiply line offset by 8
	rl h
	rl c
	sla l
	rl h
	rl c
	sla l
	rl h
	rl c	
	ld e,(ix)			
	ld d,(ix+1)		; de = x0
	add hl,de			; hl = video start address
	jr nc,no_sacar
	inc c
no_sacar	ld (linedraw_reg2),hl	; Hardware line draw constant: Start Address [15:0]
	sla c			; shift line address MSBs to [11:9] of octant code reg

	ld l,(ix+4)			
	ld h,(ix+5)		; hl = x1
	xor a			; clear carry flag
	sbc hl,de			; hl = delta_x (x1-x0)
	bit 7,h
	jr z,xdeltapos		; is delta_x positive?
	ex de,hl			; make it positive if not
	xor a
	ld l,a
	ld h,a
	sbc hl,de			
	set 4,c			; update octant settings bit 4
	
xdeltapos	ld (delta_x),hl		; stash delta_x
	ld e,(ix+2)		
	ld d,(ix+3)		; de = y0
	ld l,(ix+6)
	ld h,(ix+7)		; hl = y1
	xor a
	sbc hl,de			; hl = delta y (y1-y0)
	bit 7,h
	jr z,ydeltapos		; is delta_y positive?
	ex de,hl			; make it positive if not
	xor a
	ld l,a
	ld h,a
	sbc hl,de			
	set 5,c			; update octant settings bit 5

ydeltapos	ld (delta_y),hl		; stash delta_y
	ld de,(delta_x)		; hl = delta_y, de = delta_x
	xor a
	sbc hl,de			; hl = (delta_y - delta_x)
	jr c,horiz_seg		; if delta_x > delta_y then the line has horizontal segments

	xor a			; vertical segment code.. 
	ex de,hl			; de = (delta_y - delta_x)
	ld l,a			
	ld h,a			; hl = 0
	sbc hl,de			; hl = (delta_x - delta_y)
	add hl,hl
	ld (linedraw_reg0),hl	; Hardware linedraw Constant: 2 x (delta_x - delta_y)	
	ld hl,(delta_x)
	add hl,hl
	ld (linedraw_reg1),hl	; Hardware Linedraw Constant: 2 x delta_x	
	set 6,c			; update octant settings
	ld de,(delta_y)		; de = line length
	jp line_len
	
horiz_seg	add hl,hl
	ld (linedraw_reg0),hl	; Hardware Linedraw Constant: 2 x (delta_y - delta_x)
	ld hl,(delta_y)
	add hl,hl
	ld (linedraw_reg1),hl	; Hardware Linedraw Constant: 2 x delta_y

line_len	ld a,d			; de = line length (assumes length < $0200, as it should be)
	or c			; OR in the octant / addr MSB bits
	ld d,a			; DE = composite of MSB,octant code and line length

	ld a,(iy)			; get line colour
	ld hl,vreg_read
	
ld_wait1	bit 4,(hl)		; ensure any previous line draw / blit op is complete
	jr nz,ld_wait1		; before restarting line draw operation
	
	ld (linedraw_colour),a
	ld (linedraw_reg3),de	; line length, octant code, y address MSB & Start line draw.
	
	ld de,4			; add 4 to join-the-dots a-b-c-d or add 8 to link coord pairs a-b, c-d, etc
	add ix,de			; move to next coordinate group
	dec b			; countdown lines to do
	jp nz,next_line		; end if last line, else prep line in reg buffer 1
	ret
	

;-------------------------------------------------------------------------------------------------------------------

linedraw_constants

	dw (65536-window_width)+1
	dw (65536-window_width)-1
	dw window_width+1	
	dw window_width-1
	dw 1
	dw 65535
	dw (65536-window_width)
	dw window_width

delta_x	dw 0
delta_y	dw 0

;-------------------------------------------------------------------------------------------------------------------

y_offset_list

	ds 3640,0			; ie: (512KB/288)*2 line offsets divided by 8	
		
;-------------------------------------------------------------------------------------------------------

counter       	db 0

xoffset		dw 0
yoffset		dw 0
xdisp		dw speed
ydisp		dw speed

vid_window_start	dw 224

root_coord_list	dw 0,0, 50,0, 25,50, 0,0
		
coord_list	ds (number_of_lines + 1) * 4,0

;---------------------------------------------------------------------------------------------------------------------