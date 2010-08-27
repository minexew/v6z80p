;--------------------------------------------------------------------------------
;"RD" - Remove directory command. V6.05
;--------------------------------------------------------------------------------

os_cmd_rd

	call kjt_check_volume_format	
	ret nz
	
	call filename_or_bust

	jp kjt_delete_dir		;no point it being a call, nothing follows


;---------------------------------------------------------------------------------
