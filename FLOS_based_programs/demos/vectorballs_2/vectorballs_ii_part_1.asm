;
;SOURCE TAB SIZE = 10
;
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

req_hw_version	equ $263

;-----------------------------------------------------------------------------------------------------------
; Check hardware revision is appropriate for code
;-----------------------------------------------------------------------------------------------------------

	call kjt_get_version
	ld hl,req_hw_version-1
	xor a
	sbc hl,de
	jr c,hw_vers_ok
	
	ld hl,bad_hw_vers
	call kjt_print_string
	xor a
	ret
	
bad_hw_vers

	db 11,"Program requires hardware version v263+",11,11,0
	
hw_vers_ok

;--------- Initialize --------------------------------------------------------------------

number_of_objects equ 5


	call clear_vram
	
	ld a,0			;unpack sprites
	ld hl,rgby_ballsprite
	ld de,sprite_base
	ld bc,endofrgbybs-rgby_ballsprite
	call unpack_sprites

	ld a,0			;unpack font
	ld (vreg_vidpage),a
	ld a,%01100000
	out (sys_mem_select),a	
	ld ix,font_tiles
	ld hl,font_tiles
	ld de,$8000
	ld bc,endoffont-font_tiles
	call unpack_rle
	ld a,%00100000
	out (sys_mem_select),a	

	ld hl,$400		;put empty blocks (>$07) in Playfield B
	ld b,0
clpf2	ld (hl),$80
	inc hl
	ld (hl),$80
	inc hl
	djnz clpf2
	ld a,%00000000
	out (sys_mem_select),a

	ld hl,sin_table		; upload sine table to math unit
	ld de,mult_table
	ld bc,$200
	ldir	

	ld hl,font_colours		;upload font colours
	ld de,palette+(224*2)
	ld bc,64
	ldir
	
	call relocate_music
	call make_patterns
	call setup_stars
	call make_fade_table
	call init_music
	
	ld a,1
	ld (vreg_sprctrl),a		; enable sprites
	ld a,0
	ld (vreg_rasthi),a		
	ld a,$2e			; 	
	ld (vreg_window),a		; 256 line display
	ld a,%00000100		; Switch to x window pos reg
	ld (vreg_rasthi),a		
	ld a,$6e			
	ld (vreg_window),a		; Window Width = 368 pixels (+16 masked by wideborder)
	ld a,%10000011
	ld (vreg_vidctrl),a		; DualPF, tilemap mode, show tile map a, using blockset 0,wideborder

	ld a,$00			; clear vertical scroll registers
	ld (vreg_yhws_bplcount),a
	ld a,$80
	ld (vreg_yhws_bplcount),a


;--------- Main Loop -----------------------------------------------------------------------------------------------


wvrtstart	ld a,(vreg_read)		;wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	ld a,(scroll_fine)		;update hardware scroll - Playfield B
	rrca
	rrca
	rrca
	rrca
	ld (vreg_xhws),a

;	ld hl,$00f
;	ld (palette),hl
	
	call update_sprites		;do first, so off screen
	
;	ld hl,$0ff
;	ld (palette),hl
	
	call erase_stars
	call move_stars
	call plot_stars
	call upload_palette
	call play_music
	
	call scrolling_message	;do high up, as it is not double buffered
		
;	ld hl,$f00
;	ld (palette),hl

	call rotate_coords
	
;	ld hl,$000
;	ld (palette),hl
	
	call scale_coords
	
;	ld hl,$ff0
;	ld (palette),hl
	
	call sort_coords
	
;	ld hl,$080
;	ld (palette),hl

	call make_sprite_reg_list
	call update_vars
	call ball_fade_swap
	
;	ld hl,$000
;	ld (palette),hl
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		;loop if ESC key not pressed
	xor a
	out (sys_audio_enable),a	;silence channels
	ld a,$ff			;and quit (restart OS)
	ret


;------------------------------------------------------------------------------

rotate_coords

	ld ix,source_coords
	ld a,(show_pattern)
	sla a
	ld d,a
	ld e,0
	add ix,de
	ld iy,rotated_coords
	ld a,(number_of_coords)
	ld b,a

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

	ld a,(ix+6)		;simply copy ball colour across to
	ld (iy+6),a		;rotated coord set
	
	ld de,8
	add ix,de
	add iy,de
	
	dec b
	jp nz,rot_loop
	ret
	
;-------------------------------------------------------------------------------------------------

