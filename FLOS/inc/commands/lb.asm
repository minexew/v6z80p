;-----------------------------------------------------------------------
;"lb" - Load binary file command. V6.01
;-----------------------------------------------------------------------

os_cmd_lb
	

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

	ld hl,(fs_file_length)		;note the stated filesize
	ld (filesize_cache_lsw),hl
	ld hl,(fs_file_length+2)
	ld (filesize_cache_msw),hl
	
	ld hl,(os_args_start_lo)
	call ascii_to_hexword		;load location override?
	cp $c
	ret z
	cp $1f
	jr z,os_lbnao
	ld (fs_z80_address),de
	
	call ascii_to_hexword		;bank override too?
	cp $c
	ret z
	cp $1f
	jr z,os_lbnao
	ld a,e				
	call test_bank			;must be in range
	jp nc,os_invalid_bank
	ld (fs_z80_bank),a

os_lbnao	push hl				;ensure load doesnt overwrite OS
	push de
	ld de,(fs_z80_address)
	ld hl,os_high
	xor a
	sbc hl,de
	jr c,os_lbprok
	pop de
	pop hl
	xor a
	ld a,$26				;ERROR $26 - A load here would overwrite OS code/data
	ret
os_lbprok	pop de
	pop hl

	call fs_read_data_command
	ret c
	or a
	ret nz

	ld hl,os_hex_prefix_txt		;show "$"
	call os_print_string
	
	ld hl,output_line
	ld de,filesize_cache_msw
	ld b,3
	call n_hexbytes_to_ascii
	ld (hl),0	
	ld b,5				;skip leading zeros
	call os_print_output_line_skip_zeroes	;show hex figures 
	
	xor a			
	ld a,$10				;show " bytes loaded" return message
	ret
	
;-----------------------------------------------------------------------------------------------