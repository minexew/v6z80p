;-----------------------------------------------------------------------
;"cd" - Change Dir command. V6.13
;-----------------------------------------------------------------------

os_cmd_cd	

		ld a,(hl)				; if no args, just show dir path		
		or a				
		jr nz,cd_parse_path		

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


cd_parse_path
		
		call kjt_check_volume_format	
		ret nz
		
		call cd_store_vol_dir
		
		ld a,(hl)				
		cp $5c				; if "\" = go root
		jr z,cd_goroot
		cp $2f			
		jr nz,cd_nogor			; if "/" = go root
cd_goroot	push hl
		call kjt_root_dir	
		pop hl
		ret nz
		inc hl
		jr cd_margs			; more args follow?
		
		
cd_nogor	cp "%"				; "%" char = go assigned dir
		jr nz,cd_no_assign
		push hl
		call os_set_dirvol_from_envar
		pop hl
		ret nz
		ld de,5
		add hl,de
		jr cd_nchvol
			
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
cd_done		xor a
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
		
cd_gdn		push hl
		call kjt_change_dir			;step through args changing dirs as apt
		pop hl
		jr nz,cd_dcherr
cd_mol		ld a,(hl)				;move to next dir name in args (after "/" or "\") if no more found, quit
		inc hl
		or a
		ret z
		cp $2f				;"/"?
		jr z,cd_nchvol
		cp $5c				;"\"?
		jr z,cd_nchvol
		jr cd_mol
			
cd_dcherr	

		call cd_restore_vol_dir		;if a dir is not found go back to original dir and drive 
		or a
		ret


;--------------------------------------------------------------------------------------------------
		
cd_store_vol_dir

		call os_get_dir_vol
		ld (original_vol_cd_cmd),a
		ld (original_dir_cd_cmd),de
		ret
		
		
cd_restore_vol_dir
		
		push af
		ld a,(original_vol_cd_cmd)
		ld de,(original_dir_cd_cmd)
		call os_set_dir_vol
		jr z,cd_rvdok
		inc sp
		inc sp
		ret
cd_rvdok	pop af
		ret

			
;--------------------------------------------------------------------------------------------------

original_dir_cd_cmd	dw 0			; dont use scratch pad for these 
original_vol_cd_cmd 	db 0			 
			
;--------------------------------------------------------------------------------------------------

