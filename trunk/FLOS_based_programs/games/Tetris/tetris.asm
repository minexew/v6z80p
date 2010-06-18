; ****************************************************
; * Tetris v1.01 for V6Z80P by Phil @ Retroleum 2010 *
; ****************************************************

; Changes in 1.01 - Cosmetic: Added bas-relief fix-up below entry $67 = $77


;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000	

;-------- Initialize  ---------------------------------------------------------

	ld hl,hs_filename		; load hi-score if exists
	call kjt_find_file
	jr nz,no_hs
	ld ix,0
	ld iy,6
	call kjt_set_load_length	; ensure load size is 6 bytes
	ld hl,hiscore
	ld b,0
	call kjt_force_load

no_hs	call init_video
	call init_gfx
	call init_data
	call init_sys
	
	jp title_screen
	
;----------------------------------------------------------------------------

start_new_game

	call clear_stats
	call clear_matrix
	call draw_main_screen
	call update_hiscore
	ld hl,0
	ld (score),hl
	ld (score+2),hl
	ld (score+4),hl
	xor a
	ld (level+1),hl
	ld (game_over),a
	ld (lines_target),a
	ld (lines_target+2),a
	ld (rotation),a
	ld (speed_inc_count),a
	ld a,1
	ld (level),a
	ld (lines_target+1),a
	ld b,8
	ld a,(video_mode)		;lower initial fall speed if video = 60Hz
	or a
	jr z,pal_sp
	ld b,6
pal_sp	ld a,b
	ld (base_speed),a
	ld (speed),a
	call update_score
	call update_level
	call update_lines
	call set_target
	call update_lines
	call get_rand_mod7
	ld (next_piece),a
	call new_piece
	call enable_video

	
;-------- Main Loop ----------------------------------------------------------


main_loop	call kjt_wait_vrt
	
	ld hl,frame_counter
	inc (hl)
	call key_timer
	call play_fx
	
	ld a,(game_over)
	or a
	jr z,playing
	inc a
	jr nz,gotok
	ld a,$ff
gotok	ld (game_over),a
	cp 50
	jr c,waitng
	call test_fire
	jp nz,start_new_game
	jr waitng
	
playing	call game_routines
	
waitng	ld a,(esc_keytime)
	or a
	jr z,main_loop		; continue game if ESC key not pressed

;-------------------------------------------------------------------------------

quit_tetris

	xor a
	out (sys_audio_enable),a	; silence channels

	ld hl,hs_filename		; erase existing hiscore file (if it exists)
	call kjt_erase_file
	ld ix,hiscore
	ld b,0
	ld hl,hs_filename
	ld c,0
	ld de,6
	call kjt_save_file
	
	ld a,$ff			; and quit (restart OS)
	ret

;------------------------------------------------------------------------------

game_routines
	
	ld a,(level_up_wait)
	or a
	jr z,normplay
	dec a
	ld (level_up_wait),a
	jr z,continue
	cp 50
	ret nc
	call split_scroll
	ret
	
continue	call clear_stats		; new level init routines
	call clear_matrix
	call inc_level
	call update_level
	call set_target
	call update_lines
	call new_piece
	call set_base_speed
	
normplay	ld a,(wait_new_piece)
	or a
	jr nz,skip_move
	call move_piece
	call draw_current_piece
	
skip_move	ld a,(wait_new_piece)
	or a
	jr z,skip_fall
	call fall_anim
	call pre_explosion_stuff
	call explosion_anim
	call check_new_piece
	
skip_fall	ld ix,tiles_colours
	ld iy,palette+(128*2)
	ld b,32
	ld a,(spr_palette_offset)
	call palette_adjust
	ret


;------------------------------------------------------------------------------

move_piece


	ld c,0	 
	ld a,(speed)		;subtract y displacement from piece y coord
	ld hl,rapidfall
	add a,(hl)
	ld b,a
	ld a,(y_fine)
	sub b
	ld (y_fine),a
	jr nc,no_fcarry		
	inc c			;has the piece moved into a new 8x8 block?
no_fcarry	ld a,(piece_y)
	sub c
	ld (piece_y),a
	ld a,c
	ld (new_block),a

	call shunt

	ld bc,$00ff		;any block obstructions below?
	call test_location
	jr nz,wait_mo
	ld a,(x_fine)		;if pixel x is not zero must also test piece positioned right
	or a
	jr z,clearbelow
	ld bc,$01ff
	call test_location
	jr z,clearbelow


wait_mo	ld a,$e0			;landed - fix pixel position at 7
	ld (y_fine),a		
	ld a,(go_left)		;wait until slide has completed
	ld b,a
	ld a,(go_right)
	or b
	jr nz,clearbelow
	call stamp_piece		;draw the piece on the bitmap
	call test_for_solid_lines
	ld a,(piece_y)		;score based on y resting spot
	neg
	add a,23
	ld b,a
sca_lp	push bc
	ld hl,add_one
	call add_score
	pop bc
	djnz sca_lp
	call update_score
	ld a,(wait_new_piece)
	or a
	ret nz
	call new_piece
	ld bc,$0000
	call test_location		;if new piece has overlapped top of stack
	ret z			;game over
	call stamp_piece
	ld a,1
	ld (game_over),a
	ld a,5
	call new_fx
	call show_game_over
	call check_hiscore
	ret
	
clearbelow	



go_rotate	call test_fire		;rotate the piece?
	jr z,no_rotate
	ld a,(current_piece)
	cp 3
	jr z,no_rotate		;square piece has no rotation
	ld a,(rotation)
	inc a
	and 3
	ld (rotation),a
	ld c,$ff			;y offset
	ld a,(go_right)
	ld b,a			;x offset
	call test_location		;is rotation allowed here?
	jr nz,rot_block
	ld a,6
	call new_fx
	jr no_rotate
rot_block	ld a,(rotation)
	dec a
	and 3
	ld (rotation),a


no_rotate

	call test_down
	jr nz,fastfall
	ld a,(rapidfall)
	sub $20
	jr nc,notfast
	xor a
fspok	jr notfast
fastfall	ld a,(rapidfall)
	add a,$20
	cp $60
	jr c,notfast
	ld a,$60
notfast	ld (rapidfall),a
	
	ret





shunt	ld a,(go_right)		;if right shunt already occuring do right shunt motion
	or a
	jr z,notright
	ld a,(x_fine)
	add a,2
	ld (x_fine),a
	cp 8
	ret nz
	xor a
	ld (x_fine),a
	ld (go_right),a
	ld hl,piece_x
	inc (hl)
	ret


notright	ld a,(go_left)		;init a shunt left? Not allowed if already occuring.
	or a
	jr z,ncsl
	ld a,(x_fine)		;do left shunt motion
	sub 2
	ld (x_fine),a
	ret nz			;dont allow another slide left to be initialized this frame
	xor a
	ld (go_left),a
	ret
	
ncsl	call test_left_joy		; want to move piece left?
	jr z,noinitl
	ld a,(piece_x)
	cp 2
	ret z			; left side of piece cant go further left than 2
	ld a,(new_block)		; has piece has crossed over block boundary?
	or a
	jr z,nnewblk1
	ld bc,$ff00		; yes it has, is there a left block obstruction?
	call test_location		
	ret nz
	ld a,1			
	ld (go_left),a
	ld a,(piece_x)		; if clear it can go left but...
	dec a
	ld (piece_x),a		
	ld a,6
	ld (x_fine),a
	ld bc,$00ff
	call test_location		; test also block below (+ left)
	ret z
	ld a,$e0			; if there's an obstruction here, reposition the block to slide in the gap
	ld (y_fine),a
	ret
nnewblk1	ld bc,$ff00		; test current block and below (+left) for obstructions
	call test_location		
	ret nz
	ld bc,$ffff
	call test_location
	ret nz	
	ld a,1			
	ld (go_left),a
	ld a,(piece_x)		
	dec a
	ld (piece_x),a		
	ld a,6
	ld (x_fine),a
	ret
	
noinitl	ld a,(go_right)		; init a shunt right?
	or a
	ret nz

	call test_right_joy		; want to move piece right?
	ret z
	ld a,(new_block)		; has piece has crossed over block boundary?
	or a
	jr z,nnewblk2
	ld bc,$0100		; yes it has, is there a right block obstruction?
	call test_location		
	ret nz
	ld a,1			; no, so it can go right but also...	
	ld (go_right),a
	ld a,2
	ld (x_fine),a
	ld bc,$01ff
	call test_location		; test block below (+ right)
	ret z
	ld a,$e0			; if there's an obstruction here, reposition the block to slide in the gap
	ld (y_fine),a
	ret
nnewblk2	ld bc,$0100		; test current block and below (+right) for obstructions
	call test_location		
	ret nz
	ld bc,$01ff
	call test_location
	ret nz	
	ld a,1			
	ld (go_right),a
	ld a,2
	ld (x_fine),a
	ret


;------------------------------------------------------------------------------


test_location

