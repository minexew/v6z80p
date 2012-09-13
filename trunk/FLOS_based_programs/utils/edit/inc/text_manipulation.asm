;-----------------------------------------------------------------------------------------------------------------


column_offset_adj


	call locate_cursor
	ld c,0
coladjlp	cp win_x_size
	jr c,coladjok
	sub 8
	inc c
	jr coladjlp
	
coladjok	ld (cursor_x),a
	sla c
	sla c
	sla c
	ld a,(column_offset)
	cp c
	ret z
	ld a,c
	ld (column_offset),a
	call show_text_page			;redraw if column offset has changed
	ret
	


column_offset_adj_lr


	call locate_cursor
	ld c,a
	ld a,(column_offset)
	cp c
	jr z,cl_ok2
	jr c,cl_ok2
cl_adj	sub 8
	cp c
	jr z,cl_ok1
	jr nc,cl_adj
cl_ok1	ld (column_offset),a
	push bc
	call show_text_page
	pop bc
cl_ok2	ld a,(column_offset)
	sub c
	neg
	ld (cursor_x),a	
	ret



column_offset_adj_rl
	
	call locate_cursor
	ld c,a
	ld a,(column_offset)
	add a,win_x_size-1
	cp c
	jp nc,cr_cpok

cr_adjlp	ld a,(column_offset)
	add a,8
	ld (column_offset),a
	add a,win_x_size
	cp c
	jp c,cr_adjlp
	push bc
	call show_text_page
	pop bc
	
cr_cpok	ld a,(column_offset)
	ld b,a
	ld a,c
	sub b
	ld (cursor_x),a
	ret


;-----------------------------------------------------------------------------------------------------------------

find_line_end

	ld hl,work_buffer
	ld a,(cursor_y)
	add a,h
	ld h,a
fle_fbr	ld a,(hl)				
	or a
	ret z
	cp 11
	ret z
	inc l
	jr fle_fbr

;-----------------------------------------------------------------------------------------------------------------


get_char_addr

	ld hl,work_buffer
	ld a,(cursor_y)
	add a,h
	ld h,a
	ld a,(char_pos)
	ld l,a
	ret
	

;-------------------------------------------------------------------------------------------------------------------


test_line_length
	
	ld hl,work_buffer		;returns length in C (tabs count as multiple spaces)
	ld a,(cursor_y)		;also ZF set if below $f7
	add a,h
	ld h,a
	ld c,0
tll_loop	ld a,(hl)
	inc l
	cp 11
	jr z,tll_got
	or a
	jr z,tll_got
	cp 9
	jr z,tll_tab
	inc c
	ld a,c
	cp $f7
	jr c,tll_loop
tll_bad	ld a,1
	or a
	ret
	
tll_tab	ld a,c
	and $f8
	add a,8
	jr c,tll_bad
	ld c,a
	jr tll_loop
	ret

tll_got	xor a
	ret
	
;--------------------------------------------------------------------------------------------------------------------

locate_cursor

	push hl
	ld hl,work_buffer
	ld a,(cursor_y)
	add a,h
	ld h,a
	
	ld a,(char_pos)
	or a
	jr nz,lc_neol
	ld e,11
	pop hl
	ret
	
lc_neol	ld b,a			
	ld c,0			;char count
lc_loop	ld a,(hl)
	inc l
	or a
	jr z,lc_eol
	cp 9
	jr nz,lc_ntab
	ld a,c
	and $f8
	add a,8
	ld c,a
	djnz lc_loop
	jr lc_eol
lc_ntab	inc c
	djnz lc_loop
lc_eol	ld a,c
lc_done	ld e,(hl)			;returns character count x location (absolute: not offset adjusted) in A
	pop hl			;returns char at cursor in E
	ret
	
	
	


relocate_cursor

	push hl			;put cursor x at appropriate position on the new line
	push bc
	ld hl,work_buffer
	ld a,(cursor_y)
	add a,h
	ld h,a

	ld a,(cursor_x)	
	ld b,a
	ld a,(column_offset)
	add a,b
	ld b,a
	ld c,0

