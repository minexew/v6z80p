;-----------------------------------------------------------------------
;"cd" - Change Dir command. V6.15
;-----------------------------------------------------------------------

os_cmd_cd	

		ld a,(hl)				; if no args, just show dir path		
		or a				
		jr nz,pc_like_cd		

;--------------------------------------------------------------------------------------------------

max_dirs	equ 16


cd_show_path	call kjt_check_volume_format	
		ret nz

		ld b,max_dirs
		ld c,0
lp1		push bc
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
		pop de					;dont show "/" if root dir (VOLx:/) already has a slash
		ld a,d
		or e
		pop bc
		jr z,no_dirsl
		ld a,c					;dont show "/" if last dir of list
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

pc_like_cd	ld a,(current_volume)
		ld e,a
		push de
		call cd_parse_path
		pop de
		push af
		ld a,e
		call os_change_volume
		pop af
		ret

;--------------------------------------------------------------------------------------------------

cd_parse_path
		call cd_store_vol_dir
		
		call kjt_check_volume_format	
		ret nz		
		
		ld a,(hl)				
		call compare_slashes			; is first char "/" or "\" ?
		jr nz,cd_nogor
		
cd_goroot	push hl
		call kjt_root_dir	
		pop hl
		ret nz
		inc hl
		jr cd_margs				; more args follow?
		
		
cd_nogor	cp "%"					; "%" char = go to assigned dir
		jr nz,cd_no_assign
		push hl
		call get_dirvol_from_envar		; DE = dir cluster, A = volume
		pop hl
		call cd_volmove
		ret nz
		jr cd_notvolsl
			
cd_no_assign	call test_vol_string			; VOLx: ??
		jr nc,cd_nchvol
		ld de,0					; put root block in DE, A = volume  		
		call cd_volmove
		ret nz
		ld a,(hl)				; if volx: and no further path, only change the volume - and use its existing dir
		or a
		ret z
		cp " "
		ret z
		call compare_slashes			; if slash immediately follows "volx:" skip it (dont want it seen as a dir name)
		jr nz,cd_margs				; but still reset volume to root. If not, dont reset volume to root, just assume		
		inc hl					; current dir of this volume
		ld (os_args_start_lo),hl
		
cd_notvolsl	push de
		call fs_get_dir_block
		ld (original_dir_cd_cmd),de		; update the cluster that needs to be replaced upon completion (if want to restore)
		pop de
		call os_update_dir_cluster_safe
				
		ld hl,(os_args_start_lo)
cd_margs	ld a,(hl)
		cp " "
		ret z

cd_nchvol	ld a,(hl)				; look for additional paths in args
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
		or a					; null terminator = last char of string?
		ret z
		cp " "
		jr nz,cd_gdn
		inc hl
		jr cd_mollp
		
cd_gdn		push hl
		call kjt_change_dir			;step through args changing dirs as apt
		pop hl					
		jr nz,cd_restore_vol_dir		;if a dir is not found go back to original dir and drive 
cd_mol		ld a,(hl)				;move to next dir name in args (after "/" or "\") if no more found, quit
		inc hl
		or a
		ret z
		call compare_slashes			;"/" or "\" ?
		jr z,cd_nchvol
		jr cd_mol
			


;--------------------------------------------------------------------------------------------------
		
cd_store_vol_dir

		call os_get_dir_vol
		ld (original_vol_cd_cmd),a
		ld (original_dir_cd_cmd),de
		ret
		

;--------------------------------------------------------------------------------------------------

		
cd_dcherr	ld a,$23					;dir not found error
		or a
		
cd_restore_vol_dir

		push af
		ld de,(original_dir_cd_cmd)
		ld a,(original_vol_cd_cmd)
		call restore_vol_dir				;puts DE in volume's cluster and changes vol to A
		pop af
		ret

;--------------------------------------------------------------------------------------------------


cd_volmove	ld bc,5
		add hl,bc
		ld (os_args_start_lo),hl
		
		push de
		push hl
		call os_change_volume		
		call fs_get_dir_block
		ld (original_dir_cd_cmd),de			;when changing volume, note the initial dir of the new volume		
		pop hl
		pop de
		ret 


;--------------------------------------------------------------------------------------------------

compare_slashes	cp $2f
		ret z
		cp $5c
		ret

;--------------------------------------------------------------------------------------------------

original_dir_cd_cmd	dw 0			; dont use scratch pad for these 
original_vol_cd_cmd 	db 0			 
			
;--------------------------------------------------------------------------------------------------

