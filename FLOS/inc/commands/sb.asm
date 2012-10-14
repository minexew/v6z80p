;-----------------------------------------------------------------------
;"SB" - Save binary file command. V6.05
;-----------------------------------------------------------------------

os_cmd_sb
	call fileop_preamble		; handle path parsing etc
	ret nz
	call do_sb_cmd
	call cd_restore_vol_dir
	ret
	

do_sb_cmd	ld (sb_save_name_addr),hl

	call os_getbank			
	ld (sb_save_bank),a			;use current bank for save by default

	call os_move_to_next_arg
	call hexword_or_bust		;the call only returns here if the hex in DE is valid
	jp z,os_no_start_addr		;get the save location from command string
	ld (sb_save_addr),de
	
	call ascii_to_hex32_scan		;hl->bc:de
	ret nz
	ld (sb_save_len_lo),de
	ld (sb_save_len_hi),bc
	
sb_gsl	call hexword_or_bust		;the call only returns here if the hex in DE is valid			
	jr z,os_sfgds			;no hex = no bank override
	ld a,e
	cp max_bank+1			;bank must be in correct range
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
	jp ok_ret				;return with ok msg
	
	
;-------------------------------------------------------------------------------------------------

sb_save_addr	equ scratch_pad
sb_save_len_lo	equ scratch_pad+2
sb_save_len_hi	equ scratch_pad+4
sb_save_bank	equ scratch_pad+6
sb_save_name_addr	equ scratch_pad+8


;--------------------------------------------------------------------------------------------------

