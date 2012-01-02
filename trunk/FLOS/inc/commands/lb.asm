;-----------------------------------------------------------------------
;"lb" - Load binary file command. V6.04
;-----------------------------------------------------------------------

os_cmd_lb
	
	call kjt_check_volume_format	
	ret nz

	call os_getbank			;default load bank is current bank
	ld (lb_load_bank),a
		
	call filename_or_bust		;filename supplied?
	call os_find_file			;get header info
	ret nz
	ld (filesize_cache_lsw),iy		;note the filesize
	ld (filesize_cache_msw),ix
	ld (lb_load_addr),hl

	ld hl,(os_args_start_lo)
	call os_next_arg
	call hexword_or_bust		;the call only returns here if the hex in DE is valid
	jr z,os_lbnao			;load location override?
	ld (lb_load_addr),de
	push hl
	ld hl,os_high			;ensure load doesn't overwrite OS
	sbc hl,de
	pop hl
	jr c,os_lbprok
	ld a,$26				;ERROR $26 - OS SPACE PROTECT
	or a
	ret
	
os_lbprok	call hexword_or_bust		;the call only returns here if the hex in DE is valid
	jr z,os_lbnao			;bank override too?
	ld a,e				
	cp max_bank+1			;must be in range
	jp nc,os_invalid_bank
	ld (lb_load_bank),a

os_lbnao	ld hl,(lb_load_addr)		;load the file
	ld a,(lb_load_bank)
	ld b,a
	call os_force_load
	ret nz


	ld de,filesize_cache_msw		
show_bl	ld hl,os_hex_prefix_txt		;show "$"
	call os_print_string	
	ld hl,output_line
	ld b,3
	call n_hexbytes_to_ascii
	ld (hl),0	
	ld b,5				;skip leading zeros
	call os_print_output_line_skip_zeroes	;show hex figures 
	
	ld a,$10				;show " bytes loaded" return message
	or a
	ret
	
;-----------------------------------------------------------------------------------------------

lb_load_addr	equ scratch_pad
lb_load_bank	equ scratch_pad+2

;-----------------------------------------------------------------------------------------------
