
n_code

	ld a,(ix+1)		;is it an "NEG" instruction?
	cp "e"
	jp nz,not_neg
	ld a,(ix+2)
	cp "g"
	jp nz,not_neg
	ld a,(ix+3)
	or a
	jp nz,not_neg
	
	ld a,(opcode_arg1_string)
	or a
	jp nz,invalid_instruction
	
	ld de,$44ed		;NEG instruction
	call output_data_word
	xor a
	ret

not_neg	ld a,(ix+1)		;is it an "NOP" instruction?
	cp "o"
	jp nz,not_nop
	ld a,(ix+2)
	cp "p"
	jp nz,not_nop
	ld a,(ix+3)
	or a
	jp nz,not_nop
	
	ld a,(opcode_arg1_string)
	or a
	jp nz,invalid_instruction
	
	xor a			;NOP instruction
	call output_data_byte
	xor a
	ret

not_nop
	
	
;=======================================================================================================

	jp invalid_instruction

;=======================================================================================================

