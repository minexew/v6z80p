;-----------------------------------------------------------------------
;"baud" set baud rate - V6.01
;-----------------------------------------------------------------------

os_cmd_baud


	ld a,(hl)			;check args exist
	or a
	jp z,os_no_args_error
	
	ld de,baudslow_txt+1	;what baud rate was requested?
	ld b,5
	call os_compare_strings
	jr nc,os_nbaud1
	ld hl,txt_57600
	xor a
	jr os_bauddn	
	
os_nbaud1	ld de,baudfast_txt+1		
	ld hl,(os_args_start_lo)
	ld b,6
	call os_compare_strings
	jr nc,os_nbaud2

	call kjt_get_version	;check hardware version
	ld hl,$266-1		;hardware revision required for 115200 BAUD
	xor a
	sbc hl,de
	jr nc,os_nbaud2
	ld hl,txt_115200
	ld a,1
os_bauddn	out (sys_baud_rate),a
	call os_show_packed_text
	call os_new_line
	xor a
	ret
	

os_nbaud2	xor a					
	ld a,$28			;unknown args/unsupported baud rate
	ret
	
txt_57600		db $52,$8d,$1a,0
txt_115200	db $52,$8d,$9e,0

;------------------------------------------------------------------------------------------------
