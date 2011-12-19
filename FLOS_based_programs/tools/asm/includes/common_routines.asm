;----------------------------------------------------------------------------------------------------
;mnemonic argument identification routines
;----------------------------------------------------------------------------------------------------

; set IX to opcode_location when calling each routine
; on return carry set if match with a CPU reg is found, a = arg type
; otherwise, examine ZF: Set if no operand, ZF not set if not a single char

id_8bit_reg_operand

	ld a,(ix+1)		;is arg a CPU reg: B,C,D,E,H,L,A,I or R?
	or a
	ret nz
	
	ld a,(ix)
	or a
	ret z

	ld b,0
	cp "b"			;if B, b = 0
	jr z,got_reg
	
	inc b
	cp "c"
	jr z,got_reg		;if C, b = 1
	
	inc b
	cp "d"
	jr z,got_reg		;if D, b = 2
	
	inc b
	cp "e"
	jr z,got_reg		;if E, b = 3
	
	inc b
	cp "h"
	jr z,got_reg		;if H, b = 4
	
	inc b
	cp "l"
	jr z,got_reg		;if L, b = 5
	
	ld b,7			
	cp "a"	
	jr z,got_reg		;if A, b = 7
	
	inc b
	cp "i"
	jr z,got_reg		;if I, b = 8
		
	inc b			
	cp "r"
	jr z,got_reg		;if R, b = 9
	
	ld a,$ff			
	or a
	ret
	
got_reg	ld a,b
	scf	
	ret			

no_operand

	xor a
	ret


id_indirect_hlixiy_operand

	xor a
	ld (ixiy_prefix),a
	ld de,0
	ld (displacement_word),de
	
	ld a,(ix)
	or a
	ret z

	ld a,(ix)
	cp "("			;is arg indirect "(HL)", "(IX)", "(IY)" "(IX+" or "(IX-" ?
	jr nz,notind
	
	ld a,(ix+1)
	cp "h"
	jr nz,notindhl
	ld a,(ix+2)
	cp "l"
	jr nz,notind
	ld a,(ix+3)
	cp ")"
	jr nz,notind
	jr gotind
	
notindhl	ld a,(ix+1)
	cp "i"
	jr nz,notind
	ld a,(ix+2)
	cp "x"
	jr nz,notindix1
	ld a,(ix+3)
	cp ")"
	jr z,gotindix1
	cp "+"
	jr z,gotindix1d
	cp "-"
	jr z,gotindix1d
	xor a
	ret
	
gotindix1d
	
	call ixiy_disp_required
	scf
	ret nz
gotindix1	ld a,$dd
	ld (ixiy_prefix),a
	scf
	ret
		
notindix1	ld a,(ix+2)
	cp "y"
	jr nz,notind
	ld a,(ix+3)
	cp ")"
	jr z,gotindiy1
	cp "+"
	jr z,gotindiy1d
	cp "-"
	jr z,gotindiy1d
notind	xor a
	ret

gotindiy1d
	
	call ixiy_disp_required
	scf
	ret nz	
gotindiy1	ld a,$fd
	ld (ixiy_prefix),a
	
gotind	scf
	ret
	

	
ixiy_disp_required

	push ix			; a +/- displacement was included, evaluate it
	pop hl
	call get_16bit_number
	ret nz
idispok	ld (displacement_word),de
	xor a
	ret
	
	
	



id_dd_operand

	ld a,(ix)
	or a
	ret z
	
	ld a,(ix+1)
	or a
	ret z
	
	ld a,(ix+2)
	or a
	ret nz
				
	ld b,0
	ld d,(ix)			;$00 if arg = BC
	ld e,(ix+1)
	ld a,d
	cp "b"	
	jr nz,dd_not_bc
	ld a,e
	cp "c"	
	jr z,dd_found

dd_not_bc	ld b,$01
	ld a,d			;$01 if arg = DE
	cp "d"
	jr nz,dd_not_de
	ld a,e
	cp "e"	
	jr z,dd_found

dd_not_de	ld b,$02
	ld a,d			;$02 if arg = HL
	cp "h"
	jr nz,dd_not_hl
	ld a,e
	cp "l"	
	jr z,dd_found


