;-----------------------------------------------------------------------
;"cd" - PQFS Change Dir command. V6.01
;-----------------------------------------------------------------------

os_cmd_cd
	push hl
	pop ix
	ld a,"."			;".." = goto parent dir
	cp (ix)
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
	
cd_nogor	call fs_get_current_drive
	ld (original_drv_cd_cmd),a

	ld b,max_drives		;switch current storage device?
	ld c,0
	ld de,dev0_txt		
chdevlp	push bc
	ld b,5
	call os_compare_strings
	pop bc
	jr nc,cd_nchdev
	ld a,c
	push hl
	call fs_change_drive
	pop hl
	or a
	ret nz
	ld de,5
	add hl,de
	ld (os_args_start_lo),hl	; update args position
	call fs_check_disk_format	; dont allow drive change if new drive isnt PQFS
	jr c,cd_drvcer
	or a
	jr nz,cd_drvcer
	call fs_get_dir_block	; cache this drives current dir position
	ld (original_dir_cd_cmd),de
	call fs_goto_root_dir_command	; go to new drive's root block as drive has changed
	jr cd_mol			; look for additional paths in args
	
cd_drvcer	push af			; switch back to the drive selected before the CD
	ld a,(original_drv_cd_cmd)	; command was issued
	call fs_change_drive	
	pop af
	ret
	
cd_nchdev	ld a,e
	add a,8
	jr nc,chdevnc
	inc d
chdevnc	ld e,a
	inc c
	djnz chdevlp
	
	call os_args_to_filename	; did not find a drive name, look for dir paths
	or a
	jr z,cd_show_path		; if no args, just show dir path
	call fs_check_disk_format	
	ret c
	or a
	ret nz
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
	ld a,(original_drv_cd_cmd)
	call fs_change_drive	
	pop af
	or a
	ret



cd_show_path
	
	call fs_check_disk_format
	ret c
	or a
	ret nz
		
	ld hl,temp_string
	ld b,0			;Part 1: Back track through dir tree, creating list
cd_splp:	call fs_get_dir_block	;gets dir block in DE
	
	ld a,d			
	or a
	jr nz,cd_mtpb		;if this is block 1, we're at root
	ld a,1
	cp e
	jr z,cd_got_path
cd_mtpb:	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	push hl
	push bc
	call fs_get_dir_info	;gets parent dir in DE, name pointer in HL
	pop bc
	pop hl
	ret c
	inc b
	ld a,b
	cp 16
	jr z,cd_got_path
	call fs_update_dir_block	;move to the parent block
	jr cd_splp
		
cd_got_path:
	
	ld a,b			
	ld (fs_dir_depthcount),a	
	
	push hl
	ld hl,dev0_txt
	call fs_get_current_drive
	sla a
	sla a
	sla a
	ld e,a
	ld d,0
	add hl,de
cd_spgt	call os_print_string	;show "DRVx:"
	
	ld a,(fs_dir_depthcount)	
	or a
	jr z,cd_sdpdone
	cp 16
	jr nz,cd_nsnip
	dec a
	ld (fs_dir_depthcount),a
	pop hl
	dec hl
	dec hl
	push hl
	ld hl,fs_snip_txt		;if dir depth exceed 16 levels, show snipped version
	call os_print_string
cd_nsnip:	pop hl

 	ld a,(fs_dir_depthcount)	;Part 2 - step through block list showing the	
	ld b,a			;dir names
cd_splp2:	dec hl
	ld d,(hl)
	dec hl
	ld e,(hl)
	push hl
	push bc
	call fs_update_dir_block	;move to block in list

	ld hl,fs_slash_txt		;print a "/" between names
	call os_print_string
	
	call fs_get_dir_info
	jr nc,cd_pdok
	pop bc
	pop hl
	ret
	
cd_pdok:	call os_print_string	;show this dir name
	pop bc
	pop hl
	djnz cd_splp2
	
	ld hl,crlfx2_txt+1
	call os_print_string
		
	ld hl,temp_string		;restore current location
	ld e,(hl)
	inc hl
	ld d,(hl)
	call fs_update_dir_block
	xor a
	ret
		
cd_sdpdone:
	
	ld hl,crlfx2_txt+1
	call os_print_string
	pop hl
	xor a
	ret
	
;--------------------------------------------------------------------------------------------------

original_dir_cd_cmd	dw 0
original_drv_cd_cmd db 0
fs_dir_depthcount	db 0
fs_snip_txt	db "[..snip..]",0			; ""              ""
fs_slash_txt	db "/",0				; ascii dir seperator

;--------------------------------------------------------------------------------------------------
