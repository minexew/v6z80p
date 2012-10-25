;----------------------------------------------------------------------------------------------------------

a_code	ld a,(ix+1)		;is it an "and" instruction?
	cp "n"
	jp nz,not_and
	ld a,(ix+2)
	cp "d"
	jp nz,not_and
	ld a,(ix+3)
	or a
	jp nz,not_and
	
	ld a,$a0			;"and" instruction stem
	ld (opcode_stem),a
	jp standard_alu_instruction


;----------------------------------------------------------------------------------------------------------


not_and	ld a,(ix+1)		;is it an adc instuction?
	cp "d"
	jp nz,invalid_instruction	;is it "ad*"?
	ld a,(ix+2)		
	cp "c"
	jr nz,not_adc
	ld a,(ix+3)
	or a
	jp nz,invalid_instruction
	
	ld ix,opcode_arg1_string
	call id_hlixiy_operand	;is a 16 bit adc?
	jr c,adc_hl
	
adc8	ld a,$88			;"adc a" opcode
	ld (opcode_stem),a
	jp standard_alu_instruction

adc_hl	ld a,(ix)			;only "adc hl" is allowed (no ix/iy) 
	cp "h"
	jp nz,invalid_instruction
	ld a,$ed			
	call output_data_byte
	ld a,%01001010
	ld (opcode_stem),a
	jp normal_hl_dest
	
;---------------------------------------------------------------------------------------------------------

not_adc	cp "d"			;add
	jp nz,invalid_instruction
	ld a,(ix+3)
	or a
	jp nz,invalid_instruction
	ld ix,opcode_arg1_string
	call id_hlixiy_operand	;is a 16 bit add?
	jr c,add16
	ld a,$80			;"add a" opcode
	ld (opcode_stem),a
	jp standard_alu_instruction
	
add16	ld a,%00001001
	ld (opcode_stem),a
	jp standard_16bit_instruction
	
	
	
;=======================================================================================================

