;--------------------------------------------------------------------------------------------
;"km" - change keymap V6.00
;--------------------------------------------------------------------------------------------

os_cmd_km

	call fs_check_disk_format
	ret c
	or a
	ret nz
	
	call os_args_to_filename
	or a
	jp z,os_no_fn_error			;filename supplied?

	call fs_open_file_command		;get header info, does file exist in current dir
	ret c
	or a
	ret nz

	ld ix,0
	ld iy,$62*2
	call os_set_load_length		;prevent malformed keymaps overwriting OS
	
	ld hl,keymap
	call os_force_load			;overwrite default keymap
	
	ld hl,km_set_msg
	call os_show_packed_text
	xor a
	ret

;--------------------------------------------------------------------------------------------