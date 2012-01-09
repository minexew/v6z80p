;-----------------------------------------------------------------------
; "dir" - show directory command. v6.06
;-----------------------------------------------------------------------

os_cmd_dir

	call kjt_check_volume_format	
	ret nz
	
	call div_line
	call os_get_current_dir_name		;show dir name
	ret nz
	call os_print_string
	call fs_get_dir_block		;if at root also show volume label
	ld a,d
	or e
	jr nz,dcmdnr
	call fs_get_volume_label
	call os_print_string
dcmdnr	call os_new_line
	
nrootdir	call div_line
	call os_goto_first_dir_entry
	jr nz,os_dlr
	xor a
	ld (os_linecount),a
	
os_dfllp	call os_get_dir_entry		;line list loop starts here
	jr nz,os_dlr			;end of dir?
	push bc
	call os_print_string		;show filename
	call os_get_cursor_position		;move cursor to x = 20
	ld b,14
	call os_set_cursor_position	
	pop bc
	bit 0,b				;is this entry a file?
	jr z,os_deif		
	ld hl,dir_txt			;write [dir] next to name
	jr os_dpl
	
os_deif	ld hl,os_hex_prefix_txt		;its a file - write length next to name
	call os_print_string
	ld hl,output_line
	push hl
	push ix
	pop de
	call hexword_to_ascii
	push iy
	pop de
	call hexword_to_ascii
	ld (hl),0
	pop hl
	ld b,7				;skip only 7 out of 8 hex digits
	call os_skip_leading_ascii_zeros
os_dpl	call os_print_string
	call os_new_line
	
	call os_goto_next_dir_entry
	jr nz,os_dlr			;end of dir?
	call os_count_lines
	ld a,"y"
	cp b
	jr z,os_dfllp
	
os_dlr	call div_line			;now show remaining disk space
	call os_calc_free_space		;hl:de = free space in kb
	ret nz	

	ld c,"K"				;if > 1024KB, show as MB
dir_getr	ld a,d
	and $c0
	or h
	or l
	jr z,dir_gotr
	ld b,10
dir_rlp1	srl h
	rr l
	rr d
	rr e
	djnz dir_rlp1
	ld c,"M"
	
dir_gotr	ld a,c
	ld (xb_spare_txt),a
	ex de,hl
	call os_print_decimal

	ld hl,xb_spare_txt
	call os_print_string
	xor a
	ret

;-----------------------------------------------------------------------

div_line	ld bc,$132d			;2d = "-"
	call os_print_multiple_chars
	call os_new_line
	ret

;-----------------------------------------------------------------------

	