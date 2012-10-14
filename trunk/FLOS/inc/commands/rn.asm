;-------------------------------------------------------------------------------------------
;"rn" - Rename command. V6.03
;-------------------------------------------------------------------------------------------

os_cmd_rn
	
	call fileop_preamble		; handle path parsing etc
	ret nz
	call do_rn_cmd
	call cd_restore_vol_dir
	ret

do_rn_cmd	push hl
	pop de
	
	call os_next_arg
	jp z,os_no_args_error
	
	ex de,hl
	jp kjt_rename_file			;no point it being a call, nothing follows
		
;-------------------------------------------------------------------------------------------
