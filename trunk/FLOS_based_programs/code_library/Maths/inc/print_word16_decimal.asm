;----------------------------------------------------------------------------------

; Prints a hexword as decimal - excludes leading zeroes

; Input: HL = number to display

print_word16_decimal

	ld d,5
	ld e,0
	ld bc,-10000
	call Num1
	ld bc,-1000
	call Num1
	ld bc,-100
	call Num1
	ld bc,-10
	call Num1
	ld bc,-1
Num1	ld a,'0'-1
Num2	inc a
	add hl,bc
	jr c,Num2
	sbc hl,bc
	dec d
	jr z,notzero
	cp "0"
	jr nz,notzero
	bit 0,e
	ret z
notzero	call putchar
	ld e,1
	ret 
	


putchar	push hl			;FLOS print char routine
	ld hl,my_char
	ld (hl),a
	call kjt_print_string
	pop hl
	ret
	
my_char	db 0,0				;note zero string terminator

;-----------------------------------------------------------------------------------
	