rlc_loop	ld a,c
	cp b
	jr nc,rlc_done
	ld a,(hl)
	cp 11
	jr z,rlc_done
	inc l
	cp 9
	jr z,rlc_tab
	inc c
	jr rlc_loop
rlc_tab	ld a,c
	and $f8
	add a,8
	ld c,a
	jr rlc_loop
	
rlc_done	ld a,l
	ld (char_pos),a
	call locate_cursor
	call column_offset_adj

rlc_end	pop bc
	pop hl
	ret
	

	
;------------------------------------------------------------------------------------------------

update_text_file

;This stitches the text in the collapsed work buffer (at vram 0) back into the main text file
	
	call rebuild_main
	call make_work_buffer
	call show_text_page
	ret
	
	
rebuild_main
	
	ld a,(rebuild_flag)
	or a
	ret z

;	ld hl,$f0f
;	ld (palette),hl

	ld b,win_y_size			;deflate all lines in editor window
	ld hl,work_buffer
	ld de,$2000
	call deflate_lines
	ld a,d
	sub $20
	ld d,a				;de = length of deflated workbuffer text
	ld (deflated_wb_size),de
	

rebuild_text_file

;	ld hl,$f00
;	ld (palette),hl
	
	xor a
	ld (rebuild_flag),a
	
	ld hl,(textfile_wb_start_loc)		;make space for the new section of text (or if
	ld a,(textfile_wb_start_loc+2)	;shorter, collapse the text file)
	ld de,(deflated_wb_size)
	add hl,de
	adc a,0
	ld (blit_dest),hl
	ld (blit_dest+2),a
	
	ld de,(textfile_wb_end_loc)
	ld a,(textfile_wb_end_loc+2)
	ld (blit_source),de
	ld (blit_source+2),a
	ld c,a
	
	ld hl,(vram_text_end)
	ld a,(vram_text_end+2)
	or a
	sbc hl,de
	sbc a,c
	ld (blit_size),hl
	ld (blit_size+2),a
	
	ld c,a				;update end_of_text_file pointer (blit_dest+blit_size)
	ld de,(blit_dest)
	ld a,(blit_dest+2)
	add hl,de
	adc a,c
	ld (vram_text_end),hl		
	ld (vram_text_end+2),a
	call ahl_flat_to_vram_paged		;put zero at end of text file in VRAM
	ld (vreg_vidpage),a
	call kjt_page_in_video
	ld (hl),0
	call kjt_page_out_video
	
	call move_vram_data
	
	ld hl,0				;now copy over the text from the deflated text buffer
	ld a,0
	ld (blit_source),hl
	ld (blit_source+2),a
	
	ld hl,(textfile_wb_start_loc)
	ld a,(textfile_wb_start_loc+2)
	ld (blit_dest),hl
	ld (blit_dest+2),a
	
	ld hl,(deflated_wb_size)
	xor a
	ld (blit_size),hl
	ld (blit_size+2),a
	
	call move_vram_data
	
;	ld hl,$0
;	ld (palette),hl
	ret
	
;------------------------------------------------------------------------------------------------


deflate_lines
	
	xor a				;deflate the work buffer to start of VRAM
	ld (vreg_vidpage),a
	call kjt_page_in_video
	
rb_lp1	ld a,(hl)				;lines in work buffer end in 11 (or 0 if last line)
	cp 11
	jr z,rb_eol
	or a				;0 = EOF
	jr z,rb_end
	ld (de),a
	inc de
	inc l
	jr nz,rb_lp1
	
rb_eol	ld a,13				;end each line with CR+LF
	ld (de),a
	inc de
	ld a,10
	ld (de),a
	inc de
	
	inc h
	ld l,0
	djnz rb_lp1
	
rb_end	call kjt_page_out_video
	ret



	
deflated_wb_size	dw 0


;------------------------------------------------------------------------------------------------

;set up blit_source, blit_dest and blit_size prior to calling


