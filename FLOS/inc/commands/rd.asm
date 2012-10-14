;--------------------------------------------------------------------------------
;"RD" - Remove directory command. V6.06
;--------------------------------------------------------------------------------

os_cmd_rd

	call fileop_preamble		; handle path parsing etc
	ret nz
	call kjt_delete_dir
	call cd_restore_vol_dir
	ret
	

;---------------------------------------------------------------------------------
