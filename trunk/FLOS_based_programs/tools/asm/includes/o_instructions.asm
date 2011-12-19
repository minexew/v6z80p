;----------------------------------------------------------------------------------------------------------

o_code	ld a,(ix+1)		;is it an "OR" instruction?
	cp "r"
	jr nz,not_org
	ld a,(ix+2)
	or a
	jr nz,not_or
	
	ld a,$b0			;"or" instruction stem
	ld (opcode_stem),a
	jp standard_alu_instruction

;-------------------------------------------------------------------------------------------------------------

not_or	ld a,(ix+2)
	cp "g"
	jr nz,not_org
	ld a,(ix+3)
	or a
	jp z,org_directive
		
;-------------------------------------------------------------------------------------------------------------

not_org	ld a,(ix+1)
	cp "t"
	jr nz,not_otxx
out_block	ld a,$a3		
	ld (opcode_stem),a
	inc ix
	inc ix
	jp block_op_handler		; for OTIR, OTDR instructions

;-------------------------------------------------------------------------------------------------------------

not_otxx

	ld a,(ix+1)
	cp "u"
	jr nz,not_out
	ld a,(ix+2)
	cp "t"
	jr nz,not_out	
	ld a,(ix+3)
	or a
	jr z,out_inst
	inc ix
	jr out_block		; for OUTI, OUTD instructions

;--------------------------------------------------------------------------------------------------------------

out_inst	ld ix,opcode_arg1_string
	ld a,(ix)
	cp "("
	jr nz,not_out
	ld a,(ix+1)
	cp "c"
	jr nz,not_out_c_r
	ld a,(ix+2)
	cp ")"
	jr nz,not_out_c_r
	ld a,(ix+3)
	or a
	jr nz,not_out_c_r
	
	ld ix,opcode_arg2_string
	call id_8bit_reg_operand
	jp nc,invalid_instruction
	cp 8
	jp nc,invalid_instruction
	rlca
	rlca
	rlca
	ld b,a
	push bc
	ld a,$ed
	call output_data_byte
	pop bc
	ld a,b
	or $41
	call output_data_byte		;out (c),r
	xor a
	ret
	
	
not_out_c_r


	ld ix,opcode_arg2_string		;is it an "OUT (n),a" instruction?
	ld a,(ix)
	cp "a"
	jr nz,not_out
	ld a,(ix+1)
	or a
	jr nz,not_out	
	ld a,$d3
	call output_data_byte		;out (n),a
	ld hl,opcode_arg1_string
	call get_8bit_number
	ret nz
	ld a,e
	call output_data_byte
	xor a
	ret

;-------------------------------------------------------------------------------------------------------------

not_out	jp invalid_instruction


;-------------------------------------------------------------------------------------------------------
; Non Z80 "O" instructions follow (Directives)
;-------------------------------------------------------------------------------------------------------

org_directive

	ld hl,opcode_arg1_string
	call handle_numeric_expression	;ORG can return error on first pass if label not found
	ret nz				;as rest of code location depends on it
	ld hl,(bin_addr)
	xor a
	sbc hl,de
	jr z,org_ok
	jr c,org_ok
	ld a,10				;error 10 - org out of sequence
	or a
	ret
org_ok	ld (bin_addr),de
	xor a
	ret
	

;=======================================================================================================