scale_coords


	ld a,(x_offset_ang)
	add a,2
	ld (x_offset_ang),a
	ld (mult_index),a
	ld hl,192
	ld (mult_write),hl
	ld de,(mult_read)		;x offset

	ld a,(y_offset_ang)
	add a,1
	ld (y_offset_ang),a
	ld (mult_index),a
	ld hl,100
	ld (mult_write),hl
	ld bc,(mult_read)		;y offset
	
	ld a,(z_offset_ang)
	sub 1
	ld (z_offset_ang),a
	ld (mult_index),a
	ld hl,500			;max +/- z position
	ld (mult_write),hl
	ld hl,(mult_read)		;y offset
	ld (z_offset),hl
	exx
	
	xor a			;scale x and y by z to give perspective effect
	ld (mult_index),a	
	ld ix,rotated_coords
	ld iy,adjusted_z_coords
	ld a,(number_of_coords)
	ld b,a

sca_loop	ld l,(ix+4)		;z lo 
	ld h,(ix+5)		;z hi
	push hl
	inc h
	inc h			;add 512 to make all positive, centre of range = 512
	srl h
	rr l
	srl h
	rr l
	ld a,l			;store adjusted z / 4 (range 0-255) for sort routine 			
	ld (iy),a			;(dont need to take into account z-offset in sort)
	
	pop hl
	ld de,(z_offset)		;add on z-offset
	add hl,de
	ld de,800			;make range all psitive
	add hl,de
	add hl,hl
	add hl,hl
	ld de,2500		;add on distance from vanishing point
	add hl,de			
	ld (ix+4),l		;replace adjusted z for sprite definition lookup
	ld (ix+5),h		;
	ld (mult_table),hl		;put in scaling factor
	
	exx
	ld l,(ix)			;x 
	ld h,(ix+1)		;x
	add hl,de
	ld (mult_write),hl
	exx
	ld hl,(mult_read)
	ld (ix),l			;scaled x
	ld (ix+1),h		;scaled x
	
	exx
	ld l,(ix+2)		;y
	ld h,(ix+3)		;y
	add hl,bc
	ld (mult_write),hl
	exx
	ld hl,(mult_read)
	ld (ix+2),l		;scaled y
	ld (ix+3),h		;scaled y
	
	inc iy			;next adjusted z index
	ld de,8			;next coord group base index
	add ix,de
	djnz sca_loop		;loop till all done
	
	ld hl,0
	ld (mult_table),hl		;put sin 0 value back in mult table
	ret
	
;--------------------------------------------------------------------------------------------------

sort_coords

	ld de,adjusted_z_coords	;unsorted list
	ld a,(number_of_coords)	;number of coords to sort
	ld b,a
	ld c,0			;counts 0 to items
	ld h,sort_range_list/256	;MSB of address
fsl_loop	ld a,(de)			;a = item's z coord
;	srl a			;scale to fit a 0-127 range 
	ld l,a			;l = magnitude of entry
	ld a,(hl)			;get previous offset to link list
	ld (hl),c			;put item number in range list (index = its magniture)
	inc h			;switch to link list		
	ld l,c			;index in link list = item number
	ld (hl),a			;insert old value from range list into link list
	dec h			;switch to index list
	inc c			;next item
	inc de			;move to next item to sort
	djnz fsl_loop		;loop until all items entered into buffer
	ret

;--------------------------------------------------------------------------------------------------

update_sprites
	
	ld hl,temp_spr_regs
	ld de,spr_registers
	ld bc,512
	ldir
	ret
	
	
make_sprite_reg_list
		
	ld ix,temp_spr_regs		
	ld b,256			;buffer range
	ld l,0			;start magnitude index
	ld h,sort_range_list/256	;MSB of range list addr
	inc h			;adjust for first pass

scanlist	dec h			;switch to range list
	ld a,$ff			;$ff = null entry value
scan_lp	cp (hl)			;check for an entry of 'l' magnitude
	jr nz,found		;if its not zero there are items with this weight
	inc l			;next buffer index
	djnz scan_lp		;loop until entire range checked
	jp alldone

found	ld c,l			;save range index in c
	ld a,(hl)			;a = item number from scanlist
	ld (hl),255		;reset range list entry for next frame
	ld e,a			;store item number in e
	inc h			;switch to link list
	
