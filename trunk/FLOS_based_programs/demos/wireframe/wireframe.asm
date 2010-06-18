;---------------------------------------------------------------------------------------
; 3D Wire frame demo for V5Z80P.
; V1.00 by Phil Ruston 2008.
;--------------------------------------------------------------------------------------- 
;
; Notes: Y-scaling required on VGA/NTSC displays as the pixels are noticably tall.
;        60Hz modes also require optimization stop slow downs.
;
;---------------------------------------------------------------------------------------


;---Standard header for OSCA and OS --------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

half_vbuffer_size	equ $8000		; IE: 2nd video buffer starts at $10000

window_width	equ 288
window_height	equ 224

;-------- Initialize --------------------------------------------------------------------


	di			; disable interrupts

	ld a,%00000000
	out (sys_irq_enable),a	; disable all irq sources

	ld a,%00000111
	out (sys_clear_irq_flags),a	; clear all irq flags 

	ld a,%00000000		; select y window pos register
	ld (vreg_rasthi),a		; 
	ld a,$4b			; set 216 line display
	ld (vreg_window),a
	ld a,%00000100		; switch to x window pos register
	ld (vreg_rasthi),a		
	ld a,$ac
	ld (vreg_window),a		; set 288 pixels wide window

	ld a,%10000000
	ld (vreg_vidctrl),a		; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)

	
	call kjt_page_in_video
	xor a
	ld e,a
vploop	ld (vreg_vidpage),a		 
	ld hl,$2000		; clear first 192KB of video ram
	ld bc,$2000
clrbplp	ld (hl),0
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,clrbplp
	inc e
	ld a,e
	cp 24
	jr nz,vploop
	call kjt_page_out_video


	ld a,2
	ld (first_passes),a
	
	call line_draw_setup

	call setup_star_sprites
	
	call setup_sine_scroll
	
	call setup_logo_sprites

	call setup_music
	
	ld hl,font_cols
	ld de,palette
	ld bc,64
	ldir

	ld hl,logo_cols
	ld de,palette+256
	ld bc,64
	ldir

	ld hl,sin_table		; upload sine table to math unit
	ld de,$0600
	ld bc,$200
	ldir

	ld a,%00000011
	ld (vreg_sprctrl),a		; enable sprites + low/hi priority mode
	
	ld hl,vector_cols
	ld de,palette+($a0*2)
	ld bc,32
	ldir

	
;--------- Main Loop ---------------------------------------------------------------------------------


wvrtstart	ld a,(vreg_read)		; wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend
	
	call vrt_routines
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		;loop if ESC key not pressed
	
	xor a
	ld a,$ff			;quit (restart OS)
	ret


;-------------------------------------------------------------------------------------------------

vrt_routines

	ld ix,bitplane0a_loc	; Show video buffer 0 or 1 
	ld hl,12*288		; Buffer 0 address		
	ld a,(buffer)		
	or a
	jr z,set_vaddr
	xor a
	ld hl,half_vbuffer_size+(12*288/2)	; Buffer 1 address
	add hl,hl
	rl a			; Put carry in A bit 0 
set_vaddr	ld (ix),l			;\ 
	ld (ix+1),h		;- Video fetch start address for this frame
	ld (ix+2),a		;/


;flip buffer flag

	ld a,(buffer)		;swap buffer flag
	xor 1
	ld (buffer),a


	call plot_stars

;	ld hl,$08f
;	ld (palette),hl		;raster time marker


; delete old lines (if necessary)

	ld a,(first_passes)		;nothing to delete on first 2 frames
	or a
	jr z,ok_erase
	dec a
	ld (first_passes),a
	jr no_erase
ok_erase	call erase_lines

no_erase

	call play_tracker
	call update_sound_hardware


; generate new coordinates

;	ld hl,$0f0
;	ld (palette),hl		;raster time marker
	
	call adjust_rotation 
	call rotate_3d_coordinates
	call scale_3d_coordinates

; plot sine scroller

;	ld hl,$f08
;	ld (palette),hl		;raster time marker

	call sine_scroll


; draw new lines

;	ld hl,$00f
;	ld (palette),hl		;raster time marker

	call sort_lines

;	ld hl,$088
;	ld (palette),hl		;raster time marker

	call draw_lines_in_z_order


;update star positions

;	ld hl,$0f8
;	ld (palette),hl		;raster time marker

	call move_stars

;	ld hl,$0
;	ld (palette),hl		;raster time marker

	ret

;------------------------------------------------------------------------------------------------------

