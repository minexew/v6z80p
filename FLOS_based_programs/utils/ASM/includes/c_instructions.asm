;----------------------------------------------------------------------------------------------------------

c_code	ld a,(ix+1)		;is it a "cp" instruction?
	cp "p"
	jp nz,not_cpl
	ld a,(ix+2)
	or a
	jp nz,not_cp
	
	ld a,$b8			;"cp" instruction stem
	ld (opcode_stem),a
	jp standard_alu_instruction
	
;----------------------------------------------------------------------------------------------------------

not_cp	ld a,(ix+2)		;"cpl" instruction?
	cp "l"
	jr nz,not_cpl
	ld a,(ix+3)
	or a
	jp nz,invalid_instruction
	ld a,$2f
	call output_data_byte
	xor a
	ret

;-----------------------------------------------------------------------------------------------------------


not_cpl	ld a,(ix+1)
	cp "a"			;call instruction?
	jr nz,not_call
	ld a,(ix+2)
	cp "l"
	jr nz,not_call
	ld a,(ix+3)
	cp "l"
	jr nz,not_call
	ld a,(ix+4)
	or a
	jr nz,not_call
	
	ld ix,opcode_arg1_string
	call id_cc_operand
	jp nc,no_call_cc_req
	rlca
	rlca
	rlca
	or %11000100
	call output_data_byte	; conditional call

	ld hl,opcode_arg2_string
ca_addr	call get_16bit_number
	ret nz
	call output_data_word
	xor a
	ret
	
no_call_cc_req

	ld a,%11001101		;unconditional call
	call output_data_byte
	ld hl,opcode_arg1_string
	jr ca_addr
		
;----------------------------------------------------------------------------------------------------------

not_call	ld a,(ix+1)		;is it a "ccf" instruction?
	cp "c"
	jp nz,not_ccf
	ld a,(ix+2)
	cp "f"
	jp nz,not_ccf
	ld a,(ix+3)
	or a
	jr nz,not_ccf	

	ld a,$3f
	call output_data_byte
	xor a
	ret

;----------------------------------------------------------------------------------------------------------

not_ccf	ld a,$a1			
	ld (opcode_stem),a
	inc ix
	inc ix
	jp block_op_handler		; for CPIR, CPDI, CPIR, CPD instructions


;=======================================================================================================

