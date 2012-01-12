;-----------------------------------------------------------------------------------------------
; "MOUNT" = Re-mount and show drives v6.03
;-----------------------------------------------------------------------------------------------

os_cmd_remount

	xor a			;quiet mode off
	call os_mount_volumes
	call os_new_line
	
	ld hl,commands_txt		; set "%ex0" assign envar
	call os_change_dir
	jr nz,no_cmds
	call fs_get_dir_block
	ld (envar_data),de
	ld a,$30
	ld (ex_path_txt+3),a
	ld hl,ex_path_txt
	ld de,envar_data
	call os_set_envar
	call os_root_dir

no_cmds	xor a
	ret

;-----------------------------------------------------------------------------------------------
	