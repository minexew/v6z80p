;-----------------------------------------------------------------------
;"cd" - Change Dir command. V6.03
;-----------------------------------------------------------------------

os_cmd_cd
	push hl
	pop ix
	ld a,"."			;".." = goto parent dir
	cp (hl)
	jr nz,cd_nual
	cp (ix+1)
	jr nz,cd_nual
	call fs_check_disk_format	
	ret c
	or a
	ret nz
	call fs_parent_dir_command	
	ret

cd_nual	ld a,(hl)
	cp $2f			; "/" char = go root
	jr nz,cd_nogor
	call fs_check_disk_format	
	ret c
	or a
	ret nz
	call fs_goto_root_dir_command	
	ret
	
cd_nogor	ld a,(current_volume)
	ld (original_vol_cd_cmd),a

	push hl
	pop ix
	ld a,(ix+4)
	cp ":"			; wish to change volume?
	jr nz,cd_nchvol
	ld de,vol_txt+1
	ld b,3
	call os_compare_strings
	jr nc,cd_nchvol
	ld de,5
	add hl,de
	ld (os_args_start_lo),hl	; update args position
	ld a,(ix+3)		; volume digit char
	sub $30
	call os_change_volume
	ret nz			; error if new volume is invalid
	call fs_goto_root_dir_command	; go to new drive's root block as drive has changed
	jr cd_mol			; look for additional paths in args


cd_nchvol	call os_args_to_filename	; did not find a volume name, look for dir paths
	or a
	jr z,cd_show_path		; if no args, just show dir path

	call fs_get_dir_block
	ld (original_dir_cd_cmd),de

cd_mollp	call fs_change_dir_command	;step through args changing dirs as apt
	or a
	jr nz,cd_dcherr
cd_mol	call os_args_to_filename
	or a
	jr nz,cd_mollp
	ret			;if no more args, finish
	
cd_dcherr	push af			;if a dir is not found go back to original dir and drive 
	ld de,(original_dir_cd_cmd)
	call fs_update_dir_block
	ld a,(original_vol_cd_cmd)
	call os_change_volume	
	pop af
	or a
	ret



cd_show_path

	xor a
	ret
	

original_dir_cd_cmd	dw 0
original_vol_cd_cmd db 0
	
;--------------------------------------------------------------------------------------------------