;returns with zero flag set if no collision

	ld (tl_offset),bc			;b = x offset, c = y offset

	call get_piece_data		
	ld a,(tl_offset+1)
	add a,(iy)
	ld b,a
	ld a,(tl_offset)
	add a,(iy+1)	
	ld c,a
	call locate_frag
	ld a,(hl)
	cp $ff
	ret nz
	ld de,4
	add iy,de
	ld a,(tl_offset+1)
	add a,(iy)
	ld b,a
	ld a,(tl_offset)
	add a,(iy+1)	
	ld c,a
	call locate_frag
	ld a,(hl)
	cp $ff
	ret nz
	ld de,4
	add iy,de
	ld a,(tl_offset+1)
	add a,(iy)
	ld b,a
	ld a,(tl_offset)
	add a,(iy+1)	
	ld c,a
	call locate_frag
	ld a,(hl)
	cp $ff
	ret nz
	ld de,4
	add iy,de
	ld a,(tl_offset+1)
	add a,(iy)
	ld b,a
	ld a,(tl_offset)
	add a,(iy+1)	
	ld c,a
	call locate_frag
	ld a,(hl)
	cp $ff
	ret
	
	

locate_frag
	
	ld a,(piece_y)
	add a,c
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld a,(piece_x)
	add a,b
	ld e,a
	ld d,0
	add hl,de
	ld de,board_matrix
	add hl,de			;HL = addr in matrix of top/left piece "origin"
	ret
	

;------------------------------------------------------------------------------


new_piece	ld a,(next_piece)
	ld (current_piece),a
	sla a
	ld l,a
	ld h,0
	ld de,stats
	add hl,de
	inc (hl)			;inc stats
	jr nz,statok
	ld (hl),255
statok	call update_stats
	call get_rand_mod7
	ld (next_piece),a
	
	xor a
	ld (rotation),a
	ld a,22
	ld (piece_y),a
	ld a,6
	ld (piece_x),a
	ld a,$e0			
	ld (y_fine),a
	
	xor a
	ld (fall_time),a
	ld (wait_new_piece),a
	ld (ready_for_new_piece),a
	ld (frag_flashtime),a
	ld (frag_explosion),a
	ld (spr_palette_offset),a
	
	ld a,(speed_inc_count)
	inc a
	ld (speed_inc_count),a
	cp 16
	jr nz,skpspd
	xor a
	ld (speed_inc_count),a
	ld a,(base_speed)		;increase falling speed of pieces
	add a,$20			;but do not go over 1 pixels per frame
	cp $60			;faster than the levels's base speed
	jr c,spe_ok1
	ld a,$80
spe_ok1	ld b,a
	ld a,(speed)
	add a,1
	cp b
	jr c,spe_ok2
	ld a,b
spe_ok2	ld (speed),a
	
skpspd	call show_next_piece
	ret


;-----------------------------------------------------------------------------


test_for_solid_lines
	
	
	ld iy,explo_frags
	ld ix,solid_list
	ld hl,board_matrix+48+3
	ld d,0
csl_lp	push hl
	ld a,$ff
	ld b,10
nxtcol	cp (hl)
	jp z,nline2
	inc hl
	djnz nxtcol
	
	ld (ix),d			;make a note of solid lines
	inc ix
	
	push de			;clear the line (bitmap)
	ld a,19
	sub d
	add a,2
	ld l,a
	ld h,0
	add hl,hl
	ld de,display_y_list
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	add hl,hl
	ld de,120
	add hl,de
	ld (blit_dst_loc),hl
	ld hl,200*320
	ld (blit_src_loc),hl
	xor a
	ld (blit_src_msb),a
	ld (blit_dst_msb),a
	ld a,display_width-80
	ld (blit_dst_mod),a
	ld a,-80
	ld (blit_src_mod),a
	ld a,%01000011
	ld (blit_misc),a		; ascending mode
	ld a,7
	ld (blit_height),a
	ld a,79
	ld (blit_width),a		; clear the line on the bitmap
	call wait_blit
	pop de

	ld l,d
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld bc,board_matrix+48+3
	add hl,bc
	push ix
	push hl
	pop ix
	push de

	ld hl,168			; init 10 "explosion" fragments
	sla d
	sla d
	sla d
	ld c,d
	ld b,0
	xor a
	sbc hl,bc
	ld c,l
	ld b,h			; bc =y coord
	sla c
	rl b
	ld de,120*8		; de = first x coord
	ld a,10
nxexfri	push af
	ld (iy),e			; x coord
	ld (iy+1),d
	ld (iy+2),c		; y coord
	ld (iy+3),b
	ld l,(ix)
	inc ix
	ld (iy+4),l		; definition
	ld hl,explo_sel
	add a,(hl)
	ld hl,explo_ydisplist-1
	add a,l
	ld l,a
	jr nc,ncydl
	inc h
ncydl	ld a,(hl)
	ld (iy+6),a		; explosive power y

	ld hl,explo_xdisplist-1
	pop af
	push af
	add a,l
	ld l,a
	jr nc,ncxdl
	inc h
ncxdl	ld a,(hl)			; explosive power x
	ld (iy+5),a

	ex de,hl
	ld de,8*8			; next x frag pos
	add hl,de
	ld de,8
	add iy,de
	ex de,hl
	pop af
	dec a
	jr nz,nxexfri
	ld a,(explo_sel)
	add a,10
	cp 40
	jr nz,xsok
	xor a
xsok	ld (explo_sel),a
	pop de
	pop ix
	
nline2	pop hl			
	ld bc,16
	add hl,bc
	inc d
	ld a,d
	cp 20			
	jp nz,csl_lp		
	
	push ix			;were there any solid lines?
	pop hl
	ld de,solid_list
	xor a
	sbc hl,de
	ld a,l
	or h
	ret z
	ld (solid_count),a		;yes, set up stack collapse vars
	ld a,24			
	ld (frag_flashtime),a
	ld a,1
	ld (wait_new_piece),a
	xor a
	ld (solid_step),a
	call frags_to_sprites
	ld hl,line_bonus_1
	ld a,(solid_count)
	dec a
	sla a
	sla a
	sla a
	ld e,a
	ld d,0
	add hl,de
	call add_score
	call update_score
	ld a,(solid_count)
	ld b,a
inclclp	push bc
	call sub_lines
	pop bc
	djnz inclclp
	call update_lines
	ret

;------------------------------------------------------------------------------------------------

frags_to_sprites

	ld ix,sprite_registers+16
	ld iy,explo_frags
	ld b,40
spfrlp	push bc
	ld l,(iy)
	ld h,(iy+1)			;hl = xpos
	ld a,h
	or l
	jr z,spoff
	ld e,(iy+2)	
	ld d,(iy+3)			;de = ypos
	srl h
	rr l
	srl h
	rr l
	srl h
	rr l
	srl d
	rr e
	ld a,(iy+4)			;a = def
	call do_spr_reg
spoff	ld de,4
	add ix,de
	ld de,8
	add iy,de
	pop bc
	djnz spfrlp
	ret

;----------------------------------------------------------------------------------------------

fixup_frag_defs

	ld iy,explo_frags			;cosmetically adjust frag degfs
	ld b,40
fixfrdlp	ld h,0
	ld l,(iy+4)
	ld de,explo_fixup
	add hl,de
	ld a,(hl)
	ld (iy+4),a
	ld de,8
	add iy,de
	djnz fixfrdlp
	ret
		
;-----------------------------------------------------------------------------------------------

pre_explosion_stuff
	
	ld a,(frag_flashtime)
	or a
	ret z
	ld b,a
	and 4
	sla a
	sla a
	dec a
	ld (spr_palette_offset),a		;flash frag sprites
	ld a,b
	dec a
	ld (frag_flashtime),a
	ret nz

	ld a,8				;if end of flash, set up frag explosion + first scroll down
	ld (fall_time),a
	ld a,$f
	ld (spr_palette_offset),a		
	ld a,1
	ld (frag_explosion),a
	ld a,3
	call new_fx
	call fixup_frag_defs
	
	ld iy,solid_list			;replace "unclosed" bas-relief tiles below
	ld a,(solid_count)			;blank line (purely cosmetic)
	ld b,a
scllp1	push bc
	ld e,(iy)				;get blank line
	dec e
	ld a,(solid_count)
	ld d,a
	ld hl,solid_list
ilasl1	ld a,(hl)
	cp e				;if line above is also a solid line, dont redo bas-relief
	jr z,nxtltc1
	inc hl
	dec d
	jr nz,ilasl1
	ld l,(iy)				;get blank line
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,board_matrix+48+3-16		;hl = addr of matrix below blank line
	add hl,de		
	push hl
	pop ix
	ld a,22
	sub (iy)
	ld c,a				;c = y coord of tile
	ld b,15				;b = x coord of tile
rtonl1	ld a,(ix)
	cp $ff
	jr z,nochb
	ld l,a
	ld h,0
	ld de,fixup_table_b
	add hl,de
	ld a,(hl)				;get replacement tile def
	or a
	jr z,nochb
	ld (ix),a
	push ix
	push bc
	call plot_tile
	pop bc
	pop ix
nochb	inc ix
	inc b
	ld a,b
	cp 25
	jr nz,rtonl1	
nxtltc1	inc iy
	pop bc
	djnz scllp1
	
	ld iy,solid_list			;replace "unclosed" bas-relief tiles above
	ld a,(solid_count)			;blank line (purely cosmetic)
	ld b,a
scllp2	push bc
	ld e,(iy)				;get blank line
	inc e
	ld a,(solid_count)
	ld d,a
	ld hl,solid_list