mag_lp	ld a,e
	exx
	ld iy,rotated_coords	;coord list 
	ld d,0
	add a,a			;a << 1 (assume no more than 63 items)
	add a,a			;a << 1
	add a,a			;a << 1
	rl d
	ld e,a
	add iy,de			;iy = base for this item's coord group

	ld a,(iy+5)		;z value
	sra a
	cp 8
	jr nc,twosprite		;0-7 = single sprite definition required
	add a,(iy+6)		;add colour offset to def
	ld (ix+3),a		;definition byte
	ld l,(iy)			
	ld h,(iy+1)		;hl = x coordinate
	ld de,264			
	add hl,de			;add centre screen x offset			
	ld (ix),l			;put in sprite x coord LSB
	ld a,h			;save x coord MSB
	ld l,(iy+2)		
	ld h,(iy+3)		;hl = y coordinate
	ld de,144
	add hl,de			;add centre screen y offset 
	ld (ix+2),l		;put in sprite left half y coord LSB
	ld l,a
	ld a,h
	and 1
	rlca			;shift y MSB left
	or l			;OR in X MSB
	or $10			;OR in Height
	ld (ix+1),a		;put in sprite control bits
	ld de,4
	jr nxtspr
	
twosprite	cp 16			;8-15 = two sprites required
	jr c,bfmaxok
	ld a,15
bfmaxok	sub 8
	sla a
	add a,8
	add a,(iy+6)		;add on ball colour
	ld (ix+3),a		;put in sprite left half definition number (temp)
	add a,16			
	ld (ix+7),a		;put in sprite right half definition number (temp)
	ld l,(iy)			
	ld h,(iy+1)		;hl = x coordinate
	ld de,256			
	add hl,de			;add centre screen x offset			
	ld (ix),l			;put in sprite left half x coord LSB
	ld a,h			;save left side x coord MSB
	ld de,16			;right side sprite is 16 pixels ->
	add hl,de
	ld (ix+4),l		;put in sprite right half x coord LSB
	ld c,h			;save right side x coord MSB
	ld l,(iy+2)		
	ld h,(iy+3)		;hl = y coordinate
	ld de,136
	add hl,de			;add centre screen y offset 
	ld (ix+2),l		;put in sprite left half y coord LSB
	ld (ix+6),l		;put in sprite right half y coord LSB
	ld l,a
	ld a,h
	and 1
	rlca			;shift y MSB left
	or l			;OR in X MSB
	or $20			;OR in Height
	ld (ix+1),a		;put in sprite control bits for left side
	or c
	ld (ix+5),a		;put in sprite control bits for right side 
	ld de,8
nxtspr	add ix,de			;next sprite reg location

	exx 
	ld l,e			;l = item number
	ld e,(hl)			;e = next item number
	ld a,255				
	ld (hl),a			;reset for next frame
	cp e			;any more in chain? (non $FF value)
	jp nz,mag_lp		;loop until all items of this magnitude are read

	ld l,c			;retrieve range count value from c
	inc l			;next index in sort buffer
	dec b
	jp nz,scanlist		;loop until all indices checked

alldone	push ix			;zero all unused sprite registers
	pop de
	ld hl,temp_spr_regs+$200
	xor a
	sbc hl,de
	srl h
	rr l
	srl h
	rr l
	ld b,l
	push ix
	pop hl
clssrlp	ld (hl),a
	inc hl
	ld (hl),a
	inc hl
	inc hl
	inc hl
	djnz clssrlp
	ret

;----------------------------------------------------------------------------------------------------------

update_vars

	ld a,(rotate_angle1)
	inc a
	ld (rotate_angle1),a
	
	ld a,(rotate_angle2)
	dec a
	ld (rotate_angle2),a
	
	ld a,(rotate_angle3)
	inc a
	inc a
	ld (rotate_angle3),a
	
	ret
	

;----------------------------------------------------------------------------------------

number_of_stars equ 16


erase_stars
	
	ld a,0
	ld (vreg_vidpage),a

	di
	ld a,%00100000
	out (sys_mem_select),a	;all writes to VRAM
	
	ld de,star_x_positions
	ld ix,star_y_positions
	ld b,8
	ld c,0
enxtstar	ld a,(de)
	rrca
	rrca
	rrca
	rrca
	and $f
	or $10
	ld h,a
	ld a,(de)
	and $f
	or (ix)
	ld l,a
	ld (hl),c
	inc de
	inc ix
	djnz enxtstar
	
	ld b,8
	ld c,0
enxtstar2	ld a,(de)
	rrca
	rrca
	rrca
	rrca
	and $f
	or $20
	ld h,a
	ld a,(de)
	and $f
	or (ix)
	ld l,a
	ld (hl),c
	inc de
	inc ix
	djnz enxtstar2
	
	ld a,%00000000		;normal writes
	out (sys_mem_select),a
	ei
	ret
	

