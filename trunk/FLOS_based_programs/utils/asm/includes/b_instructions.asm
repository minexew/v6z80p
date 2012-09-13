;------------------------------------------------------------------------------------------------------------------

b_code	ld a,(ix+1)		;is it an "BIT" instruction?
	cp "i"
	jp nz,not_bit
	ld a,(ix+2)
	cp "t"
	jp nz,not_bit
	ld a,(ix+3)
	or a
	jp nz,not_bit
	
	ld a,%01000000		;BIT opcode stem (after CB)
	ld (opcode_stem),a
	jp handle_bitwise_instruction
		
;-------------------------------------------------------------------------------------------------------------------

not_bit	jp invalid_instruction

;=======================================================================================================