ilasl2	ld a,(hl)
	cp e				;if line above is also a solid line, dont redo bas-relief
	jr z,nxtltc2
	inc hl
	dec d
	jr nz,ilasl2
	ld l,(iy)				;get blank line
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,board_matrix+48+3+16		;hl = addr of matrix above blank line
	add hl,de		
	push hl
	pop ix
	ld a,20
	sub (iy)
	ld c,a				;c = y coord of tile
	ld b,15				;b = x coord of tile
rtonl2	ld a,(ix)
	cp $ff
	jr z,nocha
	ld l,a
	ld h,0
	ld de,fixup_table_a
	add hl,de
	ld a,(hl)				;get replacement tile def
	or a
	jr z,nocha
	ld (ix),a
	push ix
	push bc
	call plot_tile
	pop bc
	pop ix
nocha	inc ix
	inc b
	ld a,b
	cp 25
	jr nz,rtonl2	
nxtltc2	inc iy
	pop bc
	djnz scllp2

skip	ld hl,solid_list			;collapse board matrix to remove all solid lines
	ld a,(solid_count)			;(go in reverse order so position of blank lines
	ld b,a				;remains true)
	ld e,a
	ld d,0
	add hl,de
	push hl
	pop ix			
collapslp	dec ix			
	ld a,(ix)			
	push bc
	call rejig_matrix
	pop bc
	djnz collapslp
	ret
	
;------------------------------------------------------------------------------------------------
	
explosion_anim
	
	ld a,(frag_explosion)
	or a
	ret z
		
	xor a
	ld (fragofscount),a
	ld iy,explo_frags
	ld b,40				;max number of frags
explflp	push bc
	ld a,(iy)
	or (iy+1)
	jr nz,fragon			;is frag on screen?
	ld hl,fragofscount
	inc (hl)
	jr noxfr
	
fragon	ld b,0
	ld c,(iy+5)			;bc = x displacment
	bit 7,c
	jr z,xdpos
	dec b
xdpos	ld l,(iy)			
	ld h,(iy+1)	
	add hl,bc				;bc = x motion of frag
	ld (iy),l			
	ld (iy+1),h
	ld a,c				;reduce x displacement
	or a
	jr z,xdzero
	bit 7,c
	jr nz,xdneg
	dec c
	jr xdupd
xdneg	inc c
xdupd	ld (iy+5),c		
	
xdzero	ld b,0
	ld c,(iy+6)			;y motion of frag
	bit 7,c
	jr z,ydpos
	dec b
ydpos	ld l,(iy+2)			
	ld h,(iy+3)	
	xor a
	sbc hl,bc				;bc = x motion of frag
	ld (iy+2),l			
	ld (iy+3),h
	ld a,(iy+6)
	dec a				;reduce power (reverse at 0)
	cp $ef			
	jr nz,fydok
	ld a,$f0				;max y speed
fydok	ld (iy+6),a
	ld de,208*2			;frag gone out of screen window?
	xor a
	sbc hl,de
	jr c,noxfr
	xor a
	ld (iy),a				;switch it off if so (x=0)
	ld (iy+1),a

noxfr	ld de,8
	add iy,de
	pop bc
	djnz explflp	

	call frags_to_sprites

	ld a,(spr_palette_offset)		;fade colours of frag sprites
	or a
	jr z,fadedone
	dec a
	ld (spr_palette_offset),a
	
fadedone	ld a,(fragofscount)			;if all fragments are off, we're a step closer to
	cp 40				;launching a new piece
	ret nz
	xor a
	ld (frag_explosion),a
	ld hl,ready_for_new_piece
	set 1,(hl)
	ret

;--------------------------------------------------------------------------------

fall_anim
	
	ld a,(fall_time)		; scroll bitmap blocks down smoothly
	or a
	ret z

	ld a,(solid_step)
	ld e,a
	ld d,0
	ld hl,solid_list
	add hl,de
	ld a,(hl)			;line blocks must fall onto

	ld b,a
	ld a,19
	sub b
	ld b,a
	sla b
	sla b
	sla b			; lines in copy (height of blit)
	
	add a,2
	ld l,a
	ld h,0
	add hl,hl
	ld de,display_y_list
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	add hl,hl
	ld de,120+79+(6*display_width)
	add hl,de
	ld (blit_src_loc),hl
	ld de,display_width
	add hl,de
	ld (blit_dst_loc),hl
	xor a
	ld (blit_src_msb),a
	ld (blit_dst_msb),a
	ld a,display_width-80
	ld (blit_src_mod),a
	ld (blit_dst_mod),a
	ld a,%00000000
	ld (blit_misc),a		; descending mode
	ld a,b
	add a,7
	ld (blit_height),a
	ld a,79
	ld (blit_width),a
	call wait_blit
		
	ld hl,120+(16*display_width)
	ld (blit_dst_loc),hl	;clear first two lines
	ld hl,200*320
	ld (blit_src_loc),hl
	xor a
	ld (blit_src_msb),a
	ld (blit_dst_msb),a
	ld a,display_width-80
	ld (blit_dst_mod),a
	ld a,-80
	ld (blit_src_mod),a
	ld a,%01000011
	ld (blit_misc),a		; ascending mode
	ld a,1
	ld (blit_height),a
	ld a,79
	ld (blit_width),a		; clear the line on the bitmap
	call wait_blit

	ld a,(fall_time)	
	dec a
	ld (fall_time),a
	ret nz
	
	ld b,8
	ld hl,solid_list		;move the lines of the blank line list down one row	
droplp	dec (hl)
	inc hl
	djnz droplp
		
	ld a,(solid_count)
	ld b,a
	ld a,(solid_step)
	inc a
	ld (solid_step),a
	cp b
	jr nz,moretodo
	ld hl,ready_for_new_piece
	set 0,(hl)
	ret

moretodo	ld a,8			;init another tumble animation
	ld (fall_time),a
	ret

;--------------------------------------------------------------------------------

check_new_piece

	ld a,(ready_for_new_piece)
	cp 3
	ret nz
	
	ld ix,lines		; if lines = 000, init a new level
	ld a,(ix)
	or (ix+1)
	or (ix+2)
	jr nz,nonewl
	call show_level_up
	ld a,100
	ld (level_up_wait),a
	ret
	
nonewl	call new_piece
	ret
	
;--------------------------------------------------------------------------------

rejig_matrix

	
; set A to the line the stack should collapse onto

	push af
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,board_matrix+48+3
	add hl,de			
	push hl
	pop de			;de = dest
	ld bc,16
	add hl,bc			;hl = source (16 bytes ahead of dest)
	pop af
rjloop	ld bc,10			;bytes to copy per line
	ldir
	ld bc,6
	add hl,bc
	ex de,hl
	add hl,bc
	ex de,hl
	inc a
	cp 20
	jr nz,rjloop
	
	ld hl,bm_topline+3		;clear the top line also
	ld b,10
ftl_lp	ld (hl),$ff
	inc hl
	djnz ftl_lp
	ret
		
;---------Make / display current piece from four sprites -------------------------------------------


draw_current_piece
	
	ld a,(level_up_wait)
	or a
	jr nz,wipepiece
	ld a,(wait_new_piece)
	or a
	jr z,norm_piece
wipepiece	ld hl,sprite_registers	;clear current piece sprites if waiting
	xor a
	ld b,4*4
clrpielp	ld (hl),a
	inc hl
	djnz clrpielp
	ret

norm_piece

	call get_piece_data
	ld ix,sprite_registers
	ld b,4
spr_fr_lp	push bc
	ld a,(x_fine)
	and 7
	ld c,a
	ld a,(piece_x)		; x coord (in blocks)
	sub 3			; remove matrix offset
	add a,(iy)
	sla a
	sla a
	sla a
	or c
	ld l,a
	ld h,0
	ld de,120			;number of pixels to first column
	add hl,de
	
	ex de,hl
	ld hl,7+(24*8)
	ld a,(y_fine)
	rlca
	rlca
	rlca
	and 7
	ld c,a
	ld a,(piece_y)		;y coord (in blocks)
	add a,(iy+1)
	sla a
	sla a
	sla a
	or c
	ld c,a
	ld b,0
	xor a
	sbc hl,bc			;y coords for current piece has 0 origin at bottom
	ex de,hl
		
	ld a,(iy+3)
	rrca
	rrca
	rrca
	rrca
	or (iy+2)			;definition
	
	call do_spr_reg
	
	ld bc,4
	add ix,bc
	add iy,bc
	
	pop bc
	djnz spr_fr_lp
	ret

;------------------------------------------------------------------------------------------------------

get_piece_data

	ld a,(current_piece)	;IY returns addr in piece info table
	rlca
	rlca
	rlca
	rlca
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	ld de,frag_list
	add hl,de
	ld a,(rotation)
	rlca
	rlca
	rlca
	rlca
	ld e,a
	ld d,0
	add hl,de
	push hl
	pop iy
	ret
	
;------------------------------------------------------------------------------------------------------
	
show_next_piece	
	
	ld a,(next_piece)		
	rlca
	rlca
	rlca
	rlca
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	ld de,frag_list
	add hl,de
	push hl
	pop iy
	
	ld ix,sprite_registers+(44*4)
	ld b,4
