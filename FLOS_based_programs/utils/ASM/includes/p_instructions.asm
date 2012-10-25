
p_code
	ld a,(ix+1)
	cp "o"
	jr z,pop_likely
	cp "u"
	jr z,push_likely
	
	jp invalid_instruction

;-------------------------------------------------------------------------------------------------------

pop_likely

	ld a,(ix+2)
	cp "p"
	jp nz,invalid_instruction
	ld a,(ix+3)
	or a
	jp nz,invalid_instruction
	
	ld a,(opcode_arg2_string)	;should be no second arg
	or a
	jp nz,invalid_instruction
	ld a,%11000001		;"pop" instruction stem
	ld (opcode_stem),a
	ld ix,opcode_arg1_string
	jp type_3_16bit_opcode


push_likely

	ld a,(ix+2)
	cp "s"
	jp nz,invalid_instruction
	ld a,(ix+3)
	cp "h"
	jp nz,invalid_instruction
	ld a,(ix+4)
	or a
	jp nz,invalid_instruction
	
	ld a,(opcode_arg2_string)	;should be no second arg
	or a
	jp nz,invalid_instruction
	ld a,%11000101		;"push" instruction stem
	ld (opcode_stem),a
	ld ix,opcode_arg1_string
	jp type_3_16bit_opcode
	

;=======================================================================================================

