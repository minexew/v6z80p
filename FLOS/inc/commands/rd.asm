;-----------------------------------------------------------------------
;"RD" - Remove directory command. V6.02
;-----------------------------------------------------------------------

os_cmd_rd

	call os_dont_store_registers	;command does not store registers on return


	call fs_check_disk_format
	ret c
	or a
	ret nz
	
	call os_args_to_filename
	or a
	jp z,os_no_args_error
	call fs_delete_dir_command
	ret c
	or a		
	ret

;-----------------------------------------------------------------------