spr_f_lp2	push bc
	
	ld hl,40
	ld d,0
	ld e,(iy)
	sla e
	sla e
	sla e
	add hl,de
	push hl
	ld hl,next_piece_offsets
	ld a,(next_piece)
	ld e,a
	ld d,0
	add hl,de
	ld e,(hl)
	ld d,0
	bit 7,e
	jr z,npospos
	dec d
npospos	pop hl
	add hl,de
	
	ex de,hl
	ld hl,136		
	ld b,0
	ld c,(iy+1)
	sla c
	sla c
	sla c
	bit 7,c
	jr z,posoff
	dec b
posoff	xor a
	sbc hl,bc
	ex de,hl
	
	ld a,(iy+3)
	rrca
	rrca
	rrca
	rrca
	or (iy+2)			;definition
	
	call do_spr_reg2
	
	ld bc,4
	add ix,bc
	add iy,bc
	
	pop bc
	djnz spr_f_lp2
	ret
	
	
;----------------------------------------------------------------------------------------------------

x_win_offset equ $7f		;offset from display window edge
	
do_spr_reg

;set ix to sprite register base
;hl = x coord
;de = y coord
;a  = definition (only using 0-255 here)

	ld bc,x_win_offset
	add hl,bc
	ld bc,(y_win_offset)
	ex de,hl
	add hl,bc
	ex de,hl
	ld (ix+3),a		;def
	ld (ix+0),l		;x lsb
	ld (ix+2),e		;y lsb
	sla d			
	ld a,h
	or d
	or $10
	ld (ix+1),a		;msbs etc
	ret


;--------------------------------------------------------------------------------

do_spr_reg2

;set ix to sprite register base
;hl = x coord
;de = y coord
;a  = definition (this routine for defs 256+ here)

	ld bc,x_win_offset
	add hl,bc
	ld bc,(y_win_offset)
	ex de,hl
	add hl,bc
	ex de,hl
	ld (ix+3),a		;def
	ld (ix+0),l		;x lsb
	ld (ix+2),e		;y lsb
	sla d			
	ld a,h
	or d
	or $14
	ld (ix+1),a		;msbs etc
	ret


;--------------------------------------------------------------------------------

;set ix = source colours
;set iy = dest palette
;set a = colour offset (0-F = whiten, F = whitest / F0-FF = darken, F0 = darkest)
;set b = number of colours to do
	
palette_adjust
	
	bit 7,a
	jr nz,drkcols
	
	and $f
	ld e,a
	rrca
	rrca
	rrca
	rrca
	ld d,a
colwlp	ld a,(ix)
	ld l,a
	and $f
	add a,e
	bit 4,a
	jr z,nocar1
	ld a,$f
nocar1	ld h,a
	ld a,l
	and $f0
	add a,d
	jr nc,nocar2
	ld a,$f0
nocar2	or h
	ld (iy),a
	ld a,(ix+1)
	and $f
	add a,e
	bit 4,a
	jr z,nocar3
	ld a,$f
nocar3	ld (iy+1),a
	inc ix
	inc ix
	inc iy
	inc iy
	djnz colwlp
	ret

drkcols	neg
	and $f
	ld e,a
	rrca
	rrca
	rrca
	rrca
	ld d,a
colblp	ld a,(ix)
	ld l,a
	and $f
	sub e
	jr nc,nocar4
	xor a
nocar4	ld h,a
	ld a,l
	and $f0
	sub d
	jr nc,nocar5
	xor a
nocar5	or h
	ld (iy),a
	ld a,(ix+1)
	and $f
	sub e
	jr nc,nocar6
	xor a
nocar6	ld (iy+1),a
	inc ix
	inc ix
	inc iy
	inc iy
	djnz colblp
	ret
	

;--------- Stamp image of frozen piece into bitmap --------------------------------------------------

stamp_piece

	call get_piece_data
	push iy
	
	ld b,4
stamp_lp	push bc
	ld a,(piece_x)		; x coord (in blocks)
	sub 3			; remove matrix offset
	add a,(iy)
	add a,15			; x char position of matrix on screen
	ld b,a
	ld a,(piece_y)		; y coord (in blocks)
	add a,(iy+1)
	ld c,a
	ld a,24			; flip y coord and add offset to first line
	sub c
	ld c,a		
	ld a,(iy+3)
	rrca
	rrca
	rrca
	rrca
	or (iy+2)			; tile definition
	call plot_tile
	ld bc,4
	add iy,bc	
	pop bc
	djnz stamp_lp
	
	pop iy			; now write block data to board matrix
	ld b,4
matrix_lp	push bc
	ld b,(iy)
	ld c,(iy+1)
	call locate_frag		; returns in HL address in board matrix
	ld a,(iy+3)
	rrca
	rrca
	rrca
	rrca
	or (iy+2)			; tile definition
	ld (hl),a			; enter tile def in matrix	
	ld bc,4
	add iy,bc	
	pop bc
	djnz matrix_lp
	
	ld a,7
	call new_fx
	ret


;-------------------------------------------------------------------------------------------------

plot_tile

; b = x
; c = y
; a = tile number ($yx)
	
	ld l,c
	ld h,0
	add hl,hl
	ld de,display_y_list
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	add hl,hl
	ld d,0
	sla b
	sla b
	sla b
	rl d
	ld e,b	
	add hl,de
	ld (blit_dst_loc),hl		; destination
	
	ld l,a
	and $f0
	rrca
	ld h,a
	ld a,l
	and $f
	rlca
	rlca
	rlca
	ld l,a
	ld (blit_src_loc),hl		; source
	xor a
	ld (blit_dst_msb),a
	inc a
	ld (blit_src_msb),a
	
	ld a,248
	ld (blit_src_mod),a			; set blit source modulo [0:7]
	ld hl,display_width-8		; calculate dest modulo (window size - bob width)
	ld a,l
	ld (blit_dst_mod),a			; set blit dest modulo [0:7]
	ld a,h				; calc MSBs for dest & source 
	rlca
	rlca
	or %01000000			; Transparency = off, ascending = 1 
	ld (blit_misc),a		

	ld a,7				;
	ld (blit_height),a			; set blit height
	ld (blit_width),a			; start the blit
	call wait_blit
	ret


;------------------------------------------------------------------------------

draw_main_screen

	ld de,charmap
	ld l,0
yok	ld h,0
xok	ld b,h
	ld c,l
	ld a,(de)
	push hl
	push de
	call plot_tile
	pop de
	pop hl
	inc de
	inc h
	ld a,h
	cp 40
	jr nz,xok
	inc l
	ld a,l
	cp 25
	jr nz,yok
	ret
	
;-------------------------------------------------------------------------------------------------

get_rand_mod7

	call get_rand			; return 0-6 in A
	ld c,7
	xor a
	call divide_16_8
	ret
	

get_rand	ld	de,(seed)		
	ld	a,d
	ld	h,e
	ld	l,253
	or	a
	sbc	hl,de
	sbc	a,0
	sbc	hl,de
	ld	d,0
	sbc	a,d
	ld	e,a
	sbc	hl,de
	jr	nc,rand
	inc	hl
rand	ld	(seed),hl		
	ret




divide_16_8

	add hl,hl		
	rla		
	cp c		
	jr c,divit1	
	sub c		
	inc l		

divit1	add hl,hl		
	rla		
	cp c		
	jr c,divit2	
	sub c		
	inc l		

divit2	add hl,hl		
	rla		
	cp c		
	jr c,divit3	
	sub c		
	inc l		

divit3	add hl,hl		
	rla		
	cp c		
	jr c,divit4	
	sub c		
	inc l		

divit4	add hl,hl		
	rla		
	cp c		
	jr c,divit5	
	sub c		
	inc l		

divit5	add hl,hl		
	rla		
	cp c		
	jr c,divit6	
	sub c		
	inc l		

divit6	add hl,hl		
	rla		
	cp c		
	jr c,divit7	
	sub c		
	inc l		

divit7	add hl,hl		
	rla		
	cp c		
	jr c,divit8	
	sub c		
	inc l		

divit8	add hl,hl		
	rla		
	cp c		
	jr c,divit9	
	sub c		
	inc l		

divit9	add hl,hl		
	rla		
	cp c		
	jr c,divit10	
	sub c		
	inc l		

divit10	add hl,hl		
	rla		
	cp c		
	jr c,divit11	
	sub c		
	inc l		

divit11	add hl,hl		
	rla		
	cp c		
	jr c,divit12	
	sub c		
	inc l		

divit12	add hl,hl		
	rla		
	cp c		
	jr c,divit13	
	sub c		
	inc l		

divit13	add hl,hl		
	rla		
	cp c		
	jr c,divit14	
	sub c		
	inc l		

divit14	add hl,hl		
	rla		
	cp c		
	jr c,divit15	
	sub c		
	inc l		

divit15	add hl,hl		
	rla		
	cp c		
	jr c,divit16	
	sub c		
	inc l		

divit16	ret
	
;-------------------------------------------------------------------------------------------------

test_down

	ld a,(down_keytime)
	or a
	ret nz
	in a,(sys_joy_com_flags)
	bit 1,a
	ret
	

test_left_joy

	ld a,(left_keytime)
	or a
	ret nz
trylj	in a,(sys_joy_com_flags)
	bit 2,a
	ret


test_right_joy

	ld a,(right_keytime)
	or a
	ret nz
tryrj	in a,(sys_joy_com_flags)
	bit 3,a
	ret
	
	
