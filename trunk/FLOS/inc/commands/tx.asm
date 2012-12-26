;-----------------------------------------------------------------------
;"TX" - Transmit binary file via serial port command. V6.04
;-----------------------------------------------------------------------

os_cmd_tx:
	
		ld a,(hl)			;check args exist
		or a
		jp z,os_no_fn_error
		
		call rx_copy_filename	
				
		call hexword_or_bust		;the call only returns here if the hex in DE is valid
		jp z,os_no_start_addr		;get save address in DE
		ld (fs_z80_address),de

		call ascii_to_hex32_scan	;hl->bc:de
		ret nz
		ld (fs_file_length),de
		ld (fs_file_length+2),bc
		
		call hexword_or_bust		;the call only returns here if the hex in DE is valid
		jr nz,sers_dfb			;get bank if specified, else use current bank
		call os_getbank
		ld e,a
sers_dfb	ld b,e
		ld a,b				;check bank is valid
		cp max_bank+1
		jp nc,os_invalid_bank
		ld (fs_z80_bank),a

		ld hl,ser_send_msg
		call os_show_packed_text

		ld bc,(fs_file_length+2)
		ld de,(fs_file_length)
		ld a,(fs_z80_bank)
		ld b,a
		ld hl,serial_filename		;filename location in HL
		ld ix,(fs_z80_address)
		call serial_send_file
		ret nz			
		jp ok_ret			;return with ok msg

sers_fsb	pop hl

os_no_filesize

		ld a,$17
		or a
		ret
		

;----------------------------------------------------------------------------------------------
