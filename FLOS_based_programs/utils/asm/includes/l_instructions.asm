;----------------------------------------------------------------------------------------------------------

l_code	ld a,(ix+1)			;is it an "LD " instruction?
	cp "d"
	jp nz,not_ld
	ld a,(ix+2)
	or a
	jp nz,not_ld
	
	ld ix,opcode_arg1_string		;does either operand refer to a 16bit CPU register pair?
	call id_dd_operand			;BC DE HL SP
	jp c,ld_16bit
	call id_hlixiy_operand		;HL IX IY
	jp c,ld_16bit
	ld ix,opcode_arg2_string
	call id_dd_operand
	jp c,ld_16bit
	call id_hlixiy_operand
	jp c,ld_16bit
		
	
;--------- 8 bit loads ----------------------------------------------------------------------------------
	
	
	ld ix,opcode_arg1_string		; 8-bit load group: Is it an LD r,r type LD opcode?
	call id_8bit_reg_operand
	jp nc,not_ld_r_x
	cp 8			
	jp nc,ld_ir_x			; if first operand is "I" or "R", go to special case
	rlca
	rlca
	rlca
	ld (operand1_reg_sel),a		; adjust bit position for dst operand CPU register
		
	ld ix,opcode_arg2_string
	call id_8bit_reg_operand
	jr nc,not_ld_r_r			; must have two single-char operands
	cp 8
	jp nc,ld_x_ir			; if second operand is "I" or "R", go to special case
	
ld_r_r	ld hl,operand1_reg_sel		; LD r,r opcode
	or (hl)			
	or $40
	call output_data_byte
	xor a
	ret	
	
ld_r_imm	ld a,(operand1_reg_sel)		; LD r,immediate opcode
	or %00000110		
	call output_data_byte
	ld hl,opcode_arg2_string
	call get_8bit_number
	ret nz
	ld a,e
	call output_data_byte
	xor a
	ret	
		
not_ld_r_r

	ld ix,opcode_arg2_string		; first operand is 8bit reg
	ld a,(ix)
	cp "("				; if second operand is not bracketed, it is taken as immediate 
	jr nz,ld_r_imm		 
	call id_indirect_hlixiy_operand	; is the second operand "(hl)", "(ix+)", or "(iy+)" ?
	jr nc,not_ld_r_indhlixiy	
	call output_ixiy_prefix
	ld a,(operand1_reg_sel)
	or %01000110
	call output_data_byte
	call output_displacement_byte
	ret


not_ld_r_indhlixiy

	ld a,(opcode_arg1_string)		; is 1st operand "A", and 2nd operand (BC) or (DE)?
	cp "a"
	jp nz,invalid_instruction
	
	ld ix,opcode_arg2_string
	ld a,(ix)
	cp "("
	jr nz,not_ld_r_x
	ld a,(ix+3)
	cp ")"
	jr nz,not_lda_irp
	ld d,(ix+1)
	ld e,(ix+2)
	ld b,$0a
	ld a,"b"				;(BC)?	
	cp d
	jr nz,not_bc1
	ld a,"c"
	cp e
	jr z,got_irp
not_bc1	ld b,$1a
	ld a,"d"				;(DE)?
	cp d
	jr nz,not_lda_irp
	ld a,"e"
	cp e
	jr nz,not_lda_irp
got_irp	ld a,b
	call output_data_byte
	xor a
	ret
	
	
not_lda_irp

	ld a,$3a				;assume to be LD A,(nn)
	call output_data_byte
	ld hl,opcode_arg2_string
	call get_16bit_number
	ret nz
	call output_data_word
	xor a
	ret



not_ld_r_x	


	ld ix,opcode_arg2_string		; is second operand an 8-bit register?
	call id_8bit_reg_operand
	jr nc,not_ld_x_r
	ld (operand2_reg_sel),a		; store second operand 8-bit reg

	ld a,(opcode_arg2_string)		; is 2nd operand "A"
	cp "a"
	jp nz,not_ld_irp_a
	
	ld ix,opcode_arg1_string		; is 1st operand (BC) or (DE)?
	ld a,(ix)
	cp "("
	jr nz,not_ld_irp_a
	ld a,(ix+3)
	cp ")"
	jr nz,not_ld_irp_a
	ld d,(ix+1)
	ld e,(ix+2)
	ld b,$02
	ld a,"b"				;(BC)?	
	cp d
	jr nz,not_bc2
	ld a,"c"
	cp e
	jr z,got_irp2
not_bc2	ld b,$12
	ld a,"d"				;(DE)?
	cp d
	jr nz,not_ld_irp_a
	ld a,"e"
	cp e
	jr nz,not_ld_irp_a
got_irp2	ld a,b
	call output_data_byte
	xor a
	ret


not_ld_irp_a

	ld ix,opcode_arg1_string		; is 1st operand "(hl)", "(ix+)", "(iy+)" ?
	call id_indirect_hlixiy_operand	
	jr nc,not_ld_hlixiy_a	
	call output_ixiy_prefix
	ld a,(operand2_reg_sel)
	or %01110000
	call output_data_byte
	call output_displacement_byte
	ret



