;----------------------------------------------------------------------------------------------------------

d_code	ld a,(ix+1)		;is it an "DEC" instruction?
	cp "e"
	jp nz,not_dec
	ld a,(ix+2)
	cp "c"
	jp nz,not_dec
	ld a,(ix+3)
	or a
	jp nz,not_dec
	
	ld a,(opcode_arg2_string)
	or a
	jp nz,invalid_instruction
	
	ld ix,opcode_arg1_string
	ld a,(ix)
	cp "("
	jr z,dec8bit
	ld a,(ix+1)
	or a
	jr z,dec8bit
	
	ld a,%00001011		; 16 bit "dec" instruction stem
	ld (opcode_stem),a
	jp type_2_16bit_opcode
			
dec8bit	ld a,$05			; 8 bit "dec" instruction stem
	ld (opcode_stem),a
	jp shifted_r_alu_instruction

;------------------------------------------------------------------------------------------------------

not_dec	ld a,(ix+1)		; DAA?
	cp "a"
	jr nz,not_daa
	ld a,(ix+2)
	cp "a"
	jr nz,not_daa
	ld a,(ix+3)
	or a
	jr nz,not_daa
	
	ld a,$27
	call output_data_byte
	xor a
	ret

;------------------------------------------------------------------------------------------------------

not_daa	ld a,(ix+1)		;DI?
	cp "i"
	jr nz,not_di
	ld a,(ix+2)
	or a
	jr nz,not_di
	
	ld a,$f3
	call output_data_byte
	xor a
	ret

;------------------------------------------------------------------------------------------------------

not_di	ld a,(ix+1)		;DJNZ x?
	cp "j"
	jr nz,not_djnz
	ld a,(ix+2)
	cp "n"
	jr nz,not_djnz	
	ld a,(ix+3)
	cp "z"
	jr nz,not_djnz
	ld a,(ix+4)
	or a
	jr nz,not_djnz
	
	ld a,$10
	call output_data_byte
	ld a,(opcode_arg2_string)
	or a
	jp nz,invalid_instruction
	ld hl,opcode_arg1_string
	call get_8bit_relative_address
	ret nz
	ld a,e
	call output_data_byte
	xor a
	ret
	
;-------------------------------------------------------------------------------------------------------
; Non Z80 instructions "D" follow (Directives)
;-------------------------------------------------------------------------------------------------------

not_djnz

	ld a,(ix+1)			;ds directive?
	cp "s"
	jr nz,not_ds
	ld a,(ix+2)
	or a
	jp nz,not_ds
	
	ld hl,opcode_arg1_string
	call handle_numeric_expression	;DS can return error on first pass if label not found
	ret nz				;as position of following code depends on it
	inc de
	ld (fill_count),de
	ld hl,opcode_arg2_string
	call get_8bit_number
	ret nz
	ld a,e
	ld (fill_byte),a
		
ds_loop	ld bc,(fill_count)
	dec bc
	ld (fill_count),bc
	ld a,b
	or c
	ret z
	ld a,(fill_byte)
	call output_data_byte
	jr ds_loop

;-----------------------------------------------------------------------------------------------------

not_ds	ld a,(ix+1)			;db directive?
	cp "b"
	jp nz,not_db
	ld a,(ix+2)
	or a
	jp nz,not_db

	ld hl,opcode_arg1_string
	ld a,(hl)
	or a
	jp z,syntax_error			;args missing
	cp $22
	jr nz,db_not_quoted_string1		;is it db "... ?
	push hl
	pop ix
	ld a,(ix+2)
	cp $22
	jr z,db_not_quoted_string1		;is it a single quoted char, if so treat as numeric
dbasclp1	inc hl				;if multiple chars, just output the ASCII bytes
	ld a,(hl)				;until another quote is found
	or a
	jp z,syntax_error
	cp $22
	jr z,db_arg2
	call output_data_byte
	ret nz
	jr dbasclp1

db_not_quoted_string1
	
	call get_8bit_number
	ret nz
	ld a,e
	call output_data_byte		;first byte from arg1 
	ret nz
	
db_arg2	ld hl,opcode_arg2_string		;other bytes from arg2 (because of the comma seperator)
db_loop2	ld (data_element_src),hl
dbnxtdel	ld hl,(data_element_src)
	ld a,(hl)
	or a
	ret z
	cp $22				;does element start with a quote?
	jr nz,dbnquote2			
	push hl
	pop ix
	ld a,(ix+2)
	cp $22				;if single char in quotes, treat as numeric
	jr z,dbnquote2
dbasclp2	inc hl				;if multiple chars, just output the ASCII bytes
	ld a,(hl)				;until another quote is found
	or a
	jp z,syntax_error
	cp $22
	jr z,dbendq2
	call output_data_byte
	ret nz
	jr dbasclp2
dbendq2	inc hl				;go past 2nd quote, should be either a terminator or comma
	ld a,(hl)
	or a
	ret z
	cp ","
	jp nz,syntax_error
	inc hl
	jr db_loop2
	
dbnquote2	ld de,d_element_iso			;isolate each data element (IE: those separated by commas)
dbdecopy	ld a,(hl)
	ld (de),a
	or a
	jr z,dbdeokz
	cp ","
	jr z,dbdeokcom
	inc hl
	inc de
	jr dbdecopy
	
dbdeokcom	inc hl				;skip the comma
dbdeokz	ld (data_element_src),hl
	xor a
	ld (de),a				;null terminae the isolated expression
	
	ld hl,d_element_iso
	call get_8bit_number
	ret nz
	ld a,e
	call output_data_byte
	ret nz
	jr dbnxtdel


;-----------------------------------------------------------------------------------------------------

not_db	ld a,(ix+1)			;dw directive?
	cp "w"
	jr nz,not_dw
	ld a,(ix+2)
	or a
	jp nz,not_dw

	ld hl,opcode_arg1_string
	ld a,(hl)
	or a
	jp z,invalid_instruction		;args missing
	call get_16bit_number
	ret nz
	call output_data_word		;first word from arg1 
	
	ld hl,opcode_arg2_string		;other word from arg2 (because of the comma seperator)
	ld (data_element_src),hl
dwnxtdel	ld hl,(data_element_src)
	ld a,(hl)
	or a
	ret z
	ld de,d_element_iso
dwdecopy	ld a,(hl)
	ld (de),a
	or a
	jr z,dwdeokz
	cp ","
	jr z,dwdeokcom
	inc hl
	inc de
	jr dwdecopy
dwdeokcom	inc hl				;skip the comma
dwdeokz	ld (data_element_src),hl
	xor a
	ld (de),a
	
	ld hl,d_element_iso
	call get_16bit_number
	ret nz
	call output_data_word
	jr dwnxtdel

;-----------------------------------------------------------------------------------------------------

not_dw
	
	jp invalid_instruction


;=======================================================================================================

fill_count	dw 0
fill_byte		db 0

data_element_src	dw 0

d_element_iso	ds 256,0

;=======================================================================================================
