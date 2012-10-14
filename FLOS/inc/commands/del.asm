;-----------------------------------------------------------------------
;"DEL" delete file command. V6.03
;-----------------------------------------------------------------------


os_cmd_del
	
	call fileop_preamble		; handle path parsing etc
	ret nz
	call kjt_erase_file
	call cd_restore_vol_dir
	ret

;-----------------------------------------------------------------------