test_fire

	ld a,(up_keytime)
	cp 2
	jr nz,nokeyfire
	ld a,1
	or a
	ret
nokeyfire	in a,(sys_joy_com_flags)
	bit 4,a
	jr nz,holdfire
	xor a
	ld (fire_latch),a
	ret
holdfire	ld a,(fire_latch)
	or a
	jr z,jfire
	xor a
	ret
jfire	ld a,1
	ld (fire_latch),a
	or a
	ret


key_timer

	ld a,(up_keytime)
	or a
	jr z,leftkt
	inc a
	ld (up_keytime),a
	jr nz,leftkt
	ld a,$ff
	ld (up_keytime),a
	
leftkt	ld a,(left_keytime)
	or a
	jr z,rightkt
	inc a
	ld (left_keytime),a
	jr nz,rightkt
	ld a,$ff
	ld (left_keytime),a
	
rightkt	ld a,(right_keytime)
	or a
	ret z
	inc a
	ld (right_keytime),a
	ret nz
	ld a,$ff
	ld (right_keytime),a	
	ret
	
	
;-----------------------------------------------------------------------------------------------------

;set hl to point to addition value string

add_score	ld de,score
	ld b,6
	ld c,0
scralp	ld a,(de)
	add a,(hl)
	add a,c
	ld c,0
	cp 10
	jr c,sanctd
	sub 10
	ld c,1
sanctd	ld (de),a
	inc hl
	inc de
	djnz scralp
	ret
	
;--------------------------------------------------------------------------------------------------

update_score

	ld hl,score+4
	ld b,4
	ld c,4
	ld e,5
uslp	ld a,(hl)
	add a,$c0
	push de
	push bc
	push hl
	call plot_tile
	pop hl
	pop bc
	pop de
	dec hl
	inc b
	dec e
	jr nz,uslp
	ret

;--------------------------------------------------------------------------------------------------

update_stats
	
	ld ix,stats
	ld c,0
stloop	ld a,(ix)
	or a
	jr z,skipts
	cp 32
	jr c,heightok
	ld a,32
heightok	dec a
	ld (blit_height),a
	ld a,32
	sub (ix)
	jr nc,hsok1
	xor a
hsok1	ld l,a
	ld h,0
	add hl,hl
	ld de,y_line_offset_list
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld hl,251+(134*display_width)	;y pos of bars (top line)
	add hl,de
	ld b,0
	add hl,bc
	ld (blit_dst_loc),hl
	ld hl,72+(64*256)		; source of bar gfx
	add hl,bc
	ld (blit_src_loc),hl
	ld a,1
	ld (blit_src_msb),a
	xor a
	ld (blit_dst_msb),a
	ld hl,display_width-5
	ld a,l
	ld (blit_dst_mod),a
	ld a,256-5
	ld (blit_src_mod),a
	ld a,h
	sla a
	sla a
	or %01000000
	ld (blit_misc),a		; ascending mode
	ld a,4
	ld (blit_width),a
	call wait_blit
	
skipts	inc ix
	inc ix
	ld a,c
	add a,5
	ld c,a
	cp 35
	jr nz,stloop
	ret

;--------------------------------------------------------------------------------------------------------

clear_stats
	
	ld hl,251+(134*display_width)	;y pos of bars (top line)
	ld (blit_dst_loc),hl
	ld hl,200*320
	ld (blit_src_loc),hl
	xor a
	ld (blit_src_msb),a
	ld (blit_dst_msb),a
	ld a,-35
	ld (blit_src_mod),a
	ld hl,display_width-35
	ld a,l
	ld (blit_dst_mod),a
	ld a,h
	sla a
	sla a
	or %01000011
	ld (blit_misc),a		; ascending mode
	ld a,31
	ld (blit_height),a
	ld a,34
	ld (blit_width),a		; clear the line on the bitmap
	call wait_blit

	ld hl,stats
	ld b,14
cstlp	ld (hl),0
	inc hl
	djnz cstlp
	ret

;--------------------------------------------------------------------------------------------------
	
show_game_over

	ld de,gameover_chars
	ld h,6
	ld c,9
golp2	ld l,8
	ld b,16
golp1	ld a,(de)
	push de
	push bc
	push hl
	call plot_tile
	pop hl
	pop bc
	pop de
	inc de
	inc b
	dec l
	jr nz,golp1
	inc c
	dec h
	jr nz,golp2
	ret	

	
;---------------------------------------------------------------------------------------------------

sub_lines

	ld b,3
	ld hl,lines
subllp	dec (hl)
	ld a,(hl)
	cp $ff
	ret nz
	ld (hl),9
	inc hl
	djnz subllp
	ld hl,lines
	ld (hl),0
	inc hl
	ld (hl),0
	inc hl
	ld (hl),0
	ret


;---------------------------------------------------------------------------------------------------

update_lines

	ld hl,lines+2
	ld b,32
	ld c,4
	ld e,3
ulvlp	ld a,(hl)
	add a,$c0
	push de
	push bc
	push hl
	call plot_tile
	pop hl
	pop bc
	pop de
	dec hl
	inc b
	dec e
	jr nz,ulvlp
	ret	


;---------------------------------------------------------------------------------------------------

show_level_up

	ld de,level_up_chars
	ld h,3
	ld c,11
golu2	ld l,10
	ld b,15
golu1	ld a,(de)
	push de
	push bc
	push hl
	call plot_tile
	pop hl
	pop bc
	pop de
	inc de
	inc b
	dec l
	jr nz,golu1
	inc c
	dec h
	jr nz,golu2
	ret	

;---------------------------------------------------------------------------------------------------

inc_level
	
	ld b,3
	ld hl,level
ilevlp	inc (hl)
	ld a,(hl)
	cp 10
	ret nz
	ld (hl),0
	inc hl
	djnz ilevlp
	dec hl
	ld (hl),9
	dec hl
	ld (hl),9
	dec hl
	ld (hl),9
	ret



;--------------------------------------------------------------------------------------------------
	
update_level

	ld hl,level+2
	ld b,32
	ld c,10
	ld e,3
ullp	ld a,(hl)
	add a,$c0
	push de
	push bc
	push hl
	call plot_tile
	pop hl
	pop bc
	pop de
	dec hl
	inc b
	dec e
	jr nz,ullp
	ret


;---------------------------------------------------------------------------------------------------

set_target

	ld hl,lines_inc
	ld de,lines_target
	ld b,3
	ld c,0
ltralp	ld a,(de)
	add a,(hl)
	add a,c
	ld c,0
	cp 10
	jr c,ltnctd
	sub 10
	ld c,1
ltnctd	ld (de),a
	inc hl
	inc de
	djnz ltralp
	
	ld hl,lines_target
	ld de,lines
	ld bc,3
	ldir
	ret


;-----------------------------------------------------------------------------------------------------

check_hiscore

	ld hl,score+4
	ld de,hiscore+4
	ld b,5
nsft	ld a,(de)
	cp (hl)
	jr c,higher
	ret nz
	dec hl
	dec de
	djnz nsft
	ret
higher	ld hl,score
	ld de,hiscore		
	ld bc,5
	ldir
		
update_hiscore

	ld hl,hiscore+4		;update hi score
	ld b,4
	ld c,10
	ld e,5
uhslp	ld a,(hl)
	add a,$c0
	push de
	push bc
	push hl
	call plot_tile
	pop hl
	pop bc
	pop de
	dec hl
	inc b
	dec e
	jr nz,uhslp
	ret

;--------------------------------------------------------------------------------------------------

split_scroll

	ld hl,121+(16*display_width)
	ld (blit_src_loc),hl
	dec hl
	dec hl
	ld (blit_dst_loc),hl
	xor a
	ld (blit_src_msb),a
	ld (blit_dst_msb),a
	ld hl,display_width-40
	ld a,l
	ld (blit_src_mod),a
	ld (blit_dst_mod),a
	ld a,h
	sla a
	sla a
	or h
	or %01000000
	ld (blit_misc),a
	ld a,159
	ld (blit_height),a
	ld a,39
	ld (blit_width),a
	call wait_blit
	
	ld hl,198+(16*display_width)
	ld (blit_src_loc),hl
	inc hl
	inc hl
	ld (blit_dst_loc),hl
	xor a
	ld (blit_src_msb),a
	ld (blit_dst_msb),a
	ld hl,65536-(display_width+40)
	ld a,l
	ld (blit_src_mod),a
	ld (blit_dst_mod),a
	ld a,h
	and 3
	ld h,a
	sla a
	sla a
	or h
	or %00000000
	ld (blit_misc),a
	ld a,159
	ld (blit_height),a
	ld a,39
	ld (blit_width),a
	call wait_blit
		
	
	ld hl,0+(200*display_width)
	ld (blit_src_loc),hl
	ld hl,158+(16*display_width)
	ld (blit_dst_loc),hl
	xor a
	ld (blit_src_msb),a
	ld (blit_dst_msb),a
	ld hl,display_width-4
	ld a,-4
	ld (blit_src_mod),a
	ld a,l
	ld (blit_dst_mod),a
	ld a,h
	sla a
	sla a
	or h
	or %01000011
	ld (blit_misc),a
	ld a,159
	ld (blit_height),a
	ld a,3
	ld (blit_width),a
	call wait_blit
	ret
	
;--------------------------------------------------------------------------------------------------

