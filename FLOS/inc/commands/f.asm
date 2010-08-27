;-----------------------------------------------------------------------
;"f" fill memory command. V6.03
;-----------------------------------------------------------------------

os_cmd_f			

	call get_start_and_end	;this routine only returns here if start/end data is valid

	call hexword_or_bust	;the call only returns here if the hex in DE is valid
	jp z,os_no_args_error
	ld a,e
	ld (fillbyte),a
		
	ld hl,(cmdop_end_address)	;check range is ok
	ld bc,(cmdop_start_address)
	xor a			;clear carry
	sbc hl,bc
	jp c,os_range_error		;abort if end addr <= start addr

	ld b,h			;get length in bc
	ld c,l
	inc bc
	ld hl,(cmdop_start_address)
	ld a,(fillbyte)
	call os_bchl_memfill

	ld a,$20			;OK completion message
	or a
	ret

;-----------------------------------------------------------------------
