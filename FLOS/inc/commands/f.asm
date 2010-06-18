;-----------------------------------------------------------------------
;"f" fill memory command. V6.01
;-----------------------------------------------------------------------

os_cmd_f:				

	call get_start_and_end
	cp $c			;bad hex?
	ret z
	cp $1f		
	jp z,os_no_start_addr	;no start address
	cp $20
	jp z,os_no_e_addr_error	;no end address

	call ascii_to_hexword	;get fill byte
	cp $c
	ret z
	cp $1f
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

	xor a
	ld a,$20			;OK completion message
	ret