move_stars


	ld hl,star_x_positions
	
	ld a,(hl)
	sub 8
	ld (hl),a
	inc hl
	ld a,(hl)
	sub 7
	ld (hl),a
	inc hl
	ld a,(hl)
	sub 6
	ld (hl),a
	inc hl
	ld a,(hl)
	sub 5
	ld (hl),a
	inc hl
	ld a,(hl)
	sub 4
	ld (hl),a
	inc hl
	ld a,(hl)
	sub 3
	ld (hl),a
	inc hl
	ld a,(hl)
	sub 2
	ld (hl),a
	inc hl
	ld a,(hl)
	sub 1
	ld (hl),a
	inc hl
	ld a,(hl)
	sub 7
	ld (hl),a
	inc hl
	ld a,(hl)
	sub 6
	ld (hl),a
	inc hl
	ld a,(hl)
	sub 5
	ld (hl),a
	inc hl
	ld a,(hl)
	sub 4
	ld (hl),a
	inc hl
	ld a,(hl)
	sub 3
	ld (hl),a
	inc hl
	ld a,(hl)
	sub 2
	ld (hl),a
	inc hl
	ld a,(hl)
	sub 1
	ld (hl),a
	inc hl

;	ld a,(hl)
;	sub 1
;	ld (hl),a	
	ret


plot_stars
	
	ld a,0
	ld (vreg_vidpage),a
	
	di
	ld a,%00100000
	out (sys_mem_select),a	;all writes to VRAM
	
	ld de,star_x_positions
	ld ix,star_y_positions
	ld b,8
	ld c,240			;star colour
nxtstar	ld a,(de)
	rrca
	rrca
	rrca
	rrca
	and $f
	or $10
	ld h,a
	ld a,(de)
	and $f
	or (ix)
	ld l,a
	ld (hl),c
	inc c
	inc c
	inc de
	inc ix
	djnz nxtstar
	
	ld b,8
	ld c,240			;star colour
nxtstar2	ld a,(de)
	rrca
	rrca
	rrca
	rrca
	and $f
	or $20
	ld h,a
	ld a,(de)
	and $f
	or (ix)
	ld l,a
	ld (hl),c
	inc c
	inc c
	inc de
	inc ix
	djnz nxtstar2
	
	ld a,%00000000		;normal writes
	out (sys_mem_select),a
	ei
	ret
		
star_x_positions

	ds number_of_stars,0

star_y_positions
	
	db $0,$20,$40,$60,$80,$a0,$c0,$e0
	db $0,$20,$40,$60,$80,$a0,$c0,$e0

;--------------------------------------------------------------------------------------------

setup_stars

	ld ix,star_x_positions	;set random star x positions
	ld hl,0
	ld de,$f147
	ld a,31
	ld b,number_of_stars	;number of stars
suspllp	ld (ix),h
	add hl,de
	add a,h
	inc a
	rrca 
	xor b
	sub e
	ld h,a
	inc ix
	djnz suspllp
	
	
	ld a,0
	ld (vreg_vidpage),a

	ld a,%00100000
	out (sys_mem_select),a	;all writes to VRAM

	ld de,rand_list		;set up star tiles
	ld hl,0			;tilemap a
	ld c,8
stilelp2	ld a,(de)
	ld b,32
stilelp	or $10
	and $1f
	ld (hl),a
	inc hl
	inc a
	djnz stilelp
	ld a,(de)
	ld b,32
stilelpb	or $20
	and $2f
	ld (hl),a
	inc hl
	inc a
	djnz stilelpb
	inc de
	dec c
	jr nz,stilelp2
	
	ld a,%00000000		;normal writes
	out (sys_mem_select),a
	
	ret
	
rand_list

	db $0,$5,$b,$4, $8,$c,$3,$6, $1,$e,$3,$a, $2,$7,$9,$f
	db $5,$c,$1,$7, $2,$9,$0,$d, $8,$4,$b,$f, $7,$a,$6,$3
			
;---------------------------------------------------------------------------------------

scrolling_message


	di		
	ld a,%00100000
	out (sys_mem_select),a	;all writes to vram
	ld ix,$400+(32*14)
	ld hl,(scrolltext_addr)	;draw in lines of characters to tilemap
	ld b,24
scrtlp	ld a,(hl)
	add a,128-32			;adjust ascii value to font tile
	ld (ix),a
	add a,59
	ld (ix+32),a		;reflected tile below
	inc hl
	inc ix
	djnz scrtlp
	ld a,%00000000		;normal writes
	out (sys_mem_select),a
	
	
	ld a,(scroll_fine)		;advance pixel scroll position
	sub 4
	jr nc,sf_ok
	add a,16
	ld hl,(scrolltext_addr)
	inc hl
	ld (scrolltext_addr),hl
