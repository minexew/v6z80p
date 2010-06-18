;-----------------------------------------------------------------------
;"exec" - execute script V6.00
;
; Notes: Changing drives within a script not supported yet.
;        Scripts cannot launch scripts
;-----------------------------------------------------------------------

os_cmd_exec:

	ld hl,in_script_flag		;test if already in a script
	bit 0,(hl)
	jr z,oktlscr
	xor a
	ret
oktlscr	set 0,(hl)

	ld hl,(os_args_start_lo)		;copy the script filename (scripts cannot launch
	ld de,script_fn			;scripts as this would require nested script filenames)
	ld b,16
	call os_copy_ascii_run
	call fs_get_dir_block		;store location of dir that holds the script
	ld (script_dir),de
	
	call fs_check_disk_format
	ret c
	or a
	ret nz
	
	ld hl,0
	ld (script_file_offset),hl
	
scrp_loop	ld hl,script_buffer			;clear bootscript buffer and command string		
	ld de,commandstring
	ld b,OS_window_cols+1
	ld a,$20				;fill 'em with spaces
scrp_flp	ld (hl),a
	ld (de),a
	inc hl
	inc de
	djnz scrp_flp
	
	call fs_get_dir_block		;store current dir
	push de
	ld de,(script_dir)			;return to dir that contains the script
	call fs_update_dir_block
	ld hl,script_fn			;locate the script file - this needs to be done every
	call fs_hl_to_filename		;script line as external commands will have opened files
	call fs_open_file_command		
	jr c,pop_ret
	or a
	jr nz,pop_ret
	pop de
	call fs_update_dir_block		;return to dir selected prior to script
	
	ld ix,0
	ld iy,OS_window_cols		;only load enough chars for one line 
	call os_set_load_length
	ld iy,(script_file_offset)		;index from start of file
	call os_set_file_pointer
		
	ld hl,script_buffer			;load in part of the script	
	ld b,0
	call os_force_load
	or a			
	jr z,scrp_ok			;file system error?
	cp $1b			
	ret nz				;Dont mind if attempted to load beyond end of file
	
scrp_ok	ld iy,(script_file_offset)
	ld hl,script_buffer			;copy ascii from script buffer to command string
	ld de,commandstring
	ld b,OS_window_cols
scrp_cmd	ld a,(hl)
	cp $20
	jr c,scrp_eol
	ld (de),a
	inc hl
	inc de
	inc iy
	djnz scrp_cmd
	
scrp_eol	ld (script_file_offset),iy
	ld (script_buffer_offset),hl

	call os_parse_cmd_chk_ps		;attempt to launch commands (check for spawn progs)
	
	ld iy,(script_file_offset)		;skip <CR> etc when repositioning file pointer
	ld hl,(script_buffer_offset)
scrp_fnc	ld a,(hl)		
	or a
	ret z				;if encounter a zero, its the end of the file
	cp $20
	jr nc,scrp_gnc			;if a space or higher, we have the next command
	inc hl		
	inc iy				;otherwise keep looking
	jr scrp_fnc

scrp_gnc	ld (script_file_offset),iy		;update file offset and loop
	jp scrp_loop	



pop_ret	pop de
	ret
	

;-----------------------------------------------------------------------------------------------