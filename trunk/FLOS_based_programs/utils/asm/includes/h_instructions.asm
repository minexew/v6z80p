
h_code	ld a,(ix+1)
	cp "a"
	jr nz,not_halt
	
	ld a,(ix+2)
	cp "l"
	jr nz,not_halt
	
	ld a,(ix+3)
	cp "t"
	jr nz,not_halt

	ld a,(ix+4)
	or a
	jr nz,not_halt
	
	call no_args_required
	ret nz
	
	ld a,$76			;halt
	call output_data_byte
	xor a
	ret
		
;----------------------------------------------------------------------------------------------------

not_halt
	
	jp invalid_instruction

;=======================================================================================================

