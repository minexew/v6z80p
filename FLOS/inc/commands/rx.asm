;-----------------------------------------------------------------------
;"RX" - Receive binary file via serial port command. V6.04
;-----------------------------------------------------------------------
;
;  6.03 - Longer time out but can quit with ESC key
;  6.02 - Adapted to new regime where "receive file" sets the load address
;
;-------------------------------------------------------------------------------

os_cmd_rx:
	
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
	jp z,os_no_start_addr	;gets load location in DE
	ld (serial_address),de
	
	push hl
	ld hl,os_high
	xor a
	sbc hl,de
	jr c,os_prok
	pop hl
	ld a,$26			;ERROR $26 - A load here would overwrite OS code/data
	or a
	ret
os_prok	pop hl
	
	call hexword_or_bust	;the call only returns here if the hex in DE is valid
	jr nz,serl_dfb		;get bank if specified, else use current bank
	call os_getbank
	ld e,a
serl_dfb	ld b,e
	ld a,b			;check bank is in valid range
	ld (serial_bank),a
	call test_bank
	jp nc,os_invalid_bank
			
	ld hl,ser_rec_msg
	call os_show_packed_text
	
	in a,(sys_serial_port)	;flush serial buffer at outset

	ld hl,serial_filename	;filename location in HL
	ld a,$8F			;time out = 15 seconds / escape key active
	call serial_get_header
	or a
	ret nz			;if a = 0 on return, header was OK
	ld hl,ser_rec2_msg
	call os_show_packed_text
	call serial_receive_file
	or a			;if a = 0 on return, file load was OK
	ret nz			;"or" clears carry flag

	ld hl,output_line
	ld de,(serial_fileheader+18)
	call hexword_to_ascii
	ld de,(serial_fileheader+16)
	call hexword_to_ascii	
	ld (hl),0
	ld hl,os_hex_prefix_txt	;report number of bytes loaded
	call os_print_string
	ld b,7
	call os_print_output_line_skip_zeroes
		
	ld a,$10			;show " bytes loaded" return message
	or a
	ret


;----------------------------------------------------------------------------------------------
