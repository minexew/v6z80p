
r_code	ld a,(ix+1)			;is it a "RES" instruction?
	cp "e"
	jp nz,not_rex
	ld a,(ix+2)
	cp "s"
	jp nz,not_res
	ld a,(ix+3)
	or a
	jp nz,not_res

	ld a,%10000000
	ld (opcode_stem),a
	jp handle_bitwise_instruction
	
;-------------------------------------------------------------------------------------------------------

not_res	ld a,(ix+2)
	cp "t"
	jp nz,invalid_instruction
	ld a,(ix+3)
	or a
	jr nz,try_retx
	ld a,(opcode_arg1_string)
	or a
	jr nz,try_retncc
	ld a,$c9
	call output_data_byte		;RET instruction
	xor a
	ret
	

try_retncc

	ld ix,opcode_arg1_string
	call id_cc_operand
	jp nc,invalid_instruction
	rlca
	rlca
	rlca
	or %11000000
	call output_data_byte		;RET cc instruction
	xor a
	ret
	
;------------------------------------------------------------------------------------------------------

try_retx	ld a,(ix+3)
	cp "i"
	jr nz,not_reti
	ld a,(ix+4)
	or a
	jp nz,invalid_instruction
	ld de,$4ded
	call output_data_word		;RETI instruction
	xor a	
	ret

;------------------------------------------------------------------------------------------------------
	
not_reti	ld a,(ix+3)
	cp "n"
	jp nz,invalid_instruction
	ld a,(ix+4)
	or a
	jp nz,invalid_instruction
	ld de,$45ed
	call output_data_word		;RETN instruction
	xor a	
	ret

;------------------------------------------------------------------------------------------------------

not_rex	ld a,(ix+1)
	cp "l"
	jp nz,not_rl
	ld a,(ix+2)
	or a
	jr nz,try_rlx
	
	ld a,$10
	ld (opcode_stem),a			;rl stem
	
do_as_rl	ld ix,opcode_arg1_string
	call id_indirect_hlixiy_operand
	jp nc,not_rli
	ld a,%110
	ld (operand1_reg_sel),a
	jr rl_reg
	
not_rli	call id_8bit_reg_operand
	ld (operand1_reg_sel),a
	jp nc,invalid_instruction
	cp 8
	jp nc,invalid_instruction		;if I or R reg, invalid instruction
	
rl_reg	call output_ixiy_prefix
	ld a,$cb
	call output_data_byte
	call output_displacement_byte
	ld a,(opcode_stem)
	ld b,a
	ld a,(operand1_reg_sel)
	or b
	call output_data_byte		;rl x instruction
	xor a
	ret

;---------------------------------------------------------------------------------------------------------
	
try_rlx	ld a,(ix+2)
	cp "a"
	jr nz,not_rla
	ld a,(ix+3)
	or a
	jp nz,invalid_instruction
	ld a,$17
	call output_data_byte		;rla instruction
	xor a
	ret
	
;------------------------------------------------------------------------------------------------------

not_rla	ld a,(ix+2)
	cp "c"
	jr nz,not_rlc
	ld a,(ix+3)
	or a
	jr nz,try_rlcx
	ld a,$00
	ld (opcode_stem),a			;rlc stem
	jr do_as_rl

;------------------------------------------------------------------------------------------------------
	
try_rlcx	ld a,(ix+3)
	cp "a"
	jp nz,invalid_instruction
	ld a,(ix+4)
	or a
	jp nz,invalid_instruction
	ld a,$07
	call output_data_byte		;rlca instruction
	xor a
	ret

;------------------------------------------------------------------------------------------------------

not_rlc	ld a,(ix+2)
	cp "d"
	jr nz,not_rl
	ld a,(ix+3)
	or a
	jr nz,not_rl	
	ld de,$6fed
	call output_data_word		;rld instruction
	xor a
	ret
	
;------------------------------------------------------------------------------------------------------

not_rl	ld a,(ix+1)
	cp "r"
	jr nz,not_rr
	ld a,(ix+2)
	or a
	jr nz,try_rrx
	ld a,$18
	ld (opcode_stem),a			;rr stem
	jp do_as_rl

;------------------------------------------------------------------------------------------------------

try_rrx	ld a,(ix+2)
	cp "a"
	jr nz,not_rra
	ld a,(ix+3)
	or a
	jp nz,invalid_instruction
	ld a,$1f
	call output_data_byte		;rra instruction
	xor a
	ret

;------------------------------------------------------------------------------------------------------

not_rra	ld a,(ix+2)
	cp "c"
	jr nz,not_rrc
	ld a,(ix+3)
	or a
	jr nz,try_rrcx
	ld a,$08
	ld (opcode_stem),a			;rrc stem
	jp do_as_rl

;------------------------------------------------------------------------------------------------------
	
try_rrcx	ld a,(ix+3)
	cp "a"
	jp nz,invalid_instruction
	ld a,(ix+4)
	or a
	jp nz,invalid_instruction
	ld a,$0f
	call output_data_byte		;rrca instruction
	xor a
	ret

;------------------------------------------------------------------------------------------------------

not_rrc	ld a,(ix+2)
	cp "d"
	jr nz,not_rr
	ld a,(ix+3)
	or a
	jr nz,not_rr	
	ld de,$67ed
	call output_data_word		;rrd instruction
	xor a
	ret

;-------------------------------------------------------------------------------------------------------

not_rr	ld a,(ix+1)
	cp "s"
	jr nz,not_rst
	ld a,(ix+2)
	cp "t"
	jr nz,not_rst
	ld a,(ix+3)
	or a
	jr nz,not_rst

	ld a,(opcode_arg2_string)
	or a
	jp nz,invalid_instruction
	ld ix,opcode_arg1_string
	call id_8bit_reg_operand
	jp c,invalid_instruction
	ld hl,opcode_arg1_string
	call get_8bit_number
	ret nz
	ld a,e
	and %11000111
	jp nz,invalid_instruction
	ld a,e
	or %11000111
	call output_data_byte		;rst n
	xor a
	ret
		

;--------------------------------------------------------------------------------------------------------

not_rst

	jp invalid_instruction

;=======================================================================================================

