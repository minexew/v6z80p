
e_code
	ld a,(ix+1)		;EI?
	cp "i"
	jr nz,not_ei
	ld a,(ix+2)
	or a
	jr nz,not_ei
	
	ld a,$fb
	call output_data_byte
	xor a
	ret
	
;--------------------------------------------------------------------------------------------------------

not_ei
	ld a,(ix+1)
	cp "x"
	jp nz,not_ex
	ld a,(ix+2)
	or a
	jr z,got_ex
	
	cp "x"
	jp nz,not_ex
	ld a,(ix+3)
	or a
	jp nz,not_ex
	
	ld a,$d9			;exx
	call output_data_byte
	xor a
	ret
	
got_ex	ld ix,opcode_arg1_string	;ex instruction
	ld a,(ix)
	cp "("
	jr nz,not_exsp
	ld a,(ix+1)
	cp "s"
	jr nz,not_exsp
	ld a,(ix+2)
	cp "p"
	jr nz,not_exsp
	ld a,(ix+3)
	cp ")"
	jr nz,not_exsp
	ld a,(ix+4)
	or a
	jr nz,not_exsp
	ld ix,opcode_arg2_string	;ex (sp),hl/ix/iy
	call id_hlixiy_operand
	jp nc,invalid_instruction
	call output_ixiy_prefix
	ld a,$e3
	call output_data_byte
	xor a
	ret

not_exsp	ld ix,opcode_arg1_string
	ld a,(ix)
	cp "a"
	jr nz,not_exafaf
	ld a,(ix+1)
	cp "f"
	jr nz,not_exafaf
	ld a,(ix+2)
	or a
	jp nz,invalid_instruction
	
	ld ix,opcode_arg2_string	;dont bother checking for ' after 2nd AF due to it being seen as open quote
	ld a,(ix)			;by isolation code
	cp "a"
	jp nz,invalid_instruction
	ld a,(ix+1)
	cp "f"
	jp nz,invalid_instruction
	
	ld a,08			;ex af,af'
	call output_data_byte
	xor a
	ret

not_exafaf	

	ld ix,opcode_arg1_string
	ld a,(ix)
	cp "d"
	jp nz,invalid_instruction
	ld a,(ix+1)
	cp "e"
	jp nz,invalid_instruction
	ld a,(ix+2)
	or a
	jp nz,invalid_instruction
	
	ld ix,opcode_arg2_string
	ld a,(ix)
	cp "h"
	jp nz,invalid_instruction
	ld a,(ix+1)
	cp "l"
	jp nz,invalid_instruction
	ld a,(ix+2)
	or a
	jp nz,invalid_instruction
	
	ld a,$eb			;ex de,hl
	call output_data_byte
	xor a
	ret

;--------------------------------------------------------------------------------------------------------
; END DIRECTIVE - NON Z80 INSTRUCTION
;--------------------------------------------------------------------------------------------------------
	
not_ex	ld a,(ix+1)		;if end just return error 1 - end of source
	cp "n"
	jr nz,not_end
	ld a,(ix+2)
	cp "d"
	jr nz,not_end
	ld a,(ix+3)
	or a
	ret z
	
not_end	jp invalid_instruction

;=======================================================================================================

