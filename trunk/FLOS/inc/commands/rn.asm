;-----------------------------------------------------------------------
;"rn" - Rename command. V6.00
;-----------------------------------------------------------------------

os_cmd_rn
	
	
	call fs_check_disk_format
	ret c
	or a
	ret nz
	
	call os_args_to_alt_filename		;file to rename
	or a
	jp z,os_no_args_error
	
	call os_args_to_filename		;new name for file
	or a
	jp z,os_no_args_error
	
	call fs_rename_command
	ret
;-----------------------------------------------------------------------
