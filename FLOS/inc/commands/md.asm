;-------------------------------------------------------------------------------------------
;"MD" - Make dir command. V6.03
;-------------------------------------------------------------------------------------------

os_cmd_md
	
		call fileop_preamble		; handle path parsing etc
		ret nz
		call kjt_make_dir
		call cd_restore_vol_dir
		ret
	

;-------------------------------------------------------------------------------------------
