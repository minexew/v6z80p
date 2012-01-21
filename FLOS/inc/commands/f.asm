;-----------------------------------------------------------------------
;"f" fill memory command. V6.07
;-----------------------------------------------------------------------

os_cmd_f			

	call get_start_and_end	;this routine only returns here if start/end data is valid

	call hexword_or_bust	;the call only returns here if the hex in DE is valid
	jp z,os_no_args_error
	ld c,e			;c = fill byte
	
	call test_range_valid
	jp c,os_range_error		;abort if end addr <= start addr

	ld a,c			;get fill byte in A
	ld b,h			;get length in bc
	ld c,l
	inc bc
	ex de,hl			;get start address in HL
	call os_bchl_memfill

	jp ok_ret			;OK completion message
	

;-----------------------------------------------------------------------