adjust_rotation

	ld ix,(object_addr_base)
	
	ld a,(rotate_angle1)	;z
	add a,(ix+4)
	ld (rotate_angle1),a
	
	ld a,(rotate_angle2)	;y
	add a,(ix+3)
	ld (rotate_angle2),a
	
	ld a,(rotate_angle3)	;x
	add a,(ix+2)
	ld (rotate_angle3),a
	
	ld a,(hold_time)
	or a
	jr z,not_hold
	dec a
	ld (hold_time),a
	ret nz
	ld de,-32
	ld (zoom_displacement),de
	ret
	
not_hold	ld de,(zoom_displacement)
	ld hl,(zoom)
	add hl,de
	ld (zoom),hl
	bit 7,d
	jr z,zoomplus
	ld de,256
	xor a
	sbc hl,de
	ret nc
	xor a
	ld (rotate_angle1),a
	ld (rotate_angle3),a
	ld a,128
	ld (rotate_angle2),a

	ld de,32
	ld (zoom_displacement),de
	ld a,(show_object)
	inc a
	ld (show_object),a
	cp maxobject
	ret nz
	xor a
	ld (show_object),a
	ret
	
zoomplus	ld ix,(object_addr_base)
	ld e,(ix+5)
	ld d,(ix+6)			;de = max zoom
	xor a
	sbc hl,de
	ret c
	ld de,0
	ld (zoom_displacement),de
	ld a,255
	ld (hold_time),a
	ret	

;------------------------------------------------------------------------------------------------------
; 16 bit rotate and scale code, using maths unit
;------------------------------------------------------------------------------------------------------

rotate_3d_coordinates

	ld a,(show_object)		;find object data structure
	sla a
	ld e,a
	ld d,0
	ld ix,object_addr_list
	add ix,de
	ld l,(ix)
	ld h,(ix+1)
	ld (object_addr_base),hl
	ld a,(hl)			
	ld (number_of_coords),a
	ld b,a			;number of coords
	ld de,7			
	add hl,de			;skip animation related stuff
	push hl
	pop ix			;source coords
	ld iy,rotated_coords

rot_loop	ld a,(rotate_angle1)	;calc x1
	add a,$40			
	ld (mult_index),a		;cos angle 1
	ld l,(ix)			;x	
	ld h,(ix+1)		;x
	ld (mult_write),hl
	ld hl,(mult_read)		;hl = cos (angle1) * x
	ld a,(rotate_angle1)		
	ld (mult_index),a		;sin angle 1
	ld e,(ix+2)		;y
	ld d,(ix+3)		;y
	ld (mult_write),de		;
	ld de,(mult_read)		;de = sin (angle1) * y
	add hl,de			;hl = x1
	push hl
	
	ld a,(rotate_angle2)	;calc x2
	add a,$40
	ld (mult_index),a		;cos angle2
	ld (mult_write),hl
	ld hl,(mult_read)
	ld e,(ix+4)		;z
	ld d,(ix+5)		;z
	ld a,(rotate_angle2)	;
	ld (mult_index),a		;sin angle2
	ld (mult_write),de	
	ld de,(mult_read)
	add hl,de			;hl = x2: rotated x coordinate
	ld (iy),l
	ld (iy+1),h
	
	ld a,(rotate_angle1)	;calc y1
	ld (mult_index),a		;sin angle1
	ld l,(ix)			;x	
	ld h,(ix+1)		;x
	ld (mult_write),hl
	ld hl,(mult_read)		;hl = sin (angle1) * x
	ld a,(rotate_angle1)
	add a,$40
	ld (mult_index),a		; cos angle 1
	ld e,(ix+2)		;y
	ld d,(ix+3)		;y
	ld (mult_write),de		;
	ld de,(mult_read)		;de = cos (angle1) * y
	xor a
	sbc hl,de			;hl = y1
	ld (temp_y1),hl
	
	ld a,(rotate_angle2)	;calc z1
	ld (mult_index),a		;sin angle 2
	pop hl			;x1
	ld (mult_write),hl
	ld hl,(mult_read)		;hl = sin (angle2) * x1
	ld a,(rotate_angle2)
	add a,$40
	ld (mult_index),a		;cos angle2
	ld e,(ix+4)		;z
	ld d,(ix+5)		;z
	ld (mult_write),de		
	ld de,(mult_read)		;de = cos (angle2) * z
	xor a
	sbc hl,de			;hl = z1
	push hl
	
	ld a,(rotate_angle3)	;calc y2
	ld (mult_index),a		;sin angle 2
	ld (mult_write),hl		;z1
	ld de,(mult_read)		;de = sin (angle2) * z1
	ld a,(rotate_angle3)
	add a,$40
	ld (mult_index),a		;cos angle 3
	ld hl,(temp_y1)		;y1
	ld (mult_write),hl		
	ld hl,(mult_read)		;hl = cos (angle3) * y1
	add hl,de			;hl = y2: rotated y coordinate
	ld (iy+2),l
	ld (iy+3),h

	ld a,(rotate_angle3)	;calc z2
	ld (mult_index),a		;sin angle3
	ld hl,(temp_y1)		;y1
	ld (mult_write),hl
	ld hl,(mult_read)		;hl = sin (angle3) * y1
	ld a,(rotate_angle3)
	add a,$40
	ld (mult_index),a		;cos angle3
	pop de			;z1
	ld (mult_write),de		
	ld de,(mult_read)		;de = cos (angle3) * z1
	xor a
	sbc hl,de			;hl = z2: rotated z coordinate
	ld (iy+4),l
	ld (iy+5),h

