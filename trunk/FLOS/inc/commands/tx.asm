;-----------------------------------------------------------------------
;"TX" - Transmit binary file via serial port command. V6.01
;-----------------------------------------------------------------------

os_cmd_tx:
	
	ld a,(hl)			;check args exist
	or a
	jp z,os_no_fn_error

	push hl			;clear serial filename area
	ld hl,serial_filename
	ld bc,16
	xor a
	call os_bchl_memfill
	pop hl

	ld b,16			;max chars to copy
	ld de,serial_filename
	call os_copy_ascii_run	;(hl)->(de) until space or zero, or count = 0
	ld a,c
	ld (serial_fn_length),a
	call os_scan_for_space
				
	call hexword_or_bust	;the call only returns here if the hex in DE is valid
	jp z,os_no_start_addr	;get save address in DE
	ld (fs_z80_address),de

	ld de,0			;find file length
	ld (fs_file_length+2),de	
	call os_scan_for_non_space	
	or a
	jp z,os_no_filesize
	push hl
	ld b,5			;check for 5 digit save length
	ld c,0
sers_cflc	ld a,(hl)
	or a
	jp z,sers_fsb
	cp " "
	jr z,sers_cgfl
	inc c
	inc hl
	djnz sers_cflc
sers_cgfl	pop hl
	ld a,c
	cp 5
	jr nz,sers_fln

	call ascii_to_hex_digit	;convert first digit
	cp 16
	jr c,tx_hok
	ld a,$c
	or a
	ret	
tx_hok	ld (fs_file_length+2),a
	inc hl	
sers_fln	call hexword_or_bust	;do (rest of) length
	jp z,os_no_filesize
	ld (fs_file_length),de
	
	call hexword_or_bust	;the call only returns here if the hex in DE is valid
	jr nz,sers_dfb		;get bank if specified, else use current bank
	call os_getbank
	ld e,a
sers_dfb	ld b,e
	ld a,b			;check bank is valid
	call test_bank
	jp nc,os_invalid_bank
	ld (fs_z80_bank),a

	ld hl,ser_send_msg
	call os_show_packed_text

	ld bc,(fs_file_length+2)
	ld de,(fs_file_length)
	ld a,(fs_z80_bank)
	ld b,a
	ld hl,serial_filename	;filename location in HL
	ld ix,(fs_z80_address)
	call serial_send_file
	or a			;if a = 0 on return, load was OK
	ret nz			

	jp ret_ok_msg		;return with ok msg

sers_fsb	pop hl
	jp os_no_filesize
	

;----------------------------------------------------------------------------------------------
