;-----------------------------------------------------------------------
;"fi" - File info. V6.01
;-----------------------------------------------------------------------

os_cmd_fi:
	
	call fs_check_disk_format
	ret c
	or a
	ret nz
	
	call os_args_to_filename
	or a
	jp z,os_no_fn_error			;filename supplied?

	call fs_open_file_command		;get header info
	ret c
	or a
	ret nz

	ld hl,os_loadaddress_msg		;show load address
	call os_show_packed_text
	ld de,(fs_z80_address)
	ld hl,output_line
	call hexword_to_ascii
	ld (hl),0
	ld b,3
	call os_print_output_line_skip_zeroes
	call os_new_line
	
	ld de,(fs_z80_address)		;show bank if start address > $8000
	bit 7,d
	jr z,fi_skpbs
	ld hl,os_bank_msg			
	call os_show_packed_text
	ld a,(fs_z80_bank)
	ld hl,output_line
	call hexbyte_to_ascii
	ld (hl),0
	ld b,1
	call os_print_output_line_skip_zeroes
	call os_new_line

fi_skpbs	ld hl,os_filesize_msg		;show filesize
	call  os_show_packed_text
	ld de,fs_file_length+2
	ld b,3
	ld hl,output_line
	call n_hexbytes_to_ascii
	ld (hl),11
	inc hl
	ld (hl),0
	ld b,5				;remove leading zeros
	call os_print_output_line_skip_zeroes	;show hex figures 

	xor a
	ret

	
;-----------------------------------------------------------------------------------------------