;	ld a,(ix+6)		;ignore point colour entry
;	ld (iy+6),a		;
	
	ld de,8
	add ix,de
	add iy,de
	
	dec b
	jp nz,rot_loop
	ret
	
;-------------------------------------------------------------------------------------------------

scale_3d_coordinates

	xor a			;scale x and y by z to give perspective effect
	ld (mult_index),a	
	ld ix,rotated_coords
	ld a,(number_of_coords)
	ld b,a

sca_loop	ld l,(ix+4)		;z lo 
	ld h,(ix+5)		;z hi
	ld de,(zoom)		
	add hl,de
	add hl,hl
	add hl,hl
	add hl,hl
	ld (mult_table),hl		;put in scaling factor
	
	ld l,(ix)			;x 
	ld h,(ix+1)		;x
	ld (mult_write),hl
	ld hl,(mult_read)
	ld (ix),l			;scaled x
	ld (ix+1),h		;scaled x
	
	ld l,(ix+2)		;y
	ld h,(ix+3)		;y
	ld (mult_write),hl
	ld hl,(mult_read)
	ld (ix+2),l		;scaled y
	ld (ix+3),h		;scaled y
	
	ld de,8			;next coord group base index
	add ix,de
	djnz sca_loop		;loop till all done
	
	ld hl,0
	ld (mult_table),hl		;put sin 0 value back in mult table
	ret


;------------------------------------------------------------------------------------------------------
; Sort lines draw order based on average of the two Z coords of each line
;------------------------------------------------------------------------------------------------------

sort_lines

	ld de,(object_addr_base)	;find object data structure
	ld a,(de)			;number of coords
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl			;skip coord section
	add hl,de			;add base address
	ld bc,7			;skip first 7 bytes too
	add hl,bc			
	ld (join_list_addr_base),hl
	ld b,h
	ld c,l			;bc = join_list base address
	inc de
	ld a,(de)			;number of lines
	
	exx
	ld (number_of_lines),a
	ld b,a			;number of items to put in sort table (lines)
	ld c,0			;line index count
	ld h,sort_range_list/256
					
zsort_lp	exx
	ld ix,rotated_coords
	ld a,(bc)			; coord select for point A
	inc bc
	ld l,a
	xor a 
	ld h,a
	add hl,hl
	add hl,hl
	add hl,hl
	ex de,hl
	add ix,de
	
	ld iy,rotated_coords
	ld a,(bc)			; coord select for point B
	inc bc	
	ld l,a
	xor a 
	ld h,a
	add hl,hl
	add hl,hl
	add hl,hl
	ex de,hl
	add iy,de
	
	ld l,(ix+4)		; z coord A 
	ld h,(ix+5)
	ld e,(iy+4)		; z coord B
	ld d,(iy+5)
	add hl,de			; add
	sra h
	rr l			; divide by 2
	inc h			; add 256
	sra h
	rr l			; divide by 2 again so average in range 0 to 255
	ld a,l			
	exx	
	
	ld l,a			;
	ld a,(hl)			; get previous offset to link list
	ld (hl),c			; put item number in range list (index = its magniture)
	inc h			; switch to link list		
	ld l,c			; index in link list = item number
	ld (hl),a			; insert old value from range list into link list
	dec h			; switch to index list
	inc c			; next item
	
	djnz zsort_lp		;loop until all items entered into buffer
	ret
	

