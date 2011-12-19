;----------------------------------------------------------------------------------------------------------

i_code	ld a,(ix+1)		;is it an "INC" instruction?
	cp "n"
	jp nz,not_incx
	ld a,(ix+2)
	cp "c"
	jp nz,not_incx
	ld a,(ix+3)
	or a
	jp nz,not_inc
	
	ld a,(opcode_arg2_string)
	or a
	jp nz,invalid_instruction
	ld ix,opcode_arg1_string
	ld a,(ix)
	cp "("
	jr z,inc8bit
	ld a,(ix+1)
	or a
	jr z,inc8bit
	
	ld a,%00000011		; 16 bit "inc" instruction stem
	ld (opcode_stem),a
	jp type_2_16bit_opcode
	
inc8bit	ld a,$04			; 8 bit "inc" instruction stem
	ld (opcode_stem),a
	jp shifted_r_alu_instruction


;-------------------------------------------------------------------------------------------------------
; NON-Z80 OPCODE: INCLUDE directive
;--------------------------------------------------------------------------------------------------------

not_inc	ld a,(ix+3)			; is this an include instruction?
	cp "l"
	jr nz,not_include
	ld a,(ix+4)
	cp "u"
	jr nz,not_include		
	ld a,(ix+5)
	cp "d"
	jr nz,not_include
	ld a,(ix+6)
	cp "e"
	jr nz,not_include
	ld a,(ix+7)
	or a
	jr nz,not_include

	call push_working_file_info		; stash the current file
	ret nz
	ld de,working_src_filename		; copy the new filename from arg1
	call copy_filename_no_quotes
	ld hl,1				; reset working line count for new file
	ld (working_src_line_count),hl
	ld hl,0
	ld (working_src_file_pointer),hl
	ld (working_src_file_pointer+2),hl	; reset file pointer for new file
	
	call fill_source_buffer
	ret z
	cp 5				; if "file not found", pop previous details so error message is correct
	ret nz			
	call pop_working_file_info	
	ld a,5
	or a
	ret
	
	
		
not_include
	
	ld a,(ix+3)			; is this an incbin instruction?
	cp "b"
	jr nz,not_include
	ld a,(ix+4)
	cp "i"
	jr nz,not_include		
	ld a,(ix+5)
	cp "n"
	jr nz,not_include
	ld a,(ix+6)
	or a
	jr nz,not_incbin
	ld de,incbin_filename		; copy the incbin filename from arg1
	call copy_filename_no_quotes
	call handle_incbin
	ret

not_incbin

;-------------------------------------------------------------------------------------------------------

not_incx	ld a,(ix+1)			;is it an "IM" instruction?
	cp "m"
	jr nz,not_im
	ld a,(ix+2)
	or a
	jr nz,not_im
	
	ld a,(opcode_arg2_string)
	or a
	jp nz,invalid_instruction
	
	ld a,$ed
	call output_data_byte
		
	ld hl,opcode_arg1_string
	call get_8bit_number
	ret nz
	ld a,e
	cp 3
	jp nc,invalid_instruction
	ld e,$46
	or a
	jr z,got_im
	ld e,$56
	cp 1
	jr z,got_im
	ld e,$5e
got_im	ld a,e
	call output_data_byte
	xor a
	ret

;-------------------------------------------------------------------------------------------------------

not_im	ld a,(ix+1)			;is it an "IN r,(C)" instruction?
	cp "n"
	jp nz,not_in
	ld a,(ix+2)
	or a
	jp nz,not_in_a_n
	
	ld ix,opcode_arg2_string
	ld a,(ix)
	cp "("
	jr nz,not_in_r_c
	ld a,(ix+1)
	cp "c"
	jr nz,not_in_r_c
	ld a,(ix+2)
	cp ")"
	jr nz,not_in_r_c
	ld a,(ix+3)
	or a
	jr nz,not_in_r_c
	
	ld ix,opcode_arg1_string
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
	or $40
	call output_data_byte
	xor a
	ret
	
	
not_in_r_c


	ld ix,opcode_arg1_string		;is it an "IN A,n" instruction?
	ld a,(ix)
	cp "a"
	jr nz,not_in_a_n
	ld a,(ix+1)
	or a
	jr nz,not_in_a_n	
	ld a,$db
	call output_data_byte
	ld hl,opcode_arg2_string
	call get_8bit_number
	ret nz
	ld a,e
	call output_data_byte
	xor a
	ret

;------------------------------------------------------------------------------------------------------
	
not_in_a_n	

	ld a,$a2		
	ld (opcode_stem),a
	ld ix,opcode_stem_string+2
	jp block_op_handler			; for INIR, INDI, INIR, IND instructions
	
	
;------------------------------------------------------------------------------------------------------
	
not_in	jp invalid_instruction


;=======================================================================================================

copy_filename_no_quotes

; set DE to dest filename string

	ld hl,opcode_arg1_string
	ld b,12
cinclfn	ld a,(hl)
	inc hl
	cp $22				; skip any quotes
	jr z,cinclfn
	ld (de),a
	inc de
	or a
	ret z
	djnz cinclfn
	ret

;======================================================================================================
