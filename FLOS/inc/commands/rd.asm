;-----------------------------------------------------------------------
;"RD" - Remove directory command. V6.01
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
	cp $0b			;dir not found?
	jr nz,notdnf
	ld a,$23			;swap FS error code $0b to message index $23	
notdnf	or a		
	ret

;-----------------------------------------------------------------------