;------------------------------------------------------------------------------------------------------
; Line draw code V1.02
;------------------------------------------------------------------------------------------------------

line_draw_setup

; Call once before any line draw operations to create a look up table for video y line address offsets
; that corrects for the coordinate system. IE: Centres the origin (0,0) midscreen, with negetive y below.
; The Y offset look up table values are actually 0.5 * the required value to allow for addresses > $10000


	ld hl,linedraw_constants		; copy the video offset constants to the 
	ld de,linedraw_lut0			; line draw hardware lookup table
	ld bc,16
	ldir
	
	ld ix,y_offset_addr_list		; positives y max -> 0	
	ld iy,y_offset_addr_list+256		 	
	ld hl,0+((window_height/2)-1)*(window_width/2) 	
	ld de,window_width/4
	add hl,de				 	
	ld de,window_width/2		 	
	ld b,window_height/2
delistlp1	ld (ix),l
	ld (iy),h
	xor a
	sbc hl,de
	inc ix
	inc iy
	djnz delistlp1
	
	ld ix,y_offset_addr_list+255		;negetives -1 -> y min	
	ld iy,y_offset_addr_list+511		 	
	ld hl,0+(window_height/2)*(window_width/2) 	
	ld de,window_width/4
	add hl,de	
	ld de,window_width/2
	ld b,window_height/2
delistlp2	ld (ix),l
	ld (iy),h
	xor a
	add hl,de
	dec ix
	dec iy
	djnz delistlp2
	ret
	
;---------------------------------------------------------------------------------------------
; Draws lines by reading the "join list" entries from the z-order buffer to connect coordinates
; Saves register values for erase routine to save recalculating everything
; Warning: Modifies Stack Pointer on entry and exit - be careful with IRQs etc!
;---------------------------------------------------------------------------------------------

draw_lines_in_z_order


ld_wait	ld a,(vreg_read)		; ensure any previous line draw / blit op is complete
	and $10			; at start (as an odd number of line draws will recommence
	jr nz,ld_wait		; with the same register set)

	ld (original_sp),sp
	ld de,lines_drawn
	ld hl,0
	ld sp,erase_list_a		; select coord set based on double-buffer state
	ld a,(buffer)
	or a
	jr z,buffz
	inc de
	ld hl,half_vbuffer_size
	ld sp,erase_list_b
buffz	ld (double_buff_offset),hl
	ld a,(number_of_lines)
	ld (de),a			; record the number of lines drawn on this video buffer


	ld b,256			; z sort range
	ld l,0			; start magnitude index
	ld h,sort_range_list/256	; MSB of range list addr
	inc h			; adjust for first pass

scanlist	dec h			; switch to range list
	ld a,$ff			; $ff = null entry value
scan_lp	cp (hl)			; check for an entry of 'l' magnitude
	jr nz,found		; if its not zero there are items with this weight
	inc l			; next buffer index
	djnz scan_lp		; loop until entire range checked
	jp alldone

found	ld c,l			; found an entry at this magnitude - save range index in c
	ld a,(hl)			; a = item number from scanlist
	ld (hl),255		; reset range list entry for next frame
	ld e,a			; store item number in e
	inc h			; switch to link list
	
mag_lp	ld a,e			; A = join_up list entry
	exx			; Swap register sets for actual line draw section

	
	ld ix,rotated_coords	; Get coords for line from the join-list entry index just found
	sla a
	ld l,a
	ld h,0
	ld bc,(join_list_addr_base)
	add hl,bc
	ld a,(hl)			; coord select for point A
	inc hl
	ld e,(hl)			; coord select for point B

	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	ex de,hl
	add ix,de
	
	ld iy,rotated_coords
	xor a
	ld h,a			
	add hl,hl
	add hl,hl
	add hl,hl
	ex de,hl
	add iy,de
	
	ld c,a			; reset the octant code / address MSB 
	ld l,(ix+2)		; y0 LSB
	ld h,y_offset_addr_list/256	; hl = index in line offset list
	ld e,(hl)			; e = addr/2 lsb
	inc h
	ld d,(hl)			; d = addr/2 msb
	ex de,hl			; hl = line offset/2
	ld de,(double_buff_offset)	; add start address of video buffer to draw on
	add hl,de
	add hl,hl			; double the line offset
	rr c			; put carry flag into bit 7 of octant code
	ld e,(ix+0)			
	ld d,(ix+1)		; de = x0
	add hl,de			; hl = video start address



