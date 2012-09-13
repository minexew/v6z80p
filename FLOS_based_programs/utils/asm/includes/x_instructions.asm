;----------------------------------------------------------------------------------------------------------

x_code	ld a,(ix+1)			;is it an "XOR" instruction?
	cp "o"
	jp nz,invalid_instruction
	ld a,(ix+2)
	cp "r"
	jp nz,invalid_instruction
	ld a,(ix+3)
	or a
	jp nz,invalid_instruction
	
	ld a,$a8				;"xor" instruction stem
	ld (opcode_stem),a
	jp standard_alu_instruction


;=======================================================================================================
