;-----------------------------------------------------------------------
;"md" - Make dir command. V6.00
;-----------------------------------------------------------------------

os_cmd_md
	
	
	call fs_check_disk_format
	ret c
	or a
	ret nz
	
	call os_args_to_filename
	or a
	jp z,os_no_args_error
	call fs_make_dir_command
	ret

;-----------------------------------------------------------------------