not_ld_hlixiy_a

	ld a,(opcode_arg1_string)		; is 1st operand "(nn)" ?
	cp "("
	jp nz,invalid_instruction
	ld a,$32
	call output_data_byte
	ld hl,opcode_arg1_string
	call get_16bit_number
	ret nz
	call output_data_word
	xor a
	ret


not_ld_x_r


	ld ix,opcode_arg1_string		; second operand is immediate byte,
	call id_indirect_hlixiy_operand	; is first operand "(hl)", "(ix+)", "(iy+)" ?
	jp nc,invalid_instruction
	call output_ixiy_prefix
	ld a,$36
	call output_data_byte
	call output_displacement_byte
	ret nz
	ld hl,opcode_arg2_string
	call get_8bit_number
	ret nz
	ld a,e
	call output_data_byte
	xor a
	ret	




ld_ir_x	ld a,(opcode_arg2_string)		;is it a LD I,A?
	cp "a"
	jp nz,invalid_instruction
	ld a,(opcode_arg1_string)
	cp "i"
	jr nz,notldia
	ld de,$47ed
	call output_data_word
	xor a
	ret
notldia	ld de,$4fed			;must be a LD I,R
	call output_data_word
	xor a
	ret
	
	
ld_x_ir	ld a,(opcode_arg1_string)		;is it a LD A,I?
	cp "a"
	jp nz,invalid_instruction
	ld a,(opcode_arg2_string)
	cp "i"
	jr nz,notldai
	ld de,$57ed
	call output_data_word
	xor a
	ret
notldai	ld de,$5fed			;must be a LD A,R
	call output_data_word
	xor a
	ret
		
		
;-------- 16 bit loads ----------------------------------------------------------------------------------------------

	
ld_16bit	ld ix,opcode_arg1_string	
	call id_dd_operand
	jr nc,dst_not_dd_operand
	rlca
	rlca
	rlca
	rlca
	ld (operand1_reg_sel),a
	
	ld a,(ix)			
	cp "s"				;is dest dd operand SP?
	jr nz,not_ddsp
	ld ix,opcode_arg2_string
	call id_hlixiy_operand		;if so, check source operand for HL IX IY
	jr nc,not_ddsp
	call output_ixiy_prefix		;if source is HL IX or IY, so special case: LD SP,xx
	ld a,$f9
	call output_data_byte
	xor a
	ret
		
not_ddsp	ld a,(opcode_arg2_string)	
	cp "("				; is source operand indirect?
	jr z,indirect_ld_dd

	ld a,(operand1_reg_sel)		; LD dd, nn
	or %00000001
ld16ok	call output_data_byte
	ld hl,opcode_arg2_string
	call get_16bit_number
	ret nz
	call output_data_word
	xor a
	ret
	
	
indirect_ld_dd
	
	ld a,(opcode_arg1_string)		; LD dd,(nn). If dd = HL there is a special case opcode
	cp "h"
	jr nz,nothlind
	ld a,$2a
	jr ld16ok
	
nothlind	ld a,$ed
	call output_data_byte
	ld a,(operand1_reg_sel)
	or %01001011
	jr ld16ok
		
		
dst_not_dd_operand

	ld ix,opcode_arg1_string		; is dest a LD HL/IX/IY opcode?
	call id_hlixiy_operand
	jp nc,try_ind_dd

	ld a,(opcode_arg2_string)	
	cp "("				; is source operand indirect?
	jr z,indirect_ld_ixiy
	call output_ixiy_prefix		; LD ix/iy, nn
	ld a,$21
	jr ld16ok
	
	
indirect_ld_ixiy
	
	call output_ixiy_prefix		; LD ix/iy, (nn)
	ld a,$2a
	jr ld16ok


try_ind_dd
	
	ld a,(opcode_arg1_string)		;is this a LD (nn),dd?
	cp "("
	jp nz,invalid_instruction
	
	ld ix,opcode_arg2_string
	call id_dd_operand
	jr nc,src_not_dd_operand
	rlca
	rlca
	rlca
	rlca
	ld (operand2_reg_sel),a

	ld a,(opcode_arg2_string)		; LD (nn),dd. If dd = HL there is a special case opcode
	cp "h"
	jr nz,nothlind2
	ld a,$22
	jr ld16ok_b
	
nothlind2	ld a,$ed
	call output_data_byte
	ld a,(operand2_reg_sel)
	or %01000011
	jr ld16ok_b

src_not_dd_operand

	ld ix,opcode_arg2_string		; is dest a LD HL/IX/IY opcode?
	call id_hlixiy_operand
	jp nc,invalid_instruction
	call output_ixiy_prefix		; LD (nn),ix/iy
	ld a,$22
ld16ok_b	call output_data_byte
	ld hl,opcode_arg1_string
	call get_16bit_number
	ret nz
	call output_data_word
	xor a
	ret
	
;-------- other 'L' opcodes ----------------------------------------------------------------------------------------

	
not_ld	ld a,$a0
	ld (opcode_stem),a
	inc ix
	inc ix
	jp block_op_handler			; for LDIR, LDI, LDIR, LDD instructions


;===================================================================================================================