move_vram_data
	
	ld a,(blit_size+2)
	cp 6
	jr c,bs_ok
	
	ld hl,$f00			;if blit size > $60000, there was an error
	ld (palette),hl
	ld b,25
vrtlp1	call kjt_wait_vrt
	djnz vrtlp1
	ld hl,0
	ld (palette),hl
	xor a
	inc a 
	ret
	
bs_ok	xor a 	
	ld (blit_src_mod),a			;modulos not used
	ld (blit_dst_mod),a

	ld de,(blit_dest)			;is destination higher in VRAM than source?
	ld a,(blit_dest+2)			;if so, do a descending blit
	ld c,a
	ld hl,(blit_source)
	ld a,(blit_source+2)
	or a
	sbc hl,de
	sbc a,c
	jp c,do_descending_blit
	

do_ascending_blit


	ld a,%01000000			;set blitter to ascending mode (modulo 
	ld (blit_misc),a			;high bits set to zero, transparency: off)

big_blit_loop

	ld a,(blit_size+2)			;blit size MSB - any 64KB chunks?
	or a
	jr z,no_big_chunks
	
	ld a,(blit_source+2)		;blit source MSB
	ld hl,(blit_source)			;blit source LSW
	ld (blit_src_loc),hl		;set source address lsw
	ld (blit_src_msb),a			;set source address msb
	
	ld a,(blit_dest+2)			;blit dest MSB
	ld hl,(blit_dest)			;blit dest LSB
	ld (blit_dst_loc),hl		;set dest address lsw
	ld (blit_dst_msb),a			;set dest address msb

	ld a,255
	ld (blit_height),a			
	ld (blit_width),a			;start 64KB blit

	ld hl,blit_source+2			;update locations and size
	inc (hl)
	ld hl,blit_dest+2
	inc (hl)
	ld hl,blit_size+2
	dec (hl)	

	call wait_blit
	jr big_blit_loop

no_big_chunks

	ld a,(blit_size+1)
	or a
	jr z,no_page_chunks
	
	ld a,(blit_source+2)		;blit source MSB
	ld hl,(blit_source)			;blit source LSW
	ld (blit_src_loc),hl		;set source address lsw
	ld (blit_src_msb),a			;set source address msb
	
	ld a,(blit_dest+2)			;blit dest MSB
	ld hl,(blit_dest)			;blit dest LSB
	ld (blit_dst_loc),hl		;set dest address lsw
	ld (blit_dst_msb),a			;set dest address msb

	ld a,(blit_size+1)
	dec a
	ld (blit_height),a			
	ld a,255
	ld (blit_width),a			;do n page blit

	ld de,(blit_size)			;update locations and size
	ld e,0
	ld hl,(blit_source)
	ld a,(blit_source+2)
	add hl,de
	adc a,0
	ld (blit_source),hl
	ld (blit_source+2),a
	
	ld hl,(blit_dest)
	ld a,(blit_dest+2)
	add hl,de
	adc a,0
	ld (blit_dest),hl
	ld (blit_dest+2),a
	
	call wait_blit
	
no_page_chunks

	ld a,(blit_size)			;remaining bytes 
	or a
	ret z
	
	ld a,(blit_source+2)		;blit source MSB
	ld hl,(blit_source)			;blit source LSW
	ld (blit_src_loc),hl		;set source address lsw
	ld (blit_src_msb),a			;set source address msb
	
	ld a,(blit_dest+2)			;blit dest MSB
	ld hl,(blit_dest)			;blit dest LSB
	ld (blit_dst_loc),hl		;set dest address lsw
	ld (blit_dst_msb),a			;set dest address msb

	xor a
	ld (blit_height),a			
	ld a,(blit_size)
	dec a
	ld (blit_width),a			;do n byte blit

	call wait_blit
	xor a
	ret




