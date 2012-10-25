;----------------------------------------------------------------------------------------------------------

s_code	ld a,(ix+1)		;is it sub instuction?
	cp "b"
	jr z,sbc_likely		;is is "sb"
	cp "e"
	jr z,set_likely		;is it "se"
	cp "c"
	jp z,scf_likely		;is it "sc"
	cp "l"
	jp z,sla_likely		;is it "sl"
	cp "r"
	jp z,sra_likely		;is it "sr"
	cp "u"
	jp z,sub_likely		;is it "su"?
	
	jp invalid_instruction
	
;---------------------------------------------------------------------------------------------------------

sbc_likely
	ld a,(ix+2)
	cp "c"
	jp nz,invalid_instruction
	ld a,(ix+3)
	or a
	jp nz,invalid_instruction
	
	ld ix,opcode_arg1_string
	call id_hlixiy_operand	;is a 16 bit sbc?
	jp c,sbc_16
	ld a,$98			;"sbc a" opcode
	ld (opcode_stem),a
	jp standard_alu_instruction


;---------------------------------------------------------------------------------------------------------

sbc_16	ld a,(ixiy_prefix)		;only "sbc hl" is allowed (no ix/iy) 
	or a
	jp nz,invalid_instruction
	ld a,$ed
	call output_data_byte
	ld a,%01000010
	ld (opcode_stem),a
	jp normal_hl_dest


;---------------------------------------------------------------------------------------------------------


sub_likely

	ld a,(ix+2)
	cp "b"			;sub
	jp nz,invalid_instruction
	ld a,(ix+3)
	or a
	jp nz,invalid_instruction
	
	ld a,$90			;"sub a" opcode
	ld (opcode_stem),a
	jp standard_alu_instruction

	
;---------------------------------------------------------------------------------------------------------

set_likely

	ld a,(ix+2)		;set instruction
	cp "t"
	jp nz,invalid_instruction
	ld a,(ix+3)
	or a
	jp nz,invalid_instruction
	
	ld a,%11000000
	ld (opcode_stem),a
	jp handle_bitwise_instruction
	
;---------------------------------------------------------------------------------------------------------

scf_likely

	ld a,(ix+2)
	cp "f"
	jp nz,invalid_instruction
	ld a,(ix+3)
	or a
	jp nz,invalid_instruction
	call test_opcode_args	; this instruction should have no operands
	jp nz,invalid_instruction
	ld a,$37
	call output_data_byte	; SCF opcdoe
	xor a
	ret

;---------------------------------------------------------------------------------------------------------

sla_likely

	ld a,(ix+2)
	cp "a"
	jp nz,invalid_instruction
	ld a,(ix+3)
	or a
	jp nz,invalid_instruction
	
	ld a,$20
	ld (opcode_stem),a		;sla stem
	jp do_as_rl

;---------------------------------------------------------------------------------------------------------

sra_likely

	ld a,(ix+2)
	cp "a"
	jr nz,try_srl
	ld a,(ix+3)
	or a
	jp nz,invalid_instruction
	
	ld a,$28
	ld (opcode_stem),a		;sra stem
	jp do_as_rl
		

;---------------------------------------------------------------------------------------------------------

try_srl	ld a,(ix+2)
	cp "l"
	jp nz,invalid_instruction
	ld a,(ix+3)
	or a
	jp nz,invalid_instruction
	
	ld a,$38
	ld (opcode_stem),a		;srl stem
	jp do_as_rl
	
;=======================================================================================================

