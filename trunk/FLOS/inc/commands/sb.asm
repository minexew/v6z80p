;-----------------------------------------------------------------------
;"SB" - Save binary file command. V6.03
;-----------------------------------------------------------------------

os_cmd_sb
	
	call kjt_check_volume_format		;disk ok?
	ret nz
	
	call os_getbank			
	ld (sb_save_bank),a			;use current bank for save by default

	call filename_or_bust		;filename supplied?
	ld (sb_save_name_addr),hl
	
	ld hl,(os_args_start_lo)
	call os_next_arg
	call hexword_or_bust		;the call only returns here if the hex in DE is valid
	jp z,os_no_start_addr		;get the save location from command string
	ld (sb_save_addr),de
	
	call os_next_arg			;find save length
	jp z,os_no_filesize
	exx
	ld hl,0				;hl = LSW	
	ld e,0				; e = MSN
	exx
sb_fsllp	ld a,(hl)
	cp " "
	jr z,sb_gsl
	call ascii_to_hex_digit		;convert up to 5 digits
	inc hl
	cp 16
	jr c,sb_hok
	ld a,$c
	or a
	ret	
sb_hok	exx
	add hl,hl
	rl e
	add hl,hl
	rl e
	add hl,hl
	rl e
	add hl,hl
	rl e
	or l
	ld l,a
	ld (sb_save_len_lo),hl
	ld a,e
	ld (sb_save_len_hi),a
	exx
	jr sb_fsllp

sb_gsl	call hexword_or_bust		;the call only returns here if the hex in DE is valid			
	jr z,os_sfgds			;no hex = no bank override
	ld a,e
	call test_bank			;bank must be in correct range
	jp nc,os_invalid_bank
	ld (sb_save_bank),a
	
os_sfgds	ld hl,(sb_save_name_addr)		;try to make file
	call kjt_create_file
	jr z,os_sfapp
	cp 9				;if error 9, file exists already. Else quit.
	ret nz			
	ld hl,save_append_msg		;ask if want to append data to exisiting file
	call os_show_packed_text
	call os_wait_key_press
	ld a,"y"
	cp b
	jr z,os_sfapp
	xor a
	ret

os_sfapp	ld hl,(sb_save_name_addr)
	ld ix,(sb_save_addr)
	ld de,(sb_save_len_lo)
	ld a,(sb_save_len_hi)
	ld c,a
	ld a,(sb_save_bank)
	ld b,a
	call kjt_write_bytes_to_file
	ret nz	
	ld a,$20				;ok msg
	or a
	ret

	
;-------------------------------------------------------------------------------------------------

sb_save_addr	equ scratch_pad
sb_save_len_lo	equ scratch_pad+2
sb_save_len_hi	equ scratch_pad+4
sb_save_bank	equ scratch_pad+6
sb_save_name_addr	equ scratch_pad+8


;--------------------------------------------------------------------------------------------------