do_descending_blit

	ld a,(blit_size+2)			;move source and dest to last byte of blit
	ld hl,(blit_size)			;because blit is in descending mode
	ld de,1
	or a
	sbc hl,de
	sbc a,0
	ex de,hl
	ld c,a
	
	ld hl,(blit_source)
	ld a,(blit_source+2)
	add hl,de
	adc a,c
	ld (blit_source),hl
	ld (blit_source+2),a
	
	ld hl,(blit_dest)
	ld a,(blit_dest+2)
	add hl,de
	adc a,c
	ld (blit_dest),hl
	ld (blit_dest+2),a

	ld a,%00000000			;set blitter to descending mode (modulo 
	ld (blit_misc),a			;high bits set to zero, transparency: off)

d_big_blit_loop

	ld a,(blit_size+2)			;blit size MSB - any 64KB chunks?
	or a
	jr z,d_no_big_chunks
	
	ld a,(blit_source+2)		;blit source MSB
	ld hl,(blit_source)			;blit source LSW
	ld (blit_src_loc),hl		;set source address lsw
	ld (blit_src_msb),a			;set source address msb
	
	ld a,(blit_dest+2)			;blit dest MSB
	ld hl,(blit_dest)			;blit dest LSB
	ld (blit_dst_loc),hl		;set dest address lsw
	ld (blit_dst_msb),a			;set dest address msb

	ld a,255
	ld (blit_height),a			
	ld (blit_width),a			;start 64KB blit

	ld hl,blit_source+2			;update locations and size
	dec (hl)
	ld hl,blit_dest+2
	dec (hl)
	ld hl,blit_size+2
	dec (hl)	

	call wait_blit
	jr d_big_blit_loop

d_no_big_chunks

	ld a,(blit_size+1)
	or a
	jr z,d_no_page_chunks
	
	ld a,(blit_source+2)		;blit source MSB
	ld hl,(blit_source)			;blit source LSW
	ld (blit_src_loc),hl		;set source address lsw
	ld (blit_src_msb),a			;set source address msb
	
	ld a,(blit_dest+2)			;blit dest MSB
	ld hl,(blit_dest)			;blit dest LSB
	ld (blit_dst_loc),hl		;set dest address lsw
	ld (blit_dst_msb),a			;set dest address msb

	ld a,(blit_size+1)
	dec a
	ld (blit_height),a			
	ld a,255
	ld (blit_width),a			;do n page blit

	ld de,(blit_size)			;update locations and size
	ld e,0
	ld hl,(blit_source)
	ld a,(blit_source+2)
	or a
	sbc hl,de
	sbc a,0
	ld (blit_source),hl
	ld (blit_source+2),a
	
	ld hl,(blit_dest)
	ld a,(blit_dest+2)
	or a
	sbc hl,de
	sbc a,0
	ld (blit_dest),hl
	ld (blit_dest+2),a
	
	call wait_blit
	
d_no_page_chunks

	ld a,(blit_size)			;remaining bytes 
	or a
	ret z
	
	ld a,(blit_source+2)		;blit source MSB
	ld hl,(blit_source)			;blit source LSW
	ld (blit_src_loc),hl		;set source address lsw
	ld (blit_src_msb),a			;set source address msb
	
	ld a,(blit_dest+2)			;blit dest MSB
	ld hl,(blit_dest)			;blit dest LSB
	ld (blit_dst_loc),hl		;set dest address lsw
	ld (blit_dst_msb),a			;set dest address msb

	xor a
	ld (blit_height),a			
	ld a,(blit_size)
	dec a
	ld (blit_width),a			;do n byte blit

	call wait_blit
	xor a
	ret



					
wait_blit	in a,(sys_vreg_read)		
	bit 4,a 				;busy wait for blit to complete
	jr nz,wait_blit
	ret
	
	
blit_source	db 0,0,0
blit_dest		db 0,0,0
blit_size		db 0,0,0
	
;-----------------------------------------------------------------------------------------------


show_text_page
	
;	ld hl,$333		;TESTING
;	ld (palette),hl		;TESTING
	
	ld hl,work_buffer		;puts window of work buffer on screen
	ld c,0