sf_ok	ld (scroll_fine),a
	ld ix,(scrolltext_addr)
	ld a,(ix+24)
	or a
	jr nz,neom
	ld hl,scroll_text
	ld (scrolltext_addr),hl
neom	ret	

;----------------------------------------------------------------------------------------

clear_vram

	call kjt_page_in_video
	ld e,0			; clear entire video memory 
	ld a,e
cvrlp3	ld (vreg_vidpage),a
	ld c,$20
	ld hl,$2000
	xor a
cvrlp2	ld b,0
cvrlp1	ld (hl),a
	inc l
	djnz cvrlp1
	inc h
	dec c
	jr nz,cvrlp2
	inc e
	ld a,e
	cp $10
	jr nz,cvrlp3
	call kjt_page_out_video
	ret
	
;------------------------------------------------------------------------------------------

ball_fade_swap

	ld a,(timer)
	inc a
	ld (timer),a
	cp $20
	jr nc,nofade_in
	ld a,(fade_level)
	or a
	jr z,go_fade
	dec a
	ld (fade_level),a
	jr go_fade
	
nofade_in	cp $e0
	jr c,go_fade
	ld a,(fade_level)
	inc a
	cp $1f
	jr c,fadelok
	ld a,$1f
fadelok	ld (fade_level),a
	

go_fade	ld a,(timer)
	or a
	ret nz
	ld a,(show_pattern)
	inc a
	cp number_of_objects
	jr nz,pnok
	xor a
pnok	ld (show_pattern),a
	ld e,a
	ld d,0
	ld hl,ball_count_list
	add hl,de
	ld a,(hl)
	ld (number_of_coords),a
	ret

;------------------------------------------------------------------------------------------

upload_palette

	ld a,%00000011		
	out (sys_mem_select),a
	ld a,(fade_level)
	sra a
	add a,$80
	ld h,a
	ld l,0
	ld de,palette
	ld bc,256
	ldir
	ld a,0			
	out (sys_mem_select),a
	ret
	
		
;---------------------------------------------------------------------------------------
; Unpacks V5Z80P_RLE packed data to sprite RAM - Phil_V5Z80P @ Retroleum.co.uk 2008
; Keeps destination within $1000-$1fff and updates vreg_vidpage as required
;----------------------------------------------------------------------------------------

unpack_sprites

;set  A = initial sprite bank (0-15)
;set HL = source address of packed file
;set DE = destination address for unpacked data (within sprite page $1000-$1fff)
;set BC = length of packed file

	dec bc			;less 1 to skip match token
	push hl
	pop ix
	exx
	ld b,a
	exx
	or $80
	ld (vreg_vidpage),a		; select initial sprite bank

	in a,(sys_mem_select)
	and $1f
	or $80
	out (sys_mem_select),a	; page in sprite memory
	
	inc hl
unp_gtok	ld a,(ix)			; get token byte
unp_next	bit 5,d			; test for next sprite page
	jp z,nchsb1
	exx
	inc b
	ld a,b
	or $80
	ld (vreg_vidpage),a
	exx
	ld d,$10
	ld a,(ix)
nchsb1	cp (hl)			; is byte at source location same as token?
	jr z,unp_brun		; if it is, there's a byte run to expand
	ldi			; if not, simply copy this byte to destination
	jp pe,unp_next		; last byte of source?
	jr packend
	
unp_brun	push bc			; stash B register
	inc hl		
	ld a,(hl)			; get byte value
	inc hl		
	ld b,(hl)			; get run length
	inc hl
	
unp_rllp	ld (de),a			; write byte value, byte run length
	inc de		
	bit 5,d			; test for next sprite page
	jp z,nchsb2
	ld c,a
	exx
	inc b
	ld a,b
	or $80
	ld (vreg_vidpage),a
	exx
	ld d,$10
	ld a,c
nchsb2	djnz unp_rllp
	
	pop bc	
	dec bc			; last byte of source?
	dec bc
	dec bc
	ld a,b
	or c
	jp nz,unp_gtok

packend	in a,(sys_mem_select)	;page out sprite memory
	and $7f
	out (sys_mem_select),a	
	ret


;---------------------------------------------------------------------------------------
; General Unpack V5Z80P_RLE packed files - Phil_V5Z80P @ Retroleum.co.uk 2008
; V1.01 - Note: Cannot unpack across upper RAM pages
;----------------------------------------------------------------------------------------

unpack_rle

;set IX = source address of packed file
;set HL = source address of packed file
;set DE = destination address for unpacked data
;set BC = length of packed file

	dec bc		; length less one (for token byte)
	inc hl
