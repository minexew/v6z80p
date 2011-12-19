
j_code

;-----------------------------------------------------------------------------------------------------

	ld a,(ix+1)		;is it "JP?"
	cp "p"
	jr nz,not_jp
	ld a,(ix+2)
	or a
	jp nz,invalid_instruction
	
	ld ix,opcode_arg1_string
	ld a,(ix)			; is it a JP (HL) (IX) (IY)
	cp "("
	jr nz,not_jphlixiy
	ld a,(ix+3)
	cp ")"
	jr nz,not_jphlixiy
	ld a,(ix+4)
	or a
	jr nz,not_jphlixiy
	ld a,(ix+1)
	cp "i"
	jr z,ixiyjp
	cp "h"
	jp nz,invalid_instruction
	ld a,(ix+2)
	cp "l"
	jp nz,invalid_instruction
	jr z,dojphl
ixiyjp	ld c,$dd
	ld a,(ix+2)
	cp "x"
	jr z,dojpixiy
	ld c,$fd
	cp "y"
	jp nz,invalid_instruction
dojpixiy	ld a,c
	call output_data_byte	
dojphl	ld a,$e9
	call output_data_byte
	xor a
	ret
	
not_jphlixiy

	ld ix,opcode_arg1_string
	call id_cc_operand
	jp nc,no_cc_req
	rlca
	rlca
	rlca
	or %11000010
	call output_data_byte	; conditional jp

	ld hl,opcode_arg2_string
jp_addr	call get_16bit_number
	ret nz
	call output_data_word
	xor a
	ret
	
no_cc_req	ld a,%11000011		;unconditional jp
	call output_data_byte
	ld hl,opcode_arg1_string
	jr jp_addr	

;-----------------------------------------------------------------------------------------------------

not_jp	cp "r"			; is it a JR?
	jr nz,not_jr
	ld a,(ix+2)
	or a
	jr nz,not_jr
	
	ld ix,opcode_arg1_string
	call id_cc_operand
	jp nc,jr_no_cc_req
	cp 4			; only nz,z,c,nc allowed for JR conditions
	jp nc,invalid_instruction	
	rlca
	rlca
	rlca
	or %00100000
	call output_data_byte	; conditional jr

	ld hl,opcode_arg2_string
jr_addr	call get_8bit_relative_address
	ret nz
	ld a,e
	call output_data_byte
	xor a
	ret
	
jr_no_cc_req	

	ld a,%00011000		;unconditional jr
	call output_data_byte
	ld hl,opcode_arg1_string
	jr jr_addr	




;=======================================================================================================

not_jr
	jp invalid_instruction

;=======================================================================================================