stp_llp	ld l,0
	call draw_line
	ret nz
	
	inc h
	inc c
	ld a,c
	cp win_y_size
	jr c,stp_llp
	
;	ld hl,0			;TESTING
;	ld (palette),hl		;TESTING
		
	xor a
	ret



draw_line	

;Takes line from work buffer, 'renders' (expands tabs) it and puts the a section of resulting char line

;c = cursor y pos
;hl = work buffer addr

	ld de,wb_temp_line		;build entire line in temp line buffer
tl_mktl	ld a,(hl)
	cp 32
	jr c,tl_spec		;special_char? (below 32)
tl_ntab	ld (de),a
	inc e
	jr z,ltl_err1
tl_nsch	inc l
	jr nz,tl_mktl	
ltl_err1	ld a,$fd			;$fd = line too long error
	or a
	ret
	
tl_spec	cp 11			
	jr z,tl_done		;'next line' byte?
	or a
	jr z,tl_done		;end byte?
	cp 9
	jr nz,tl_ntab		;tab char?
	ld a,e
	and $f8
	add a,8			;a = plot pos after tab
	ld b,a			;b = number of spaces to plot for tab
tl_tablp	ld a,32
	ld (de),a
	inc e
	jr z,ltl_err1
	ld a,e
	cp b
	jr nz,tl_tablp
	jr tl_nsch

tl_done	xor a
	ld (de),a
	
	ld de,wb_temp_line		;now put a section of the temp line on screen
	ld a,(column_offset)	;scan rendered line to column offset, if 0 encountered - draw a blank line
	ld b,a
	or a
	jr z,dl_loop

tl_clptst	ld a,(de)
	or a
	jr z,dl_blank_line
	inc e
	djnz tl_clptst
		
	ld b,0
dl_loop	call kjt_set_cursor_position
	ld a,(de)
	or a
	jr z,dl_rest_spc
	call kjt_plot_char
	inc e
	inc b
	ld a,b
	cp win_x_size
	jp nz,dl_loop
	xor a
	ret

dl_blank_line

	ld b,0
	
dl_rest_spc

	ld a,32
	call kjt_plot_char
	inc b
	ld a,b
	cp win_x_size
	jp nz,dl_rest_spc
	xor a
	ret
	

	
column_offset db 0			;in multiples of 8 (tab size) only - for simplicity

;-----------------------------------------------------------------------------------------------

go_line_number

; Set HL to line number required
	
	ld a,1
	ld (page_step),a
	
	xor a
	ld (cursor_x),a
	ld (column_offset),a
	ld (char_pos),a
	
	push hl
	call rebuild_main
	
	ld hl,0				;set work buffer pos at start
	ld a,2
	ld (textfile_wb_start_loc),hl
	ld (textfile_wb_start_loc+2),a	
	ld hl,1				;first line = 1
	ld (line_position),hl
	xor a
	ld (cursor_y),a
	pop hl
	dec hl
	ld (line_countdown),hl		;line 1 at start (nothing to do)
	ld a,h
	or l
	jr z,gl_done
	
	call gotoline_main
	ret nz
		
gl_eofok	ld b,win_y_size/2
gl_adjlp	push bc
	call pgup_prev_line
	pop bc
	jr nz,gl_nopl
	djnz gl_adjlp
gl_nopl	ld a,win_y_size/2
	sub b
	ld (cursor_y),a
		
gl_done	call make_work_buffer
	call show_text_page
	xor a
	ret
	
gotoline_main	

		
	call kjt_page_in_video
	ld e,16
	ld hl,$2000
		
gl_nvp	ld a,e
	ld (vreg_vidpage),a
					;IE: video_ram_window
gl_fnl1	ld a,(hl)
	or a
	jr z,gl_end_of_text
	cp 13
	jr z,gl_got_cr
	cp 10
	jr z,gl_got_lf
gl_nchr	inc l
	jr nz,gl_fnl1
	inc h
	bit 6,h				;end of current video page?
	jr z,gl_fnl1
	inc e
	ld hl,$2000
	jr gl_nvp