ld_wait2	ld a,(vreg_read)		; check linedraw system status before altering registers
	and $10			; 
	jr nz,ld_wait2		; 



	ld (linedraw_reg2),hl	; Hardware line draw constant: Start Address
	push hl			; Store on stack for erase

	ld l,(iy+0)			
	ld h,(iy+1)		; hl = x1
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
	
xdeltapos	inc hl
	ld (delta_x),hl		; stash delta_x
	ld e,(ix+2)		
	ld d,(ix+3)		; de = y0
	ld l,(iy+2)
	ld h,(iy+3)		; hl = y1
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

ydeltapos	inc hl
	ld (delta_y),hl		; stash delta_y
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
	push hl			; Store on stack for erase
	ld hl,(delta_x)
	add hl,hl
	ld (linedraw_reg1),hl	; Hardware Linedraw Constant: 2 x delta_x	
	push hl			; Store on stack for erase
	set 6,c			; update octant settings
	ld de,(delta_y)		; de = line length
	jp line_len
	
horiz_seg	add hl,hl
	ld (linedraw_reg0),hl	; Hardware Linedraw Constant: 2 x (delta_y - delta_x)
	push hl			; Store on stack for erase

	ld hl,(delta_y)
	add hl,hl
	ld (linedraw_reg1),hl	; Hardware Linedraw Constant: 2 x delta_y
	push hl			; Store on stack for erase

line_len	ld a,d			; de = line length (assumes length < $0200, as it should be)
	or c			; OR in the octant / addr MSB bits
	ld d,a			; DE = composite of MSB,octant code and line length

	exx
	ld a,c
	exx
	rrca
	rrca
	rrca
	rrca
	and $f
	add a,$a0			; compute line colour
	ld hl,vreg_read
	
ld_wait1	bit 4,(hl)		; ensure any previous line draw / blit op is complete
	jr nz,ld_wait1		; before restarting line draw operation
	
	ld (linedraw_colour),a
	ld (linedraw_reg3),de	; line length, octant code, y address MSB & Start line draw.
	push de			; Store on stack for erase


	exx 			; switch back to z-order buffer scan registers
	ld l,e			; l = item number
	ld e,(hl)			; e = next item number
	ld a,255				
	ld (hl),a			; reset for next frame
	cp e			; any more in chain? (non $FF value)
	jp nz,mag_lp		; loop until all items of this magnitude are read

	ld l,c			; retrieve range count value from c
	inc l			; next index in sort buffer
	dec b
	jp nz,scanlist		; loop until all indices checked

alldone	ld sp,(original_sp)
	ret
	
	
	
;-------------------------------------------------------------------------------------------------------------------

erase_lines

; Erases previously drawn lines by using the register values previously used by the
; line draw routine (on the same buffer).

erase_colour equ 0

	ld de,lines_drawn
	ld hl,erase_list_a-1	; select erase set based on double-buffer state
	ld a,(buffer)
	or a
	jr z,le_wait1
	inc de
	ld hl,erase_list_b-1
	
le_wait1	ld a,(vreg_read)		; ensure any previous line draw / blit op is complete at start 
	and $10			
	jr nz,le_wait1

	ld a,erase_colour
	ld (linedraw_colour),a

	ld a,(de)			;get number of lines to erase
	ld b,a
el_loop	ld d,(hl)
	dec hl
	ld e,(hl)
	dec hl
	ld (linedraw_reg2),de
	ld d,(hl)
	dec hl
	ld e,(hl)
	dec hl
	ld (linedraw_reg0),de
	ld d,(hl)
	dec hl
	ld e,(hl)
	dec hl
	ld (linedraw_reg1),de
	ld d,(hl)
	dec hl
	ld e,(hl)
	dec hl
le_wait2	ld a,(vreg_read)			; ensure any previous line draw / blit op is complete
	and $10				; at start (as an odd number of line draws will recommence
	jr nz,le_wait2			; with the same register set)
	ld (linedraw_reg3),de
	dec b
	ret z
	
	ld d,(hl)
	dec hl
	ld e,(hl)
	dec hl
	ld (linedraw_reg6),de
	ld d,(hl)
	dec hl
	ld e,(hl)
	dec hl
	ld (linedraw_reg4),de
	ld d,(hl)
	dec hl
	ld e,(hl)
	dec hl
	ld (linedraw_reg5),de
	ld d,(hl)
	dec hl
	ld e,(hl)
	dec hl