dd_not_hl	ld b,$03
	ld a,d			;$03 if arg = SP
	cp "s"
	jr nz,dd_not_sp
	ld a,e
	cp "p"	
	jr nz,dd_not_sp
	
dd_found	ld a,b
	scf			;carry set on return if dd found
	ret

dd_not_sp	xor a
	ret
	






id_qq_operand

	ld a,(ix)
	or a
	ret z
	
	ld a,(ix+1)
	or a
	ret z
	
	ld a,(ix+2)
	or a
	ret nz
				
	ld b,0
	ld d,(ix)			;$00 if arg = BC
	ld e,(ix+1)
	ld a,d
	cp "b"	
	jr nz,qq_not_bc
	ld a,e
	cp "c"	
	jr z,qq_found

qq_not_bc	ld b,$01
	ld a,d			;$01 if arg = DE
	cp "d"
	jr nz,qq_not_de
	ld a,e
	cp "e"	
	jr z,qq_found

qq_not_de	ld b,$02
	ld a,d			;$02 if arg = HL
	cp "h"
	jr nz,qq_not_hl
	ld a,e
	cp "l"	
	jr z,qq_found


qq_not_hl	ld b,$03
	ld a,d			;$03 if arg = AF
	cp "a"
	jr nz,qq_not_af
	ld a,e
	cp "f"	
	jr nz,qq_not_af
	
qq_found	ld a,b
	scf			;carry set on return if dd found
	ret

qq_not_af	xor a
	ret
	






id_bcdeixiysp_operand

	ld a,(ix)
	or a
	ret z
	
	ld a,(ix+1)
	or a
	ret z
	
	ld a,(ix+2)
	or a
	ret nz
				
	ld b,0
	ld d,(ix)			;$00 if arg = BC
	ld e,(ix+1)
	ld a,d
	cp "b"	
	jr nz,d2_not_bc
	ld a,e
	cp "c"	
	jr z,d2_found

d2_not_bc	ld b,$01
	ld a,d			;$01 if arg = DE
	cp "d"
	jr nz,d2_not_de
	ld a,e
	cp "e"	
	jr z,d2_found

d2_not_de	ld b,$02
	ld a,d			;$02 if arg = IX
	cp "i"
	jr nz,d2_not_iy
	ld a,e
	cp "x"	
	jr z,d2_found

d2_not_ix	ld b,$02			;also $02 if arg = IY
	ld a,e
	cp "y"	
	jr z,d2_found

d2_not_iy	ld b,$03
	ld a,d			;$03 if arg = SP
	cp "s"
	jr nz,d2_not_sp
	ld a,e
	cp "p"	
	jr nz,d2_not_sp
	
d2_found	ld a,b
	scf			;carry set on return if dd found
	ret

d2_not_sp	xor a
	ret
	






id_hlixiy_operand

	xor a
	ld (ixiy_prefix),a
	
	ld a,(ix+2)
	or a
	ret nz
				
	ld d,(ix)			
	ld e,(ix+1)
	ld a,d
	cp "h"	
	jr nz,not_hl2
	ld a,e
	cp "l"	
	jr z,hlixiy_found

not_hl2	ld a,d		
	cp "i"
	jr nz,not_ix
	ld a,e
	cp "x"	
	jr nz,not_ix
	ld a,$dd
	ld (ixiy_prefix),a
	jr hlixiy_found
		
not_ix	ld a,d			
	cp "i"
	jr nz,not_iy
	ld a,e
	cp "y"	
	jr nz,not_iy
	ld a,$fd
	ld (ixiy_prefix),a

hlixiy_found
	
	scf			;carry set on return if hl,ix or iy found
	ret

not_iy	xor a
	ret




id_cc_operand

	ld a,(ix)			;find condition code 
	or a
	ret z
	
	ld a,(ix+1)
	or a
	jr nz,cc_notsch		;single char condition code?
	
	ld b,$01			
	ld a,(ix)
	cp "z"	
	jr z,got_cc		;b = $1 if cc = "z"
	ld b,$03
	cp "c"
	jr z,got_cc		;b = $3 if cc = "c"
	ld b,$06
	cp "p"
	jr z,got_cc		;b = $6 if cc = "p"
	ld b,$07			
	cp "m"
	jr z,got_cc		;b = $7 if cc = "m"
	
	jr not_cc			
	