gl_got_cr	inc hl				;assuming LF follows
	bit 6,h
	call nz,gl_nxt_vp

gl_got_lf	inc hl				;skip the LF for first char of new line
	bit 6,h
	call nz,gl_nxt_vp
	
	ld bc,(line_position)
	inc bc
	ld (line_position),bc
	ld bc,(line_countdown)
	dec bc
	ld (line_countdown),bc
	ld a,b
	or c
	jr nz,gl_nchr
	jr line_done			;success!
	
gl_nxt_vp	inc e
	ld a,e
	ld (vreg_vidpage),a
	ld hl,$2000			;IE: video_ram_window
	ret


gl_end_of_text
	
	ld hl,1				;go back to first line and quit
	ld (line_position),hl
	jr line_bad			;reached end of file before line number			


;------------------------------------------------------------------------------------------------

pgup_prev_line
	
	ld a,1
	jr preln_go			;for "page up" where display update isnt required each line
	
previous_line

	xor a
preln_go	ld (page_step),a
	call rebuild_main

	call kjt_page_in_video
	ld hl,(textfile_wb_start_loc)
	ld a,(textfile_wb_start_loc+2)
	call ahl_flat_to_vram_paged
	ld e,a
	ld (vreg_vidpage),a
			
pl_loop	call dec_vram_addr			;find previous LF
	jr nz,line_bad
	ld a,(hl)
	cp 10
	jp nz,pl_loop
pl_loop2	call dec_vram_addr			;find LF before that (if addr error, we are at start of file)
	jr nz,pl_top
	ld a,(hl)
	cp 10
	jr nz,pl_loop2
	call inc_vram_addr			;char after is the first char of the line 
pl_top	ld bc,(line_position)
	dec bc
	ld (line_position),bc

line_done	ld a,e
	call paged_vram_to_flat
	ld (textfile_wb_start_loc),hl
	ld (textfile_wb_start_loc+2),a	
	xor a

line_quit	push af
	call kjt_page_out_video
	ld a,(page_step)
	or a
	jr nz,l_skp_upd
	call make_work_buffer
	call show_text_page
l_skp_upd	pop af
	ret
	
line_bad	xor a
	inc a
	jr line_quit
	
	
	
;------------------------------------------------------------------------------------------------------------------

pgdown_next_line
	
	ld a,1
	jr nxtln_go		;for "page down" where display update isnt required each line

next_line	
	
	xor a
nxtln_go	ld (page_step),a
	call rebuild_main

	call kjt_page_in_video
	ld hl,(textfile_wb_start_loc)
	ld a,(textfile_wb_start_loc+2)	
	call ahl_flat_to_vram_paged
	ld e,a
	ld (vreg_vidpage),a
		
nl_loop	ld a,(hl)			;find LF or EOF
	or a
	jr z,line_bad
	cp 10
	jr z,nl_lf
	
	call inc_vram_addr		;next addr
	jr nz,line_bad
	jr nl_loop
	
nl_lf	call inc_vram_addr		;next char is first char of new line
	jr nz,line_bad
	ld a,(hl)
	or a
	jr z,line_bad
	
	ld bc,(line_position)
	inc bc
	ld (line_position),bc
	
	jr line_done	


page_step	db 0

;------------------------------------------------------------------------------------------------------------------


		
dec_vram_addr

	dec hl
	ld a,h
	cp $1f
	jr nz,dvaok
	ld h,$3f
	dec e
	ld a,e
	ld (vreg_vidpage),a
	cp 16
	jr nc,dvaok
	ld a,16
	ld (vreg_vidpage),a
	ld e,a
	ld hl,$2000		;prevent underflow and return start of buffer error
	xor a
	inc a
	ret

dvaok	xor a
	ret
	




inc_vram_addr

	inc hl
	ld a,h
	cp $40
	jr nz,ivaok
	ld h,$20
	inc e
	ld a,e
	ld (vreg_vidpage),a
	cp 64
	jr c,ivaok
	ld a,64
	ld (vreg_vidpage),a		;prevent overflow and return end of buffer error
	ld e,a
	ld hl,$3fff
	xor a
	inc a 
	ret