le_wait3	ld a,(vreg_read)			; ensure any previous line draw / blit op is complete
	and $10				; at start (as an odd number of line draws will recommence
	jr nz,le_wait3			; with the same register set)
	ld (linedraw_reg7),de
	
	djnz el_loop
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

		
;---------------------------------------------------------------------------------------------------------

setup_star_sprites

	ld a,%10000000		;upload star sprites to sprite RAM
	out (sys_mem_select),a
	ld a,%10000000
	ld (vreg_vidpage),a		;sprite bank 0
	ld hl,star_defs
	ld de,$1000
	ld bc,256*8
	ldir
	
	ld a,%10000001
	ld (vreg_vidpage),a		;sprite bank 0
	ld hl,$1000
	ld bc,$1000
bsplp	ld (hl),16
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,bsplp
	ld a,0
	out (sys_mem_select),a
	
	ld ix,spr_registers+(112*4)	;position mask sprite
	ld (ix),$b8
	ld (ix+1),$e1
	ld (ix+2),$20
	ld (ix+3),$10
	
	
	
	ld ix,star_pos_list		;set random star x positions
	ld hl,0
	ld de,$f147
	ld a,31
	ld b,window_height/2
suspllp	ld (ix),h
	add hl,de
	add a,h
	inc a
	rrca 
	xor b
	sub e
	ld h,a
	inc ix
	inc ix
	djnz suspllp
	
	
	ld ix,spr_registers		;set Y and Def sprite registers
	ld b,window_height/2
	ld de,4
	ld c,32
	ld a,$7
istsplp	ld (ix+2),c		;y pos
	inc c
	inc c
	ld (ix+3),a		;def
	dec a
	and $7
	add ix,de
	djnz istsplp
	ret
	
;-------------------------------------------------------------------------------------------------------

setup_logo_sprites

	ld a,%10000000		;page in sprite ram @ $1000
	out (sys_mem_select),a
	ld a,%10000010
	ld (vreg_vidpage),a		;select sprite bank 2
	ld hl,logo_gfx
	ld de,$1000
	ld bc,256*12
	ldir
	ld a,0
	out (sys_mem_select),a
	
	ld ix,spr_registers+(113*4)	;position logo sprites
	ld a,$60
	ld c,$20
	ld b,6
	ld de,4
sulsplp	ld (ix),a			;x
	ld (ix+1),$21		;height/msbs
	ld (ix+2),$e7		;y
	ld (ix+3),c		;def
	add ix,de
	inc c
	inc c
	add a,16
	djnz sulsplp
	ret

;--------------------------------------------------------------------------------------------------------------


plot_stars

	ld ix,spr_registers
	ld iy,star_pos_list

	ld b,window_height/2		;update sprite reg x coords
starloop	ld h,(iy+1)
	ld l,(iy)
	ld de,128+16
	add hl,de
	ld (ix),l
	ld a,h
	or $10
	ld (ix+1),a
	inc iy
	inc iy
	ld de,4
	add ix,de
	djnz starloop
	ret
	

move_stars

	ld ix,star_pos_list
	ld b,window_height/16
ms_loop	ld de,$ffff
	ld h,(ix+1)
	ld l,(ix)
	add hl,de
	bit 7,h
	jr z,stok1
	ld hl,window_width
stok1	ld (ix+1),h
	ld (ix),l
	
	dec de
	ld h,(ix+3)
	ld l,(ix+2)
	add hl,de
	bit 7,h
	jr z,stok2
	ld hl,window_width
stok2	ld (ix+3),h
	ld (ix+2),l
	
	dec de
	ld h,(ix+5)
	ld l,(ix+4)
	add hl,de
	bit 7,h
	jr z,stok3
	ld hl,window_width
stok3	ld (ix+5),h
	ld (ix+4),l
	
	dec de
	ld h,(ix+7)
	ld l,(ix+6)
	add hl,de
	bit 7,h
	jr z,stok4
	ld hl,window_width
stok4	ld (ix+7),h
	ld (ix+6),l
	
	dec de
	ld h,(ix+9)
	ld l,(ix+8)
	add hl,de
	bit 7,h
	jr z,stok5
	ld hl,window_width
stok5	ld (ix+9),h
	ld (ix+8),l
	
	dec de
	ld h,(ix+11)
	ld l,(ix+10)
	add hl,de
	bit 7,h
	jr z,stok6
	ld hl,window_width
stok6	ld (ix+11),h
	ld (ix+10),l
	
	dec de
	ld h,(ix+13)
	ld l,(ix+12)
	add hl,de
	bit 7,h
	jr z,stok7
	ld hl,window_width
