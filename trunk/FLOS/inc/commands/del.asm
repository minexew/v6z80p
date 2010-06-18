;-----------------------------------------------------------------------
;"del" delete file command. V6.00
;-----------------------------------------------------------------------


os_cmd_del
	
	call fs_check_disk_format
	ret c
	or a
	ret nz
	
	call os_args_to_filename
	or a
	jp z,os_no_fn_error	
	call fs_erase_file_command
	ret c
	or a
	ret nz
	ld a,$20				;ok msg
	ret
	
;-----------------------------------------------------------------------
	