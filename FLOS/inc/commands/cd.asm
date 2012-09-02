;-----------------------------------------------------------------------
;"cd" - Change Dir command. V6.09
;-----------------------------------------------------------------------

os_cmd_cd	

	call kjt_check_volume_format	
	ret nz

	ld a,(current_volume)
	ld (original_vol_cd_cmd),a
	push hl
	call fs_get_dir_block
	ld (original_dir_cd_cmd),de
	pop hl

	ld a,(hl)				; if no args, just show dir path		
	or a				
	jp z,cd_show_path		

	ld a,(hl)				
	cp $2f			
	jr nz,cd_nogor			; if "/" = go root
	push hl
	call kjt_root_dir	
	pop hl
	ret nz
	inc hl
	jr cd_margs			; more args follow?
	
	
cd_nogor	cp "%"				; "%" char = go assigned dir
	jr nz,cd_no_assign

cd_envar	call kjt_get_envar
	jr z,cd_evok
	ld a,$23
	or a
	ret
cd_evok	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld a,(hl)
	push de
	call os_change_volume
	pop de
	ret nz
	call kjt_set_dir_cluster
	ret
	
	
cd_no_assign

	push hl
	pop ix
	ld a,(ix+4)
	cp ":"				; wish to change volume?
	jr nz,cd_nchvol
	ld de,vol_txt+1
	ld b,3
	call os_compare_strings
	jr nc,cd_nchvol
	ld de,5
	add hl,de
	ld (os_args_start_lo),hl		; update args position
	ld a,(ix+3)			; volume digit char
	sub $30
	call os_change_volume
	ret nz				; error if new volume is invalid
	call kjt_root_dir			; go to new drive's root block as drive has changed

	ld hl,(os_args_start_lo)
cd_margs	ld a,(hl)
	cp " "
	jr nz,cd_mollp			; look for additional paths in args
cd_done	xor a
	ret

cd_nchvol	ld a,(hl)
	cp "."
	jr nz,cd_mollp
	inc hl
	ld a,(hl)
	cp "."
	jr nz,cd_dcherr
	push hl
	call kjt_parent_dir	
	pop hl
	ret nz
	inc hl
	jr cd_mol

cd_mollp	ld a,(hl)
	or a
	ret z
	cp " "
	jr nz,cd_gdn
	inc hl
	jr cd_mollp
	
cd_gdn	push hl
	call kjt_change_dir			;step through args changing dirs as apt
	pop hl
	jr nz,cd_dcherr
cd_mol	ld a,(hl)				;move to next dir name in args (after "/") if no more found, quit
	inc hl
	or a
	ret z
	cp $2f				;"/"?
	jr z,cd_nchvol
	jr cd_mol
		
cd_dcherr	

	push af				;if a dir is not found go back to original dir and drive 
	ld de,(original_dir_cd_cmd)
	call fs_update_dir_block
	ld a,(original_vol_cd_cmd)
	call os_change_volume	
	pop af
	or a
	ret
	
;--------------------------------------------------------------------------------------------------

cd_show_path


max_dirs	equ 16

	ld b,max_dirs
	ld c,0
lp1	push bc
	call kjt_get_dir_cluster
	pop bc
	push de
	inc c
	push bc
	call kjt_parent_dir
	pop bc
	jr nz,shdir_lp
	djnz lp1
	
shdir_lp	pop de
	push bc
	push de
	call kjt_set_dir_cluster
	call kjt_get_dir_name
	call kjt_print_string
	pop de				;dont show "/" if root dir (VOLx)
	ld a,d
	or e
	pop bc
	jr z,no_dirsl
	ld a,c				;dont show "/" if last dir of list
	dec a
	jr z,no_dirsl
	ld a,$2f				;2f = "/"
	call os_print_char
no_dirsl	dec c
	jr nz,shdir_lp

	call os_new_line	
	xor a
	ret


;--------------------------------------------------------------------------------------------------

original_dir_cd_cmd	equ scratch_pad 
original_vol_cd_cmd equ scratch_pad+2
		
;--------------------------------------------------------------------------------------------------