cc_notsch	ld a,(ix+2)
	or a
	ret nz
	ld b,$0
	ld d,(ix)
	ld e,(ix+1)
	ld a,d
	cp "n"
	jr nz,not_ccn
	ld a,e
	cp "z"
	jr z,got_cc		;b = $0 if cc = "nz"
	ld b,$2
	cp "c"
	jr z,got_cc		;b = $2 if cc = "nc"

not_ccn	ld b,$4
	ld d,(ix)
	ld e,(ix+1)
	ld a,d
	cp "p"
	jr nz,not_cc
	ld a,e
	cp "o"
	jr z,got_cc		;b = $4 if cc = "po"
	inc b
	cp "e"
	jr z,got_cc		;b = $5 if cc = "pe"

not_cc	xor a
	ret
	
got_cc	ld a,b
	scf
	ret

	
;----------------------------------------------------------------------------------------------------------------------


standard_alu_instruction
	
	ld ix,opcode_arg1_string		
	ld a,(opcode_arg2_string)
	or a
	jr z,sing_opera
	
	ld ix,opcode_arg2_string		; dest + src operands
	ld a,(opcode_arg1_string)
	cp "a"
	jp nz,invalid_instruction
	ld a,(opcode_arg1_string+1)		; arg1 must be "a"
	or a
	jp nz,invalid_instruction

sing_opera	
	
	call id_8bit_reg_operand		; is operand a,b,c,d,e,h,l,i,r ?
	jp nc,not_cpu_reg_src
	cp 8			
	jp nc,invalid_instruction		; if operand is "I" or "R", instruction is bad
	
	ld b,a
	ld a,(opcode_stem)
	or b
	call output_data_byte		; output source = "a,b,c,d,e,h,l" type opcode
	xor a
	ret
	
not_cpu_reg_src

	ld a,(ix)
	cp "("				; if operand is not bracketed, it is taken as immediate 
	jr nz,reg_imm		 
	call id_indirect_hlixiy_operand	; is the second operand "(hl)", "(ix+)", or "(iy+)" ?
	jp nc,invalid_instruction	
	call output_ixiy_prefix
	ld a,(opcode_stem)
	or %110
	call output_data_byte
	call output_displacement_byte
	ret

reg_imm	ld a,(opcode_stem)			; arg = immediate byte
	or %01000110
	call output_data_byte
	push ix
	pop hl
	call get_8bit_number
	ret nz
	ld a,e
	call output_data_byte
	xor a
	ret

		
;=======================================================================================================

handle_bitwise_instruction


	ld hl,opcode_arg1_string		;BIT/RES/SET n,r
	call get_8bit_number
	ret nz
	ld a,e
	cp 8
	jp nc,number_out_of_range
	rlca
	rlca
	rlca
	ld (operand1_reg_sel),a		;the bit that is affected
	
	ld ix,opcode_arg2_string
	call id_8bit_reg_operand
	jr nc,bmi_not_sr
	cp 8
	jp nc,invalid_instruction		;regs A,B,C,D,E,H,L allowed only
	ld (operand2_reg_sel),a
	
	ld a,$cb
	call output_data_byte
	
	ld a,(operand1_reg_sel)
	ld b,a
	ld a,(operand2_reg_sel)
	ld c,a

bitwise_done
	
	ld a,(opcode_stem)
	or b
	or c
	call output_data_byte
	xor a
	ret
	
bmi_not_sr
	call id_indirect_hlixiy_operand	;BIT/RES/SET n,(ix)/(iy)/(hl) ?
	jp nc,invalid_instruction
	
	call output_ixiy_prefix
	ld a,$cb
	call output_data_byte
	call output_displacement_byte
	ret nz
	ld a,(operand1_reg_sel)
	ld b,a
	ld c,%110
	jr bitwise_done
	

;=======================================================================================================

block_op_handler
	
	
	ld a,(ix)
	cp "i"				;is it an xxI instruction?
	jr nz,blnot_ir
	ld a,(ix+1)
	or a
	jr nz,blnot_i
	ld a,$ed
	call output_data_byte
	ld a,(opcode_stem)
	call output_data_byte
	xor a
	ret
	