clear_matrix

	ld hl,board_matrix+48+3
	ld c,20
fblp2	ld b,10
fblp1	ld (hl),$ff
	inc hl
	djnz fblp1
	ld de,6
	add hl,de
	dec c
	jr nz,fblp2
	ret


;---------------------------------------------------------------------------------------------------

set_base_speed

	xor a
	ld (speed_inc_count),a
	
	ld a,(base_speed)
	add a,2
	cp $60
	jr c,speedok
	ld a,$80
speedok	ld (base_speed),a
	ld (speed),a
	ret

	
;---------------------------------------------------------------------------------------------------


wait_blit	ld a,(vreg_read)		; wait for blit to end
	and $10
	jr nz,wait_blit
	ret



;------------------------------------------------------------------------------	
;         Initialization code 
;------------------------------------------------------------------------------

display_width  equ 320
display_height equ 200

init_video

	ld b,0			; Get display mode		
	in a,(sys_hw_flags)		; VGA jumper on?
	bit 5,a
	jr z,not_vga
	ld b,2
	jr got_mode 
not_vga	ld a,(vreg_read)		; 60 Hz?
	bit 5,a
	jr z,got_mode
	ld b,1
got_mode	ld a,b
	ld (video_mode),a		; 0=PAL, 1=NTSC, 2=VGA

	xor a
	ld (vreg_rasthi),a		; select y window reg
	ld de,$29			; PAL sprite y offset
	ld c,$5a			; PAL centred position for 200 line display
	xor a
	or b
	jr z,pal
	ld c,$38			; NTSC / VGA position for 200 line display
	ld de,$19			; NTSC / VGA sprite y offset
pal	ld (y_win_offset),de
	ld a,c
	ld (vreg_window),a		; set y window size/position (200 lines)
	ld a,%00000100
	ld (vreg_rasthi),a		; select x window reg
	ld a,$8c
	ld (vreg_window),a		; set x window size/position (320 pixels)

	di			; disable IRQs for direct video RAM write mode
	xor a	
	ld (vreg_vidpage),a		; clear vram $0-$ffff
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
	ei
	
	ld ix,bitplane0a_loc	; initialize datafetch start address HW pointer.
	ld hl,$0000		; datafetch start address (15:0)
	ld a,0			; data fetch start address (16)
	ld (ix),l
	ld (ix+1),h
	ld (ix+2),a
	
	call disable_video
	ret

;---------------------------------------------------------------------------------------

setup_game_palette
	
	ld hl,tiles_colours		; set up palette
	ld de,palette
	ld bc,256
	ldir
	ld hl,tiles_colours		; use first 32 colours at 128+ also (for sprites)
	ld de,palette+256
	ld bc,64
	ldir
	ret
	
;--------------------------------------------------------------------------------------

clear_sprites

	ld hl,spr_registers		; zero all sprite registers
	ld b,0
wsprrlp	ld (hl),0
	inc hl
	ld (hl),0
	inc hl
	djnz wsprrlp
	ret
		
;------------------------------------------------------------------------------------

init_gfx

	ld a,%10000000		;Copy tile defs to sprites		
	out (sys_mem_select),a	;page in sprites @ $1000-$1fff
	ld a,$80
	ld (spr_page),a
	ld hl,tiles		;source address
	ld b,12			;12 rows of tiles
lp4	push bc
	push hl
	ld a,(spr_page)
	ld (vreg_vidpage),a
	inc a
	ld (spr_page),a	
	ld de,sprite_base
lp3	xor a
	ld e,a			;clear sprite definition block
clrspd	ld (de),a
	inc e
	jr nz,clrspd
	ld e,a
	ld c,8			;copy 8x8 tile to definition block
lp2	ld b,8			;width of tile
lp1	ld a,(hl)
	add a,128			;move pixel's palette index
	ld (de),a
	inc hl
	inc de
	djnz lp1
	push bc
	ld bc,128-8
	add hl,bc
	ld bc,8
	ex de,hl
	add hl,bc
	ex de,hl
	pop bc
	dec c
	jr nz,lp2
	ld bc,1016		;move to next tile source address (128*8)-8
	xor a
	sbc hl,bc
	inc d			;next sprite base dest
	ld a,d
	and $f
	cp $9
	jr nz,lp3
	pop hl
	ld bc,1024		;move to next tile source address (128*7) - new line
	add hl,bc
	pop bc
	djnz lp4
	
	ld a,$90			;copy also to sprite defs $100+ (no palette shift)
	ld (spr_page),a
	ld hl,tiles		;source address
	ld b,12			;12 rows of tiles
sc2lp4	push bc
	push hl
	ld a,(spr_page)
	ld (vreg_vidpage),a
	inc a
	ld (spr_page),a	
	ld de,sprite_base
sc2lp3	xor a
	ld e,a			;clear sprite definition block
sc2clrspd	ld (de),a
	inc e
	jr nz,sc2clrspd
	ld e,a
	ld c,8			;copy 8x8 tile to definition block
sc2lp2	ld b,8			;width of tile
sc2lp1	ld a,(hl)
	ld (de),a
	inc hl
	inc de
	djnz sc2lp1
	push bc
	ld bc,128-8
	add hl,bc
	ld bc,8
	ex de,hl
	add hl,bc
	ex de,hl
	pop bc
	dec c
	jr nz,sc2lp2
	ld bc,1016		;move to next tile source address (128*8)-8
	xor a
	sbc hl,bc
	inc d			;next sprite base dest
	ld a,d
	and $f
	cp $9
	jr nz,sc2lp3
	pop hl
	ld bc,1024		;move to next tile source address (128*7) - new line
	add hl,bc
	pop bc
	djnz sc2lp4

	xor a
	out (sys_mem_select),a	;page out sprite defs from Z80 RAM
	
	
;--------Copy tiles to VRAM $10000 --------------------------------------------------------------
	
	di			; disable IRQs for direct video RAM write mode
	ld a,8
	ld (vreg_vidpage),a		
	ld a,%00100000		
	out (sys_mem_select),a	; all writes to VRAM mode
	
	ld hl,tiles
	ld de,0
	ld a,112
cttvrlp	ld bc,128
	ldir
	ex de,hl
	ld bc,256-128
	add hl,bc
	ex de,hl
	dec a
	jr nz,cttvrlp
		
	xor a		
	out (sys_mem_select),a	; normal RAM mode
	ei	
	ret
	
;-------------------------------------------------------------------------------------------------

init_data

	ld ix,display_y_list	; build y line offset list
	ld hl,0
	ld de,display_width*4	; (offset values doubled in plot routine)
	ld b,32
mvyl_loop	ld (ix),l
	ld (ix+1),h
	add hl,de
	inc ix
	inc ix
	djnz mvyl_loop
	ret


;--------------------------------------------------------------------------------------------------

init_sys	di	
	ld hl,my_irq_handler	; set IRQ vector for custom keyboard code 
          ld (irq_vector),hl	  
	ld a,%00000001
	out (sys_clear_irq_flags),a	; clear keyboard irq flag 
	ld a,%10000001		
          out (sys_irq_enable),a	; enable keyboard interrupts
	ei
	call upload_samples
	
	xor a
	out (sys_ps2_joy_control),a	; select joyport 0
	ret

;--------------------------------------------------------------------------------------------

upload_samples


	ld hl,$8000			;copy samples to sound sys accessible RAM
	exx
	ld de,end_of_sample_data
	ld hl,sample_data
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
	ret
	
;----------------------------------------------------------------------------------------
; IRQ routine
;----------------------------------------------------------------------------------------

my_irq_handler

	push af			; Maskable IRQ jumps here
	in a,(sys_irq_ps2_flags)	; Read irq status flags
	bit 0,a			; keyboard irq set?
	call nz,keyboard_irq_code	; call keyboard irq routine if so
	pop af			
	ei			; re-enable interrupts
	reti			; return to main code
	

keyboard_irq_code

	push af			; treats keyboard as joystick, IE: directions until key released
	push hl			
	
	in a,(sys_keyboard_data)	; get the keycode
	cp $f0
	jr nz,not_rel
	ld hl,key_release
	ld (hl),1
	jr key_done
	
not_rel	cp $75
	jr nz,knotup
	ld hl,up_keytime
	jr got_key
knotup	cp $6b
	jr nz,knotleft
	ld hl,left_keytime
	jr got_key
knotleft	cp $72
	jr nz,knotdown
	ld hl,down_keytime
	jr got_key
knotdown	cp $74
	jr nz,knotright
	ld hl,right_keytime
	jr got_key
knotright	cp $76
	jr nz,knotesc
	ld hl,esc_keytime
	jr got_key
knotesc	ld hl,other_keytime
	
got_key	ld a,(key_release)
	or a
	jr z,press
	xor a
	ld (hl),a
	ld (key_release),a
	jr key_done
press	ld (hl),1
	
key_done	ld a,%00000001
	out (sys_clear_irq_flags),a	; clear keyboard interrupt flag
	pop hl
	pop af
	ret

;--------------------------------------------------------------------------------------------------

enable_video
	
	call kjt_wait_vrt
	ld a,%10000000
	ld (vreg_vidctrl),a		; Set bitmap mode + chunky pixel mode
	ld a,%00000001
	ld (vreg_sprctrl),a		; Enable sprites	
	ret
	
		
