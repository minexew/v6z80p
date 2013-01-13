;-----------------------------------------------------------------------
;"DEL" delete file command. V6.04
;-----------------------------------------------------------------------


os_cmd_del	call fileop_preamble		; handle path parsing etc
		ret nz
		call kjt_erase_file
		jp cd_restore_vol_dir

;-----------------------------------------------------------------------