gunp_gtok	ld a,(ix)		; get token byte
gunp_next	cp (hl)		; is byte at source location same as token?
	jr z,gunp_brun	; if it is, there's a byte run to expand
	ldi		; if not, simply copy this byte to destination
	jp pe,gunp_next	; last byte of source?
	ret
	
gunp_brun	push bc		; stash B register
	inc hl		
	ld a,(hl)		; get byte value
	inc hl		
	ld b,(hl)		; get run length
	inc hl
	
gunp_rllp	ld (de),a		; write byte value, byte run length
	inc de		
	djnz gunp_rllp
	
	pop bc	
	dec bc		; last byte of source?
	dec bc
	dec bc
	ld a,b
	or c
	jp nz,gunp_gtok
	ret

;-------------------------------------------------------------------------------------------------------------

make_fade_table

	ld a,%00000011		; make faded copies of ball palette
	out (sys_mem_select),a
	ld iy,$8000
	ld a,0
	ld (mult_index),a
	ld c,16
nxtfset	ld ix,ball_palette
	ld a,c
	rlca
	rlca
	ld h,a
	ld l,0
	ld (mult_table),hl
	ld b,128	
mfpallp	ld a,(ix)
	and $f
	ld l,a
	ld h,0
	ld (mult_write),hl
	ld a,(mult_read)
	ld d,a
	ld l,(ix)
	ld (mult_write),hl
	ld a,(mult_read)
	and $f0
	or d
	ld (iy),a
	ld l,(ix+1)
	ld (mult_write),hl
	ld a,(mult_read)
	ld (iy+1),a
	inc ix
	inc ix
	inc iy
	inc iy
	djnz mfpallp
	dec c
	jr nz,nxtfset
	ld hl,0
	ld (mult_table),hl
	ld a,0
	out (sys_mem_select),a
	ret
	
;-------------------------------------------------------------------------------------------------------------

make_patterns

	ld iy,source_coords
	ld ix,afterburner
	call make_patt
	ld ix,circle_line
	call make_patt
	ld ix,line_cube
	call make_patt
	ld ix,face_cube
	call make_patt
	ld ix,globe
	call make_patt
	ret

make_patt	ld de,64			; convert 8 bit coords to 16 bit
	add ix,de
	ld b,64
exbp_loop	push bc
	ld b,0
	ld c,(ix-64)		; unscaled x coord
	bit 7,c
	jr z,hbz1
	dec b
hbz1	sla c
	rl b
	sla c
	rl b
	ld (iy),c			; x coord LSB
	ld (iy+1),b		; sign extended x coord MSB
	ld b,0
	ld c,(ix)			; unscaled y coord
	bit 7,c
	jr z,hbz2
	dec b
hbz2	sla c
	rl b
	sla c
	rl b
	ld (iy+2),c		; y coord LSB
	ld (iy+3),b		; sign extended y coord MSB
	ld b,0
	ld c,(ix+64)		; unscaled z coord
	bit 7,c
	jr z,hbz3
	dec b
hbz3	sla c
	rl b
	sla c
	rl b
	ld (iy+4),c		; z coord LSB
	ld (iy+5),b		; sign extended z coord MSB
	inc ix			; next source coord
	ld a,(ix+127)		; get ball colour
	ld (iy+6),a
	ld de,8
	add iy,de			; next dest coord addr
	pop bc
	djnz exbp_loop
	ret
	
;------------------------------------------------------------------------------------------

relocate_music

	ld hl,music_file		;shift music code and data to sample ram 
	ld de,$8000		;(via horribly inefficient upper bank switching)
	ld b,%00000001		;source bank
	ld c,%00000100		;dest bank
	exx
	ld bc,$9d00		;length of file to relocate
movelp	exx
	ld a,b
	out (sys_mem_select),a
	ld a,(hl)
	push af
	ld a,c
	out (sys_mem_select),a
	pop af
	ld (de),a
	inc hl
	inc de
	bit 7,h
	jr nz,sbankok
	ld h,$80
	inc b
sbankok	bit 7,d
	jr nz,dbankok
	ld d,$80
	inc c
dbankok	exx
	dec bc
	ld a,b
	or c
	jp nz,movelp
	ld a,0
	out (sys_mem_select),a
	ret

init_music

	ld a,%00000100
	out (sys_mem_select),a
	call $8000
	ld a,0
	out (sys_mem_select),a
	ret
	
play_music

	ld a,%00000100
	out (sys_mem_select),a
	call $8003
	ld a,0
	out (sys_mem_select),a
	ld hl,0
	ld (mult_table),hl		;restore sine 0 value of mult table
	ret
		