stok7	ld (ix+13),h
	ld (ix+12),l
	
	dec de
	ld h,(ix+15)
	ld l,(ix+14)
	add hl,de
	bit 7,h
	jr z,stok8
	ld hl,window_width
stok8	ld (ix+15),h
	ld (ix+14),l
	
	ld de,16
	add ix,de
	dec b
	jp nz,ms_loop
	ret	

;-------------------------------------------------------------------------------------------------

setup_sine_scroll

	xor a
	ld hl,ss_y_list
	ld de,0+((224/2)-1)*288
	ld bc,288
ss_iyl	ld (hl),e
	inc h
	ld (hl),d
	dec h
	inc l
	ex de,hl
	or a
	sbc hl,bc
	ex de,hl
	inc a
	cp 224/2
	jr nz,ss_iyl
	
	xor a
	ld hl,ss_y_list+255
	ld de,0+((224/2)*288)
	ld bc,288
ss_iy2	ld (hl),e
	inc h
	ld (hl),d
	dec h
	dec l
	ex de,hl
	add hl,bc
	ex de,hl
	inc a
	cp 224/2
	jr nz,ss_iy2
		
	
	ld hl,scrolling_message
	ld (scrolling_message_ptr),hl

	ld a,0
	ld (vreg_vidpage),a
	ld a,%00100000			;copy font to VRAM
	out (sys_mem_select),a
	ld hl,fontdata
	ld de,256*4
	ld bc,2048
	ldir
	ld a,0
	out (sys_mem_select),a
	ret


;-------------------------------------------------------------------------------------------------

sine_scroll

	ld a,254				;charset width - 1
	ld (blit_src_mod),a
	ld a,$1e				;lsb of screen width -1
	ld (blit_dst_mod),a
	ld a,$0f
	ld (blit_height),a
	ld a,(buffer)			;destination buffer
	rrca
	rrca
	rrca
	or %01000100
	ld (blit_misc),a			;ascending = 1, dest mod bit 8 = 1 

	ld hl,32
	ld (mult_write),hl			;amplitude of sine scroll

	ld bc,0				;X dest offset
	exx
	ld ix,blit_width
	ld a,(scroll_fine)			;offset into char
	ld c,a
	ld a,(sine_pos)
	ld b,a
	ld hl,(scrolling_message_ptr)

ss_chlp	ld a,(hl)				;ascii char
	sub 32				;less 32
	sla a				;multiplied by 8
	sla a
	sla a
	or c				;OR in the char slice (0-7)
	ld e,a
	ld d,0
	
ss_chsl	ld a,b
	ld (mult_index),a			;sine value
	exx
	ld hl,(mult_read)			;gives 111 to -112
	ld h,ss_y_list/256			;y line LUT
	ld e,(hl)
	inc h
	ld d,(hl)				;de = 0-223 * 288
	ex de,hl
	add hl,bc				;add screen slice 0-287
	
blitwait	ld a,(vreg_read)
	and $10
	jr nz,blitwait
	
	ld (blit_dst_loc),hl
	inc bc
	inc bc				;next screen slice
	exx
	ld (blit_src_loc),de
	ld (ix),1				;start blit

	inc b				;inc sine value
	inc b
	inc de				;inc blit source
	inc de
	inc c				;inc char slice
	inc c
	bit 3,c
	jp z,ss_chsl			;loop around in same source character

	ld c,0				;char slice index = 0
	inc hl				;next char
	
	exx	
	ld hl,280
	xor a
	sbc hl,bc
	exx
	jp nc,ss_chlp
	
	ld a,(sine_pos)
	sub 1
	ld (sine_pos),a
		
	ld a,(scroll_fine)			;adjustments for next frame
	add a,2
	ld (scroll_fine),a
	cp $8
	ret nz
	xor a
	ld (scroll_fine),a
	ld hl,(scrolling_message_ptr)
	inc hl
	ld (scrolling_message_ptr),hl
	ld de,288/8
	add hl,de
	ld a,(hl)
	or a
	ret nz
	ld hl,scrolling_message
	ld (scrolling_message_ptr),hl
	ret

;-------------------------------------------------------------------------------------------------------------

setup_music
	
	ld hl,$8000			;copy samples to sound sys accessible RAM
	exx
	ld de,end_of_samples
	ld hl,music_samples