disable_video

	call kjt_wait_vrt
	ld a,%10000100
	ld (vreg_vidctrl),a		; Disable video / bitmap mode + chunky pixel mode
	ld a,%00000000
	ld (vreg_sprctrl),a		; Disable sprites	
	ret
		
;--------------------------------------------------------------------------------------------------

		include "sfx_routine.asm"

fx_data		incbin "sfx_data.bin"
	
sample_data	incbin "waves.bin"
end_of_sample_data	db 0

fx_list		dw fx_data, fx_data+$20, fx_data+$40, fx_data+$60 
		dw fx_data+$80, fx_data+$a0, fx_data+$b0


;--------------------------------------------------------------------------------------------------
; TITLE SCREEN CODE
;--------------------------------------------------------------------------------------------------

title_screen

	call title_screen_init
	
;---------------------------------------------------------------------------------------------------
	
ts_main_loop

	call kjt_wait_vrt
	call key_timer
	call tl_coords_to_sprites
	call tl_make_new_coords
	ld ix,tiles_colours
	ld iy,palette+(128*2)
	ld b,32
	ld a,(spr_palette_offset)
	call palette_adjust
	ld ix,tiles_colours
	ld iy,palette
	ld b,32
	ld a,(tile_palette_offset)
	call palette_adjust
	call get_rand

	call test_fire		; start game?
	jr z,nogstart
	call disable_video
	call setup_game_palette
	call clear_sprites
	call short_pause
	jp start_new_game
	
nogstart	ld a,(esc_keytime)		; quit to OS?
	or a
	jp nz,quit_tetris		

	jr ts_main_loop
		
;--------------------------------------------------------------------------------------------------	

title_screen_init
	
	call disable_video

	ld hl,palette
	ld bc,512
	xor a
	call kjt_bchl_memfill
	
	ld hl,sprite_registers+3
	exx
	ld ix,tetris_logo		;covert the logo pixels to coords
	ld iy,tl_src_coords
	ld c,0
tlclp2	ld b,0
tlclp1	ld a,(ix)
	or a
	jr z,nxtlp
	exx 
	ld de,ts_spdefs
	add a,e
	ld e,a
	jr nc,defmsbok
	inc d
defmsbok	ld a,(de)
	ld (hl),a			;store defintion in sprite register
	ld de,4
	add hl,de
	exx
	ld l,b
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,102
	add hl,de
	ld (iy),l
	ld (iy+1),h
	ld a,c
	sla a
	sla a
	sla a
	add a,64
	ld (iy+2),a
	ld de,4
	add iy,de
nxtlp	inc ix
	inc b
	ld a,b
	cp 48
	jr nz,tlclp1
	inc c
	ld a,c
	cp 7
	jr nz,tlclp2
	
	ld de,title_text_map		; write in text
	ld l,14
ttyok	ld h,0
ttxok	ld b,h
	ld c,l
	ld a,(de)
	push hl
	push de
	call plot_tile
	pop de
	pop hl
	inc de
	inc h
	ld a,h
	cp 40
	jr nz,ttxok
	inc l
	ld a,l
	cp 19
	jr nz,ttyok
		
	ld hl,sin_table			; upload sine table to math unit
	ld de,$0600
	ld bc,$200
	ldir	
		
	ld hl,$cd
	ld (tl_rad),hl
	
	ld a,$f1
	ld (spr_palette_offset),a
	ld (tile_palette_offset),a
	
	xor a
	ld (logo_up),a
	ld (ttxt_fade_in),a
	ld (esc_keytime),a
	
	call short_pause

	call enable_video
	ret

;--------------------------------------------------------------------------------------------------	
		
tl_make_new_coords

	ld hl,(tl_rad)		;adjust tetris logo coords (animation postions)
	ld (mult_write),hl
	
	ld ix,tl_src_coords
	ld iy,tl_dst_coords

	ld a,(tl_sin_base)
	ld c,a
	ld a,(tl_cos_base)
	ld b,a
	exx	
	ld b,127
mtlcolp	exx
	ld l,(ix)
	ld h,(ix+1)
	ld a,c
	ld (mult_index),a
	ld de,(mult_read)
	add hl,de
	ld de,(y_win_offset)
	add hl,de
	ld a,h
	cp 2
	jr c,sprok1
	ld h,2
sprok1	ld (iy),l
	ld (iy+1),h

	ld l,(ix+2)
	ld h,0
	ld a,b
	ld (mult_index),a
	ld de,(mult_read)
	add hl,de
	ld de,(y_win_offset)
	add hl,de
	ld a,h
	or a
	jr z,sprok2
	ld h,1
sprok2	ld (iy+2),l
	ld (iy+3),h
	
	ld de,4
	add ix,de
	add iy,de	
	ld a,c
	add a,7
	ld c,a
	ld a,b
	sub 5
	ld b,a
	exx
	djnz mtlcolp
	
	ld hl,(tl_rad)
	ld a,h
	or l
	jr z,radok
	ld de,4			; rad displacement speed
	xor a
	sbc hl,de
	jr z,endrp
	jr nc,radok
endrp	ld a,48
	ld (logo_up),a
	ld hl,0
radok	ld (tl_rad),hl
	
	ld a,(spr_palette_offset)
	or a
	jr z,ntspa
	inc a
	ld (spr_palette_offset),a	
	
ntspa	ld a,(logo_up)		;scroll title sprites up?
	or a
	jr z,nolsu
	dec a
	jr nz,nttfi
	ld hl,ttxt_fade_in
	ld (hl),1
nttfi	ld (logo_up),a
	cp 32
	jr nc,nolsu
	ld ix,tl_src_coords
	ld de,4
	ld b,127
sctlp	dec (ix+2)
	add ix,de
	djnz sctlp
	
nolsu	ld a,(ttxt_fade_in)
	or a
	ret z
	ld a,(tile_palette_offset)
	inc a
	ld (tile_palette_offset),a
	ret nz
	xor a
	ld (ttxt_fade_in),a	
	ret
	

;--------------------------------------------------------------------------------------------------

tl_coords_to_sprites

	ld ix,sprite_registers
	ld iy,tl_dst_coords
	ld b,127
tlctslp	ld l,(iy)
	ld h,(iy+1)
	ld e,(iy+2)
	ld d,(iy+3)
	ld (ix+0),l		;x lsb
	ld (ix+2),e		;y lsb
	sla d			
	ld a,h
	or d
	or $10
	ld (ix+1),a		;msbs etc
	ld de,4
	add iy,de
	add ix,de
	djnz tlctslp
	ret

;--------------------------------------------------------------------------------------------------

short_pause
	
	ld b,10
tswait	call kjt_wait_vrt
	djnz tswait
	ret
			
;--------------------------------------------------------------------------------------------------

tl_sin_base	db 43
tl_cos_base	db 233
tl_rad		dw $cc
tl_src_coords	ds 128*4,0	
tl_dst_coords	ds 128*4,0

tetris_logo	incbin "tetris_logo.bin"

ts_spdefs		db 0,$56,$73,$b4,$41,$45,$05,$a4

sin_table	   	incbin "sin_table.bin"

title_text_map	incbin "title_text.bin"

logo_up 		db 0
ttxt_fade_in	db 0
tile_palette_offset	db 0

;--------------------------------------------------------------------------------------------------


frame_counter	db 0
video_mode	db 0
y_win_offset	dw 0

game_over		db 0

seed		dw 1234

current_piece	db 0
next_piece	db 0
piece_x		db 0
piece_y		db 0
rotation		db 0
x_fine		db 0
y_fine		db $e0	; [7:5] = pixel position / [4:0] fractional part
go_left		db 0
go_right		db 0

fire_latch	db 0
spr_page		db 0

speed		db 0
rapidfall		db 0
new_block		db 0
tl_offset		dw 0
fall_time		db 0

spr_palette_offset	db 0
frag_flashtime	db 0
frag_explosion	db 0
wait_new_piece	db 0
fragofscount	db 0
explo_sel		db 0
ready_for_new_piece	db 0

score		db 0,0,0,0,0,0		;lowest digit first
hiscore		db 0,0,0,0,0,0
hs_filename	db "TET-HISC.BIN",0

add_one		db 1,0,0,0,0,0

line_bonus_1	db 0,0,1,0,0,0,0,0		; for a single line
line_bonus_2	db 0,0,3,0,0,0,0,0		; for a double line
line_bonus_3	db 0,0,6,0,0,0,0,0		; for a triple line
line_bonus_4	db 0,0,0,1,0,0,0,0		; for a tetris

lines		db 0,0,0
level		db 0,0,0
stats		dw 0,0,0,0,0,0,0

level_up_wait	db 0

lines_target	db 0,1,0
lines_inc		db 2,0,0

base_speed	db 0
speed_inc_count	db 0

up_keytime	db 0
down_keytime	db 0
left_keytime	db 0
right_keytime	db 0
esc_keytime	db 0
other_keytime	db 0

key_release	db 0

;-------------------------------------------------------------------------------------------------

