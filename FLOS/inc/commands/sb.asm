;-----------------------------------------------------------------------
;"SB" - Save binary file command. V6.01
;-----------------------------------------------------------------------

os_cmd_sb
	
	call fs_check_disk_format
	ret c
	or a
	ret nz
	
	call os_args_to_filename
	or a
	jp z,os_no_fn_error			;filename supplied?

	call fs_open_file_command		;check for anything with this filename 
	ret c
	cp 6
	ret z				;quit if its a directory
	
	ld hl,(os_args_start_lo)
	call ascii_to_hexword		;save location
	cp $c
	ret z
	cp $1f
	jp z,os_no_start_addr
	ld (fs_z80_address),de
	
	ld bc,0				;set up file length
	ld (fs_file_length),bc		
	ld (fs_file_length+2),bc		;first, clear it
	call os_scan_for_non_space
	or a
	jp z,os_no_filesize
		
	push hl
	ld b,5				;check for 5 digit save length
	ld c,0
os_scflc:	ld a,(hl)
	or a
	jr z,os_sfba
	cp " "
	jr z,os_scgfl
	inc c
os_scinc:	inc hl
	djnz os_scflc
os_scgfl:	pop hl
	ld a,c
	cp 5
	jr nz,os_sfln
	call ascii_to_hex_digit		;convert first digit
	cp 16
	jp nc,os_hex_error
	ld (fs_file_length+2),a
	inc hl	
os_sfln:	call ascii_to_hexword		;do (rest of) length
	cp $c
	ret z
	cp $1f
	jp z,os_no_filesize
	ld (fs_file_length),de
	
	call os_getbank			;bank override?
	ld (fs_z80_bank),a			;use current bank by default
	call ascii_to_hexword		
	cp $1f				;code $1f = no hex
	jr z,os_sfgds
	cp $c				;code $c=bad hex
	ret z
	ld a,e
	call test_bank			;bank must be in correct range
	jp nc,os_invalid_bank
	ld (fs_z80_bank),a
	
os_sfgds:	call fs_create_file_command
	ret c
	cp 9				;if error 9, file exists already
	jr nz,os_sffde			
	ld hl,save_append_msg		;ask if want to append data to exisiting file
	call os_show_packed_text
	call os_wait_key_press
	ld a,"y"
	cp b
	jr z,os_sfapp
	xor a
	ret
	
os_sffde	or a	
	ret nz

os_sfapp	call fs_write_bytes_to_file_command
	ret c
	or a
	ret nz
	ld a,$20				;ok msg
	ret

os_sfba:	pop hl
	xor a
	ld a,$12				;bad arguments
	ret
	
	
;-------------------------------------------------------------------------------------------------
	