suploadlp	ld a,%00000000
	out (sys_mem_select),a		;source bank
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	push bc
	ld a,%00000100
	out (sys_mem_select),a		;dest bank
	exx
	pop bc
	ld (hl),c
	inc hl
	ld (hl),b
	inc hl
	exx 
	push hl
	xor a
	sbc hl,de
	pop hl
	jr c,suploadlp

	ld a,%00000000
	out (sys_mem_select),a
		
	ld hl,0
	ld (force_sample_base),hl
	
	call init_tracker

	ret
	
;=============================================================================================================

		include	"3d_obj_cube.asm"
		include	"3d_obj_icosahedron.asm"
		include	"3d_obj_cube_star.asm"
		include	"3d_obj_frame.asm"
		include	"3d_obj_glass.asm"
		include	"3d_obj_tiefighter.asm"
		include 	"3d_obj_question.asm"


object_addr_list	dw cube_info		;0
		dw icosahedron_info		;1
		dw cubestar_info		;2
		dw frame_info		;3
		dw glass_info		;4
		dw tiefighter_info		;6
		dw question_info		;7

maxobject	 	equ 7

show_object	db 0

object_addr_base	dw 0
join_list_addr_base dw 0
number_of_coords	db 0
number_of_lines	db 0



rotated_coords	ds 128*8			;allow for 128 max

		org (($+256)/256)*256	;must be page aligned

y_offset_addr_list	ds 512,0			;always 256*2 no matter what y window size	


sort_range_list	ds 256,255		;must be page aligned
sort_link_list	ds 128,255		;must follow sort_range_list on next page

		
		ds 32+(128*8)		;allow for 128 lines max
erase_list_a	db 0

		ds 32+(128*8)		;allow for 128 lines max
erase_list_b	db 0

lines_drawn	db 0,0

original_sp	dw 0

double_buff_offset	dw 0

delta_x		dw 0
delta_y		dw 0
temp_y1		dw 0

rotate_angle1	db 0
rotate_angle2	db 0
rotate_angle3	db 0

zoom		dw 256
zoom_displacement	dw 32
hold_time		db 0

;-------------------------------------------------------------------------------------------------------

sin_table		incbin "sine_table.bin"

counter       	db 0

buffer		db 0

first_passes	db 0

;--------------------------------------------------------------------------------------------------------------

star_pos_list	ds window_height,0

star_defs		incbin "stars_sprites.bin"

;--------------------------------------------------------------------------------------------------------------
	
scroll_fine	db 0
	
scrolling_message_ptr

		dw scrolling_message
	
scrolling_message	db "                                        "
		
		DB "                         [[[[[[[[[[[[[[["
		DB " ITS ANOTHER V^Z]OP DEMO THINGY FROM PHIL[[[ THIS TIME"
		DB " WE HAVE _D WIRE FRAME GRAPHICS USING THE NEW HARDWARE LINE"
		DB " DRAW SYSTEM[[[[[        "
		DB " GREETINGS TO[[ JIM B[[ PETER MCQ[[ ERIK L[[ BRANDER[[ GREY[[ HUW W[[ STEVE G[[ RICHARD D[[ JOSEPH C[["
		DB " JIM F[A[[ DANIEL T[[ ALAN G[[ GEOFF O[[ PETER G[[ "
		DB " IVAN[[ RZH[[ VALEN[[ AND ANYONE IVE FORGOTTEN[["
		DB "             CODED BY PHIL RUSTON WWW[RETROLEUM[CO[UK O][[[[ BE SEEING YOU[[[["

		db "                                        ",0
		

sine_pos		db 0
	
		org (($+256)/256)*256	;page align
	
ss_y_list		ds 256,0		;lsbs
		ds 256,0		;msbs

fontdata		incbin "font_chunky.bin"

font_cols		incbin "font_12bit_palette.bin"

;--------------------------------------------------------------------------------------------------------------

logo_cols		incbin "logo_palette.bin"

logo_gfx		incbin "logo_sprites.bin"

;--------------------------------------------------------------------------------------------------------------

vector_cols	dw $001,$002,$003,$004,$005,$006,$007,$008,$009,$00a,$00b,$00c,$00d,$00e,$00f,$04f

;--------------------------------------------------------------------------------------------------------------

		include "Z80_Protracker_Player.asm"
		include "Amiga_audio_to_V5Z80P.asm"

	
		org (($+2)/2)*2		; word align

music_module	incbin "tune.pat"

music_samples	incbin "tune.sam"
end_of_samples	db 0

;---------------------------------------------------------------------------------------------------------------