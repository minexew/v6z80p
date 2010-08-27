;-------------------------------------------------------------------------------------------
;"rn" - Rename command. V6.02
;-------------------------------------------------------------------------------------------

os_cmd_rn
	
	call kjt_check_volume_format	
	ret nz

	call filename_or_bust
	push hl
	pop de
	call os_next_arg
	call filename_or_bust
	ex de,hl
	jp kjt_rename_file			;no point it being a call, nothing follows
		
;-------------------------------------------------------------------------------------------