blnot_i	ld a,(ix+1)
	cp "r"				;is it an xxIR instruction?
	jp nz,invalid_instruction
	ld a,(ix+2)
	or a
	jp nz,invalid_instruction
	ld a,$ed
	call output_data_byte
	ld a,(opcode_stem)
	or %10000
	call output_data_byte
	xor a
	ret

blnot_ir	cp "d"				;is it an xxD instruction?
	jp nz,invalid_instruction
	ld a,(ix+1)
	or a
	jr nz,blnot_d
	ld a,$ed
	call output_data_byte
	ld a,(opcode_stem)
	or %1000
	call output_data_byte
	xor a
	ret
	
blnot_d	ld a,(ix+1)
	cp "r"				;is it an xxDR instruction?
	jp nz,invalid_instruction
	ld a,(ix+2)
	or a
	jp nz,invalid_instruction
	ld a,$ed
	call output_data_byte
	ld a,(opcode_stem)
	or %11000
	call output_data_byte
	xor a
	ret
		
		
;=======================================================================================================

standard_16bit_instruction

	ld a,(ixiy_prefix)		;is dest ix or iy?
	or a
	jr z,normal_hl_dest
	
	ld ix,opcode_arg2_string
	call id_bcdeixiysp_operand
	jp nc,invalid_instruction
	jr got_reg16
	
normal_hl_dest

	ld ix,opcode_arg2_string	
	call id_dd_operand	
	jp nc,invalid_instruction
got_reg16	rrca
	rrca
	rrca
	rrca
	ld (operand1_reg_sel),a

	call output_ixiy_prefix
	
	ld a,(operand1_reg_sel)	
	ld b,a
	ld a,(opcode_stem)
	or b
	call output_data_byte
	xor a
	ret

;=======================================================================================================

type_2_16bit_opcode

	call id_hlixiy_operand	; for bc,de,hl,sp,ix or iy	
	jr nc,nothli_op
	ld a,$02
	jr reg16op
nothli_op	call id_dd_operand
	jp nc,invalid_instruction
reg16op	ld (operand1_reg_sel),a

	call output_ixiy_prefix
	
	ld a,(opcode_stem)		
	ld b,a
	ld a,(operand1_reg_sel)
	rlca
	rlca
	rlca
	rlca
	or b
	call output_data_byte
	xor a
	ret


;=======================================================================================================
	
	
type_3_16bit_opcode

	call id_hlixiy_operand	; for bc,de,hl,af,ix or iy
	jr nc,nhli_op2
	ld a,$02
	jr reg16op2
nhli_op2	call id_qq_operand
	jp nc,invalid_instruction
reg16op2	ld (operand1_reg_sel),a

	call output_ixiy_prefix
	
	ld a,(opcode_stem)		
	ld b,a
	ld a,(operand1_reg_sel)
	rlca
	rlca
	rlca
	rlca
	or b
	call output_data_byte
	xor a
	ret

	
;=======================================================================================================

shifted_r_alu_instruction
	
	ld ix,opcode_arg1_string		; should be no second operand
	ld a,(opcode_arg2_string)
	jp nz,invalid_instruction	

	call id_8bit_reg_operand
	jp nc,r_not_cpu_reg_src
	cp 8			
	jp nc,invalid_instruction		; if first operand is "I" or "R", instruction is bad
	
	rlca
	rlca
	rlca 
	ld b,a
	ld a,(opcode_stem)
	or b
	call output_data_byte		; output source = "a,b,c,d,e,h,l" type opcode
	xor a
	ret
	
r_not_cpu_reg_src

	ld a,(ix)
	cp "("			
	jp nz,invalid_instruction		 
	call id_indirect_hlixiy_operand	; is the second operand "(hl)", "(ix+)", or "(iy+)" ?
	jp nc,invalid_instruction	
	call output_ixiy_prefix
	ld a,(opcode_stem)
	or %110000
	call output_data_byte
	call output_displacement_byte
	ret

		
;=======================================================================================================


no_args_required

	push hl
	ld a,(opcode_arg1_string)
	ld hl,opcode_arg2_string
	or (hl)
	pop hl
	ret z
	ld a,8
	or a
	ret
		

;=======================================================================================================

	