frag_list	db 0,0,$1,$0, 1,0,$2,$0, 2,0,$3,$0, 1,-1,$2,$1	; T yellow
	db 1,1,$4,$0, 0,0,$3,$1, 1,0,$4,$1, 1,-1,$4,$2	; 90'
	db 1,1,$6,$0, 0,0,$5,$1, 1,0,$6,$1, 2,0,$7,$1	; 180'
	db 1,1,$0,$0, 1,0,$0,$1, 2,0,$1,$1, 1,-1,$0,$2	; 270'
	
	db 0,0,$1,$2, 1,0,$2,$2, 2,0,$3,$2, 0,-1,$1,$3	; L - d.blue
	db 0,1,$7,$0, 1,1,$8,$0, 1,0,$8,$1, 1,-1,$8,$2	; 90'
	db 2,1,$8,$7, 0,0,$6,$8, 1,0,$7,$8, 2,0,$8,$8	; 180'	
	db 1,1,$0,$3, 1,0,$0,$4, 1,-1,$0,$5, 2,-1,$1,$5	; 270'
	
	db 0,0,$2,$3, 1,0,$3,$3, 1,-1,$3,$4, 2,-1,$4,$4	; Squiggle Z - green
	db 2,1,$7,$2, 1,0,$6,$3, 2,0,$7,$3, 1,-1,$6,$4	; 90'
	db 0,0,$2,$3, 1,0,$3,$3, 1,-1,$3,$4, 2,-1,$4,$4	; 180'
	db 2,1,$7,$2, 1,0,$6,$3, 2,0,$7,$3, 1,-1,$6,$4	; 270'
		
	db 0,0,$0,$7, 1,0,$1,$7, 0,-1,$0,$8, 1,-1,$1,$8	; 2x2 Block - red
	db 0,0,$0,$7, 1,0,$1,$7, 0,-1,$0,$8, 1,-1,$1,$8	; 90'
	db 0,0,$0,$7, 1,0,$1,$7, 0,-1,$0,$8, 1,-1,$1,$8	; 180'
	db 0,0,$0,$7, 1,0,$1,$7, 0,-1,$0,$8, 1,-1,$1,$8	; 270'
		
	db 1,0,$5,$2, 2,0,$6,$2, 0,-1,$4,$3, 1,-1,$5,$3	; Squiggle - S - l blue
	db 1,1,$2,$4, 1,0,$2,$5, 2,0,$3,$5, 2,-1,$3,$6	; 90'
	db 1,0,$5,$2, 2,0,$6,$2, 0,-1,$4,$3, 1,-1,$5,$3	; 180'
	db 1,1,$2,$4, 1,0,$2,$5, 2,0,$3,$5, 2,-1,$3,$6	; 270'
	
	db 0,0,$0,$6, 1,0,$1,$6, 2,0,$2,$6, 2,-1,$2,$7	; Mirror L - maganta
	db 1,1,$7,$4, 1,0,$7,$5, 0,-1,$6,$6, 1,-1,$7,$6	; 90'	
	db 0,1,$5,$6, 0,0,$5,$7, 1,0,$6,$7, 2,0,$7,$7	; 180'
	db 1,1,$4,$5, 2,1,$5,$5, 1,0,$4,$6, 1,-1,$4,$7	; 270'
	
	db 0,0,$2,$8, 1,0,$3,$8, 2,0,$4,$8, 3,0,$5,$8	; Line -orange
	db 1,1,$8,$3, 1,0,$8,$4, 1,-1,$8,$5, 1,-2,$8,$6	; 90'
	db 0,0,$2,$8, 1,0,$3,$8, 2,0,$4,$8, 3,0,$5,$8	; 180'
	db 1,1,$8,$3, 1,0,$8,$4, 1,-1,$8,$5, 1,-2,$8,$6	; 270'

;---------------------------------------------------------------------------------------------

board_matrix	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;0
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;1
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;2 
			
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;3 - bottom of stack
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;4
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;5
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;6
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;7
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;8
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;9
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;10
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;11
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;12
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;13
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;14
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;15
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;16
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;17
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;18
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;19
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;20
		db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;21
bm_topline	db $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00 ;22  -top line of stack
		
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;23
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;24

;---------------------------------------------------------------------------------------------

explo_frags	ds 40*8,0

explo_xdisplist	db $14,$10,$0c,$08,$04,$fc,$f8,$f4,$f0,$ec

explo_ydisplist	db 3,5,7,2,6,7,4,3,5,1
		db 2,4,7,6,7,7,4,5,4,2
		db 4,3,6,3,7,5,6,4,2,0
		db 1,4,2,6,5,7,5,2,4,3


fixup_table_b	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $b2,$00,$b4,$00,$b3,$00,$b7,$00,$30,$00,$00,$00,$00,$00,$00,$00
		db $b4,$00,$00,$00,$b4,$00,$00,$00,$05,$00,$00,$00,$00,$00,$00,$00	
		db $00,$05,$00,$00,$00,$26,$00,$44,$00,$00,$00,$00,$00,$00,$00,$00
		db $30,$00,$00,$32,$00,$00,$41,$00,$38,$00,$00,$00,$00,$00,$00,$00
		db $86,$00,$34,$00,$00,$00,$00,$47,$38,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$45,$47,$00,$00,$77,$73,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$a4,$00,$a4,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $b0,$b1,$00,$00,$00,$00,$00,$00,$23,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$01,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00
	
fixup_table_a	db $b4,$00,$b7,$00,$b4,$00,$b4,$00,$23,$00,$00,$00,$00,$00,$00,$00
		db $b5,$00,$00,$00,$b6,$00,$00,$00,$31,$00,$00,$00,$00,$00,$00,$00
		db $00,$07,$00,$00,$00,$a7,$00,$41,$00,$00,$00,$00,$00,$00,$00,$00	
		db $05,$00,$00,$44,$00,$00,$32,$00,$73,$00,$00,$00,$00,$00,$00,$00
		db $31,$00,$45,$00,$00,$00,$00,$a4,$68,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$26,$60,$00,$00,$74,$68,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$77,$00,$74,$a4,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $b0,$b1,$00,$00,$00,$00,$00,$00,$05,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$01,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	
explo_fixup	db $b4,$b4,$b4,$b4,$b4,$05,$b4,$05,$05,$00,$00,$00,$00,$00,$00,$00
		db $b4,$b4,$b4,$b4,$b4,$b4,$b4,$b4,$05,$00,$00,$00,$00,$00,$00,$00
		db $b4,$05,$05,$05,$b4,$45,$45,$41,$05,$00,$00,$00,$00,$00,$00,$00
		db $05,$05,$41,$41,$45,$45,$41,$41,$73,$00,$00,$00,$00,$00,$00,$00
		db $05,$41,$45,$41,$41,$45,$41,$a4,$73,$00,$00,$00,$00,$00,$00,$00
		db $05,$05,$45,$45,$a4,$a4,$56,$a4,$73,$00,$00,$00,$00,$00,$00,$00
		db $a4,$a4,$a4,$45,$a4,$a4,$a4,$a4,$73,$00,$00,$00,$00,$00,$00,$00
		db $56,$56,$a4,$73,$a4,$a4,$a4,$a4,$05,$00,$00,$00,$00,$00,$00,$00
		db $56,$56,$73,$73,$73,$73,$05,$05,$05,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$a4,$41,$41,$45,$45,$00,$00,$00,$00,$00,$00,$00
		db $56,$56,$b4,$b4,$b4,$b4,$b4,$b4,$00,$00,$00,$00,$00,$00,$00,$00
		
next_piece_offsets	db 0,0,0,4,0,0,-4
			
;---------------------------------------------------------------------------------------------

y_line_offset_list	dw display_width*0,display_width*1,display_width*2,display_width*3
		dw display_width*4,display_width*5,display_width*6,display_width*7
		dw display_width*8,display_width*9,display_width*10,display_width*11
		dw display_width*12,display_width*13,display_width*14,display_width*15
		
		dw display_width*16,display_width*17,display_width*18,display_width*19
		dw display_width*20,display_width*21,display_width*22,display_width*23
		dw display_width*24,display_width*25,display_width*26,display_width*27
		dw display_width*28,display_width*29,display_width*30,display_width*31

		dw display_width*32,display_width*33,display_width*34,display_width*35
		dw display_width*36,display_width*37,display_width*38,display_width*39
		dw display_width*40,display_width*41,display_width*42,display_width*43
		dw display_width*44,display_width*45,display_width*46,display_width*47

		dw display_width*48,display_width*49,display_width*50,display_width*51
		dw display_width*52,display_width*53,display_width*54,display_width*55
		dw display_width*56,display_width*57,display_width*58,display_width*59
		dw display_width*60,display_width*61,display_width*62,display_width*63

solid_step	db 0
solid_count	db 0
solid_list	ds 8,0

;---------------------------------------------------------------------------------------------

tiles		incbin 	"tiles_chunky.bin"

tiles_colours	incbin	"tiles_palette.bin"

charmap		incbin	"map_screen.bin"

gameover_chars	db 47,57,57,57,57,57,57,58
		db 59,47,57,57,57,57,58,60
		db 59,59,79,73,94,77,60,60
		db 59,59,105,121,77,108,60,60
		db 59,61,62,62,62,62,63,60
		db 61,62,62,62,62,62,62,63

level_up_chars	db 47,57,57,57,57,57,57,57,57,58
		db 59,93,77,121,77,93,184,111,106,60
		db 61,62,62,62,62,62,62,62,62,63

		
;---------------------------------------------------------------------------------------------

display_y_list	ds (display_height/8)*2,0	;holds y CHARACTER line offsets / 2

;-----------------------------------------------------------------------------------------------