;------------------------------------------------------------------------------------------

timer		db 0
fade_level	db $1f
show_pattern	db 0

ball_palette	incbin "rgby_balls_palette.bin"
font_colours	incbin "reflected_font_palette.bin"

;------------------------------------------------------------------------------------------


		org (($+256)/256)*256	;page align

source_coords	ds 512*number_of_objects,0

rotated_coords	ds 512,0			;64 * 8
	
sort_range_list	ds 256,255

sort_link_list	ds 64,255

adjusted_z_coords	ds 64

sin_table		incbin "sin_table.bin"

rotate_angle1	db $00
rotate_angle2	db $17
rotate_angle3	db $c8

temp_y1		dw 0

number_of_coords	db 49

temp_spr_regs	ds 512,0

x_offset_ang	db 0
y_offset_ang 	db 85
z_offset_ang 	db 221

z_offset		dw 0

;------------------------------------------------------------------------------------------------

ball_count_list	db 49,39,56,48,49

afterburner	db $d0,$e0,$f0,$00,$10,$20,$30
		db $d0,$e0,$f0,$00,$10,$20,$30
		db $d0,$e0,$f0,$00,$10,$20,$30
		db $d0,$e0,$f0,$00,$10,$20,$30
		db $d0,$e0,$f0,$00,$10,$20,$30
		db $d0,$e0,$f0,$00,$10,$20,$30
		db $d0,$e0,$f0,$00,$10,$20,$30
		ds 15,0

		db $d0,$d0,$d0,$d0,$d0,$d0,$d0
		db $e0,$e0,$e0,$e0,$e0,$e0,$e0
		db $f0,$f0,$f0,$f0,$f0,$f0,$f0
		db $00,$00,$00,$00,$00,$00,$00
		db $10,$10,$10,$10,$10,$10,$10
		db $20,$20,$20,$20,$20,$20,$20
		db $30,$30,$30,$30,$30,$30,$30
		ds 15,0
		
		db $00,$00,$00,$00,$00,$00,$00	
		db $00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00
		ds 15,0
		
		db $50,$50,$50,$50,$50,$50,$50
		db $50,$78,$78,$78,$78,$78,$50
		db $50,$50,$78,$50,$78,$50,$50
		db $50,$50,$78,$50,$78,$50,$50
		db $50,$50,$78,$50,$78,$50,$50
		db $50,$78,$78,$78,$78,$78,$50
		db $50,$50,$50,$50,$50,$50,$50
		ds 15,0 



circle_line	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  
		db $00,$00,$38,$2a,$1c,$0e,$00,$f2,$e4,$d6,$c8,$38,$38,$38,$38,$38
		db $38,$c8,$c8,$c8,$c8,$c8,$c8,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

		db $00,$10,$1f,$2a,$2f,$2f,$2a,$1f,$10,$00,$f0,$e1,$d6,$d1,$d1,$d6
		db $e1,$f0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0e,$0e,$00,$f2
		db $f2,$00,$0e,$0e,$00,$f2,$f2,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

		db $30,$2d,$25,$18,$08,$f8,$e8,$db,$d3,$d0,$d3,$db,$e8,$f8,$08,$18
		db $25,$2d,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10,$08,$f8,$f0,$f8
		db $08,$10,$08,$f8,$f0,$f8,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$28,$28,$28,$28,$28,$28,$28,$28,$28,$50,$50,$50,$50,$50
		db $50,$50,$50,$50,$50,$50,$50,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00



		
