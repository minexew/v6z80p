;-----------------------------------------------------------------------
; "dir" - show directory command. v6.09
;-----------------------------------------------------------------------


os_cmd_dir	call kjt_check_volume_format	
		ret nz
		
		ld a,(hl)
		or a
		jr z,dir_no_args

		call cd_parse_path			;if DIR has args, interpret as path
		ret nz
		call dir_no_args
		jp cd_restore_vol_dir			;no point calling as routine
	
	

dir_no_args	call div_line
		call os_get_current_dir_name		;show dir name
		ret nz
		call os_print_string
		call fs_get_dir_block			;if at root also show volume label
		ld a,d
		or e
		call z,show_vol_label

		call os_new_line
	
nrootdir	call div_line
		call os_goto_first_dir_entry
		jr nz,os_dlr
		ld a,2
		ld (os_linecount),a
	
os_dfllp	call os_get_dir_entry			;line list loop starts here
		jr nz,os_dlr				;end of dir?
		push bc
		call os_print_string			;show filename
		call os_get_cursor_position		;move cursor to x = 20
		ld b,14
		call os_set_cursor_position	
		pop bc
		bit 0,b					;is this entry a file?
		jr z,os_deif		
		ld hl,dir_txt				;write [dir] next to name
		jr os_dpl
	
os_deif		ld (filesize_cache_msw),ix
		ld (filesize_cache_lsw),iy
		call print_filesize	

os_dpl		call os_print_string
		call os_new_line
	
		call os_goto_next_dir_entry
		jr nz,os_dlr				;end of dir?
		call os_count_lines
		ld a,"y"
		cp b
		jr z,os_dfllp
	
os_dlr		call div_line				;now show remaining disk space
		call os_calc_free_space			;hl:de = free space in kb
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
		jp print_and_return
	

;-----------------------------------------------------------------------

div_line	ld bc,$132d				;2d = "-"
		call os_print_multiple_chars
		call os_new_line
		ret

;-----------------------------------------------------------------------

print_filesize

		ld de,filesize_cache_msw+1		

print_double_word

		ld hl,os_hex_prefix_txt			;show "$"
		call os_print_string	
		ld hl,output_line
		ld b,4
		call n_hexbytes_to_ascii
		ld (hl),0	
		ld b,7					;skip leading zeros
		call os_print_output_line_skip_zeroes	;show hex figures 
		ret

;-----------------------------------------------------------------------
	