ivaok	xor a
	ret
	



ahl_flat_to_vram_paged

	push bc
	ld b,a			;converts linear A:HL address to vidpage (A), $2000-$3fff range (HL)
	ld c,h
	ld a,h
	and $1f
	add a,$20
	ld h,a
	sla c
	rl b
	sla c
	rl b
	sla c
	rl b
	ld a,b			; a = page number / hl = $2000-$3fff
	pop bc
	ret

	
	
paged_vram_to_flat

	push bc
	ld b,a			;converts Vidpage [A] + $2000-$3fff [HL] to A:HL linear VRAM address
	ld c,0			
	srl b
	rr c
	srl b
	rr c
	srl b
	rr c
	ld a,h
	and $1f
	or c
	ld h,a
	ld a,b
	pop bc
	ret


;-----------------------------------------------------------------------------------------------


make_work_buffer

	
;	ld hl,$440
;	ld (palette),hl

	call kjt_page_in_video	;create work buffer in sysram from selected line in VRAM
	
	ld hl,(textfile_wb_start_loc)
	ld a,(textfile_wb_start_loc+2)	
	call ahl_flat_to_vram_paged
	ld (mwb_vp_temp),a
	ld (vreg_vidpage),a
	
	ld c,win_y_size
	ld de,work_buffer
mwb_nllp	ld b,254
mwb_arlp	ld a,(hl)
	or a
	jr z,mwb_eof		;EOF?
	cp 13
	jr z,mwb_eolcr		;CR?
	cp 10
	jr z,mwb_eollf		;LF?
	ld (de),a
	inc e
	inc hl
	bit 6,h			;end of video page?
	call nz,mwb_next_vp
	djnz mwb_arlp
	jr mwb_tline		;line is too long, make new line
		
mwb_eolcr	inc hl			;char after CR at (HL) should now be a LF
	bit 6,h			
	call nz,mwb_next_vp
		
mwb_eollf	inc hl			;skip the LF for first valid char of new line
	bit 6,h			
	call nz,mwb_next_vp
	
mwb_tline	ld a,11
	ld (de),a			;terminate each line of work buffer with 11
	ld e,0
	inc d
	dec c			;do next line of work buffer
	jr nz,mwb_nllp
	
mwb_done	ld a,(mwb_vp_temp)
	call paged_vram_to_flat	;note end position of area copied to work buffer
	ld (textfile_wb_end_loc),hl
	ld (textfile_wb_end_loc+2),a
	call kjt_page_out_video
	
;	ld hl,0
;	ld (palette),hl
	
	xor a
	ret



mwb_eof	xor a			;terminate this line (and start of rest of wb lines) with zero
	ld (de),a
	ld e,0
	inc d
	dec c
	jr nz,mwb_eof
	ld a,(mwb_vp_temp)
	call paged_vram_to_flat	;note end position of area copied to work buffer
	ld (textfile_wb_end_loc),hl
	ld (textfile_wb_end_loc+2),a
	call kjt_page_out_video
	xor a
	inc a
	ret


mwb_next_vp

	ld a,(mwb_vp_temp)
	inc a
	ld (mwb_vp_temp),a
	ld (vreg_vidpage),a
	ld hl,$2000		;IE: video_ram_window
	ret
	
	
mwb_vp_temp

	db 0


;-----------------------------------------------------------------------------------------------

goto_line			dw 0

line_position		dw 0

char_pos			db 0			;index in work buffer text line
	
rebuild_flag		db 0

line_countdown 		dw 0

textfile_wb_start_loc	db 0,0,0			;the address in VRAM from where the work buffer was taken
textfile_wb_end_loc		db 0,0,0			;the address in VRAM where the work buffer ends (+1)
vram_text_end		db 0,0,0			;the address in VRAM where the main TEXT buffer ends
work_buffer_source_size	db 0,0,0	

;------------------------------------------------------------------------------------------------

