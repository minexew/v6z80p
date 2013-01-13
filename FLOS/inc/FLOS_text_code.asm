;-----------------------------------------------------------------------------------------------

os_get_display_size

		ld b,OS_window_cols
		ld c,OS_window_rows
		ret

;-----------------------------------------------------------------------------------

os_cursor_x_home
	
		xor a
		ld (cursor_x),a
		ret

;-----------------------------------------------------------------------------------

os_redraw_line

		call mult_cursor_y_window_cols		;returns y * OS columns in HL
		ex de,hl
		ld a,(cursor_y)
		ld c,a
		call redraw_ui_line
		ret
		
;-----------------------------------------------------------------------------------

os_new_line_cond

		call test_quiet_mode
		ret nz

	
os_new_line

		push hl
		ld hl,crlfx2_txt+1
		call os_print_string
		pop hl
		ret
	
	
os_print_str_new_line

		call os_print_string
		jr os_new_line



show_packed_text_and_cr

		call os_show_packed_text
		jr os_new_line


os_print_multiple_chars

pmch_lp		ld a,c
		call os_print_char
		djnz pmch_lp
		ret
	
	
os_print_char_cond

		call test_quiet_mode
		ret nz
			
os_print_char

		push hl
		ld hl,rep_char_txt
		ld (hl),a
		call os_print_string
		pop hl
		ret
			

;-----------------------------------------------------------------------------------


os_set_cursor_position

		push de				; if either coordinate is out of range
		ld e,0					; it will be set at zero and the routine
		ld a,b					; returns with zero flag not set
		cp OS_window_cols
		jr c,xposok
		inc e
		xor a
xposok		ld (cursor_x),a
		ld a,c
		cp OS_window_rows
		jr c,yposok
		inc e
		xor a
yposok		ld (cursor_y),a
		ld a,e
		pop de
		or a
		ret
			
	
	
os_get_cursor_position

		ld bc,(cursor_y)			; returns pos in bc (b = x, c = y)
		ret




os_get_charmap_xy
		
		push de
		push af	

		ld h,0					; multiply charpos_y by 40
		ld d,h
		ld a,c
		rlca
		rlca
		rlca
		ld e,a
		ld l,a
		add hl,hl
		add hl,hl
		add hl,de	
		ld e,b					; add on charpos_x
		add hl,de
		ex de,hl				; de = charmap offset
		ld hl,OS_charmap
		add hl,de
		
		pop af
		pop de
		ret
			

;---------------------------------------------------------------------------------------------


os_show_packed_text_cond

		call test_quiet_mode
		ret nz

	
os_show_packed_text

; Construct sentence from internal dictionary using word indexes from HL
	
		push bc
		push de
		push ix
		ld ix,output_line
		dec hl
readpindex	inc hl
		call getiword
		ld a,(hl)
		and $80
		jr z,readpindex				;if word index = 0, its the end of the line
		dec ix					;remove previously added space from end of line
		ld (ix),0				;null terminate output line
		call os_print_output_line		;HL push+popped around by routine
		pop ix
		pop de
		pop bc
		xor a					;A = 0, ZF set on exit
		ret

		
getiword	ld b,(hl)
		res 7,b
		ld de,dictionary-1
		ld c,0
dictloop	inc de
		ld a,(de)
		or a					;loop until marker byte ($80+) found (or end of dictionary = $00)
		jr z,end_dict
		jp p,dictloop	
		inc c					;reached desired word count?
		ld a,c
		cp b
		jr nz,dictloop

		ld a,(de)				;if marker byte $80-$a0, this is a command ID, skip it
		and $7f
		cp $20
		jr nc,not_cmd_id
copytol		inc de					;skip the marker char
		ld a,(de)
		or a
		jp m,eoword				;if find another marker char, it's the end of the word

not_cmd_id	cp $7f
		jr nz,not_lfcr				;test for special case $7F = <LF+CR>
		ld a,11
not_lfcr	ld (ix),a				;copy char to output line
		inc ix
		jr copytol
		
eoword		ld (ix),32				;add a space after the word	
		inc ix
end_dict	ret
		

;-----------------------------------------------------------------------------------