line_cube		db $d8,$d8,$d8,$d8,$d8,$d8	;x	
		db $d8,$d8,$d8,$d8,$d8,$d8
		db $d8,$d8,$d8,$d8,$d8,$d8
		db $d8,$d8,$e8,$f8,$08,$18
		db $e8,$f8,$08,$18,$e8,$f8
		db $08,$18,$e8,$f8,$08,$18
		db $28,$28,$28,$28,$28,$28
		db $28,$28,$28,$28,$28,$28
		db $28,$28,$28,$28,$28,$28
		db $28,$28
		ds 8,0

		db $d8,$e8,$f8,$08,$18,$28	;y
		db $28,$28,$28,$28,$28,$18
		db $08,$f8,$e8,$d8,$d8,$d8
		db $d8,$d8,$d8,$d8,$d8,$d8
		db $28,$28,$28,$28,$d8,$d8
		db $d8,$d8,$28,$28,$28,$28
		db $d8,$e8,$f8,$08,$18,$28
		db $28,$28,$28,$28,$28,$18
		db $08,$f8,$e8,$d8,$d8,$d8
		db $d8,$d8
		ds 8,0

		db $d8,$d8,$d8,$d8,$d8,$d8	;z
		db $e8,$f8,$08,$18,$28,$28
		db $28,$28,$28,$28,$18,$08
		db $f8,$e8,$d8,$d8,$d8,$d8
		db $d8,$d8,$d8,$d8,$28,$28
		db $28,$28,$28,$28,$28,$28
		db $d8,$d8,$d8,$d8,$d8,$d8
		db $e8,$f8,$08,$18,$28,$28
		db $28,$28,$28,$28,$18,$08
		db $f8,$e8
		ds 8,0

		db $78,$50,$50,$50,$50,$78	;colours
		db $50,$50,$50,$50,$78,$50
		db $50,$50,$50,$78,$50,$50
		db $50,$50,$50,$50,$50,$50
		db $50,$50,$50,$50,$50,$50
		db $50,$50,$50,$50,$50,$50
		db $78,$50,$50,$50,$50,$78
		db $50,$50,$50,$50,$78,$50
		db $50,$50,$50,$78,$50,$50
		db $50,$50
		ds 8,0
		

		

face_cube		db $12,$00,$ee
		db $12,$00,$ee
		db $12,$00,$ee
		db $12,$00,$ee
		ds 12,$20
		ds 12,$e0
		db $12,$00,$ee
		db $12,$00,$ee
		db $12,$00,$ee
		db $12,$00,$ee
		ds 16,0
			
		db $1c,$1c,$1c
		db $0a,$0a,$0a
		db $f6,$f6,$f6
		db $e4,$e4,$e4
		db $1c,$1c,$1c
		db $0a,$0a,$0a
		db $f6,$f6,$f6
		db $e4,$e4,$e4
		db $1c,$1c,$1c
		db $0a,$0a,$0a
		db $f6,$f6,$f6
		db $e4,$e4,$e4
		db $1c,$1c,$1c
		db $0a,$0a,$0a
		db $f6,$f6,$f6
		db $e4,$e4,$e4
		ds 16,0
			
		ds 12,$e0
		db $ee,$00,$12
		db $ee,$00,$12
		db $ee,$00,$12
		db $ee,$00,$12 
		db $ee,$00,$12
		db $ee,$00,$12
		db $ee,$00,$12
		db $ee,$00,$12
		ds 12,$20
		ds 16,0
		
		ds 12,$00
		ds 12,$28
		ds 12,$50
		ds 12,$78
		ds 16,0
	



globe		incbin "globe_sin_table.bin"		
		incbin "globe_sin_table.bin"
		ds 16,0
		ds 16,0
		
		incbin "globe_cos_table.bin"
		ds 16,0
		incbin "globe_sin_table.bin"
		ds 16,0
		
		ds 16,0
		incbin "globe_cos_table.bin"
		incbin "globe_cos_table.bin"
		ds 16,0
				
		ds 16,$00
		ds 16,$28
		ds 16,$50
		ds 16,$78


	
;------------------------------------------------------------------------------------------------

rgby_ballsprite	incbin "rgby_balls_two_sizes_sprites_packed_v3.bin"
endofrgbybs	db 0

font_tiles	incbin "reflected_font_tiles_packed.bin"
endoffont		db 0

scroll_fine	db 0
scrolltext_addr	dw scroll_text

scroll_text	db "                                   "
		DB " DEJA VU?        WELCOME TO VECTORBALLS II - THE REDUX!"
		DB "       THIS IS A QUICK UPDATE OF THE VECTORBALLS"
		DB " DEMO WHICH WAS ORIGINALLY MADE FOR MY V4 Z80 PROJECT."
		DB " THIS VERSION USES SOME OF THE NEW FEATURES OF THE V5Z80P"
		DB " SUCH AS THE 16 BIT MATHS HARDWARE AND 127 SPRITE REGISTERS...       "
		DB " GREETINGS TO: JIM B, PETER MCQ, ERIK L, BRANDER, PETER G, GREY, HUW W, STEVE G, RICHARD D,"
		DB " JIM F.A, DANIEL T, ALAN G, GEOFF O, JOSEPH C,"
		DB " VALEN, IVAN, RZH AND ANYONE IVE FORGOTTEN..."
		DB "             CODED BY PHIL RUSTON WWW.RETROLEUM.CO.UK IN 2008.  TUNE BY ALEX CRAXTON 1993.       BE SEEING YOU!"
		db "                           ",0

;------------------------------------------------------------------------------------------------

music_file

