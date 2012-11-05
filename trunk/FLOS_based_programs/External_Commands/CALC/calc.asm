; CALC.EXE V1.00
;
; Simple 16 bit calculator
;
;
;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $f000
my_bank		equ $0e
include 	"flos_based_programs\code_library\program_header\inc\force_load_location.asm"

required_flos	equ $594
include 	"flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------
	

		ld a,(hl)
		or a
		jr nz,got_args
		
		ld hl,show_use_txt
		call kjt_print_string
		xor a
		ret

got_args	call deflate_string			;remove spaces from arg string
		ld hl,deflated_string_txt
		
		call handle_numeric_expression
		jr nz,math_error
		ld (result),de
		
		ld hl,(result)
		call print_hexword_hex
		
		ld a," "
		call putchar
		
		ld hl,(result)
		call print_hexword_dec
		
		ld a," "
		call putchar
		
		ld hl,(result)
		call print_hexword_bin
		
		ld a,11
		call putchar
		
		xor a
		ret

math_error	ld hl,unknown_error_txt
		cp $21
		call z,err21
		cp $22
		call z,err22
		cp $23
		call z,err23
		cp $24
		call z,err24
		
		call kjt_print_string
		ld a,$80
		or a
		ret

err21		ld hl,garbage_txt
		ret

err22		ld hl,range_txt
		ret

err23		ld hl,malformed_txt
		ret		

err24		ld hl,too_long_txt
		ret

		
unknown_error_txt

		db "Unknown error",11,0
	
garbage_txt	db "ERROR: Unexpected character in number",11,0

range_txt	db "ERROR: Over/underflow",11,0

malformed_txt	db "ERROR: Malformed expression",11,0

too_long_txt	db "ERROR: Expression too long",11,0
		
show_use_txt	db 11,"CALC.EXE v1.00 - 16bit calculator",11
		db 11,"USAGE: CALC expression",11,11
		db "Prefixes: # = Dec, $ = Hex, % = bin",11
		db "(None: number interpreted as hex)",11,0


;-----------------------------------------------------------------------------------------------------------------

deflate_string
		
		ld de,deflated_string_txt
defloop		ld a,(hl)				;remove spaces from string
		inc hl
		cp " "
		jr z,defloop
ds_notsp	ld (de),a
		inc de
		or a
		jr nz,defloop
		ret
	
;-----------------------------------------------------------------------------------------------------------------
; Maths routines..
;-----------------------------------------------------------------------------------------------------------------

handle_numeric_expression

; set HL to start of zero-terminated string
; If ZF is set, return value in DE (else maths error code in A)

		ld (expression_start_loc),hl

find_brackets	ld b,0				; b = open bracket located status
expr_loop	ld a,(hl)
		or a
		jr nz,noteoexpr
		xor a
		or b
		jr nz,bracket_error		; error - End of expression whilst brackets still open
		ld hl,(expression_start_loc)
		call do_calculation		; can now run the calc in a simple left to right manner
		ret
		
noteoexpr	cp "("
		jr nz,notopbr
		ld (last_open_bracket_loc),hl
		ld b,1				; reset bracket marker
		ld c,0				; count chars before close bracket
		jr notbrchars
		
notopbr		cp ")"
		jr nz,notclbr
		xor a
		or b
		jr z,bracket_error		; error - found closed bracket without brackets being open
		jr got_close_br
		
notclbr		xor a
		or b
		jr z,notbrchars
		inc c				; inc count of chars between brackets
		jp z,exp_too_long	

notbrchars	inc hl
		jr expr_loop	
		
		
	
got_close_br	ld (close_bracket_loc),hl	;store location of close bracket
		xor a
		or c
		jr z,bracket_error		;- Error: "()" encountered
		ld hl,(last_open_bracket_loc)
		inc hl
		ld de,unbracketed_expression	;isolate contents of brackets in new string
		ld b,0
		ldir			
		xor a
		ld (de),a			;zero terminate the isolated string

		ld hl,unbracketed_expression	;do the maths on the unbracketed string..
		call do_calculation
		ret nz
		ld de,(calculation_result)
		ld hl,ascii_hexword+1
		call hexword_to_ascii_string	;convert the result to ascii 
		
		ld de,(close_bracket_loc)	;copy the string after the closed bracket after the hex word ascii
		inc de
		ld b,251
copypbs		ld a,(de)
		ld (hl),a
		or a
		jr z,pbsc_done
		inc hl
		inc de
		djnz copypbs
		jr exp_too_long
		
pbsc_done	ld hl,ascii_hexword		;paste the computed word and rest of ascii back to the original expression
		ld de,(last_open_bracket_loc)
br_fixlp	ld a,(hl)
		ld (de),a
		inc hl
		inc de
		or a
		jr nz,br_fixlp
			
		ld hl,(expression_start_loc)
		jr find_brackets		;re-run routine until all bracketed sections are substituted



bracket_error	ld a,$23
		or a
		ret
		
exp_too_long	ld a,$24
		or a
		ret
		
;----------------------------------------------------------------------------------------------------------------	

do_calculation

; set HL to source string. if ZF set, result is in DE (and "calculation_result") else maths error code in A

		call evaluate_numeric_word
		ret nz
calc_nxt	ld (calculation_result),de

		ld a,(hl)
		or a
		ret z					;end of string found, calculation complete

		cp "&"
		jr z,logical_and
		cp "|"
		jr z,logical_or
		cp "+"
		jr z,addition
		cp "-"
		jr z,subtraction
		cp "/"
		jp z,division
		cp "*"
		jp z,multiplication
		cp "<"
		jp z,shiftleft
		cp ">"
		jp z,shiftright
		ld a,$26				;ERROR $26 - maths op other than + - / * < > found
		or a
		ret
		

logical_and	inc hl
		ld a,(hl)
		or a
		jp z,calc_string_bad
		call evaluate_numeric_word
		ret nz
		push hl
		ld hl,(calculation_result)
		ld a,h
		and d
		ld h,a
		ld a,l
		and e
		ld l,a
		ex de,hl
		pop hl
		xor a
		jr calc_nxt


logical_or	inc hl
		ld a,(hl)
		or a
		jp z,calc_string_bad
		call evaluate_numeric_word
		ret nz
		push hl
		ld hl,(calculation_result)
		ld a,h
		or d
		ld h,a
		ld a,l
		or e
		ld l,a
		ex de,hl
		pop hl
		xor a
		jr calc_nxt

	
addition	inc hl				;skip the +
		ld a,(hl)		
		or a
		jp z,calc_string_bad
		call evaluate_numeric_word
		ret nz
		push hl
		ld hl,(calculation_result)
		add hl,de
		ex de,hl
		pop hl
		jp c,calc_overflow
		jr calc_nxt



subtraction	inc hl				;skip the -
		ld a,(hl)
		or a
		jp z,calc_string_bad
		call evaluate_numeric_word
		ret nz
		push hl
		ld hl,(calculation_result)
		xor a
		sbc hl,de
		ex de,hl
		pop hl
		jp nc,calc_nxt			;if there was no underflow (borrow) all ok
		jp p,calc_overflow		;if there was a borrow and underflow is > 32768, return error 			
		jp calc_nxt



division

		inc hl
		ld a,(hl)
		or a
		jp z,calc_string_bad
		call evaluate_numeric_word
		ret nz
		push hl
		
		ld hl,(calculation_result)
		ld a,h
		ld c,l

		ld hl,0				;ac = ac/de (remainder in hl)
		ld b, 16
divloop		sll c
		rla 
		adc hl,hl
		sbc hl,de
		jr nc,$+4
		add hl,de
		dec c
		djnz divloop
		
		ld d,a
		ld e,c
		pop hl
		jp calc_nxt
   
 

multiplication	inc hl
		ld a,(hl)
		or a
		jp z,calc_string_bad
		call evaluate_numeric_word
		ret nz
		
		push hl
		ld bc,(calculation_result)
		
		ld hl,0				; de:hl = bc*de
		sla e		
		rl d
		jr nc,$+4
		ld h,b
		ld l,c
		ld a,15
multloop 	add hl,hl
		rl e
		rl d
		jr nc,$+6
		add hl,bc
		jr nc,$+3
		inc de
		dec a
		jr nz,multloop
		ld a,d
		or e
		jr z,mrange_ok
		pop hl
		jr calc_overflow
   	
mrange_ok 	ex de,hl
		pop hl
		jp calc_nxt



shiftleft	

		inc hl
		ld a,(hl)
		cp "<"
		jp nz,calc_string_bad
		inc hl
		ld a,(hl)
		or a
		jp z,calc_string_bad
		
		call evaluate_numeric_word
		ret nz
		ld b,e
		xor a
		or b
		jr nz,lshtodo
		ld de,(calculation_result)
		jp calc_nxt
lshtodo		push hl
		ld hl,(calculation_result)
shl_loop	add hl,hl
		djnz shl_loop
		ex de,hl
		pop hl
		jp calc_nxt
		



shiftright

		inc hl
		ld a,(hl)
		cp ">"
		jp nz,calc_string_bad
		inc hl
		ld a,(hl)
		or a
		jp z,calc_string_bad
		call evaluate_numeric_word
		ret nz
		ld b,e
		xor a
		or b
		jr nz,rshtodo
		ld de,(calculation_result)
		jp calc_nxt
rshtodo		push hl
		ld hl,(calculation_result)
shr_loop	srl h
		rr l
		djnz shr_loop
		ex de,hl
		pop hl
		jp calc_nxt


calc_overflow

		ld a,$22
		or a
		ret	
		
calc_string_bad

		ld a,$23
		or a
		ret

;-----------------------------------------------------------------------------------------------------------------
	
	
evaluate_numeric_word

; set HL to numeric expression, returns value in DE, 
; ZF set if all OK. Else A = error 

		ld de,0
		ld a,(hl)			;if a sign prefix is specified, return de=0
		cp "+"
		ret z
		cp "-"
		ret z	

nosignpre	cp "$"				;hex value?
		jr nz,not_hex
		inc hl
		call decode_hex
		jr got_value
		
not_hex		cp "%"				;bin value?
		jr nz,not_bin
		inc hl
		call decode_bin
		jr got_value
		
not_bin		cp "#"
		jr nz,not_deci
		inc hl
		call decode_dec			;no prefix for dec
		jr got_value

not_deci	cp $22
		jr nz,not_quote			;ascii value(s)?
valascii	inc hl				;skip quote prefix
		call decode_ascii
		jr got_value
not_quote	cp $27
		jr z,valascii

		call decode_hex			;no prefix, try interpreting as hex
				
got_value	jr c,range_err		
		jr nz,bad_char
		ld a,(hl)			;if the number string ended in any of +-*/<>&| or <null> then it
		push hl			;is accepted as valid
		push bc
		ld hl,ok_term_list
		ld bc,10
		cpir
		pop bc
		pop hl
		ret z
			
bad_char	ld a,$21			;garbage chars in string
		or a
		ret
		
range_err	ld a,$22			;number > 65536
		or a
		ret


ok_term_list	db ")+-*",$2f,"<>&|",0

		
		
;-----------------------------------------------------------------------------------------------------------------
; Ascii string to hex word converters
;-----------------------------------------------------------------------------------------------------------------

decode_bin

; src number string in HL, output in DE (HL = first char not part of the number)
; CF set if > 65535. 

	
		ex de,hl
		call binmain
		ex de,hl
		ret
		
binmain		ld hl,0
binloop		ld a,(de)
		cp "1"
		jr z,binbit1
		cp "0"
		jr z,binbit0
		xor a
		ret
binbit0		add hl,hl
		ret c
		jr bin_ok
binbit1		add hl,hl
		ret c
		set 0,l
bin_ok		inc de
		jr binloop
		




	
decode_hex

; src number string in HL, output in DE (on return HL = first char not part of the number)
; CF set if > 65535.

	
notopcr		ex de,hl
		call hexmain
		ex de,hl
		ret

hexmain		ld hl,0
hexloop		ld a,(de)
		cp $61
		jr c,notlowcase
		cp $67
		jr nc,hex_done
		sub $20
		
notlowcase	cp $30
		jr c,hex_done
		cp $3a
		jr c,hexd09
		cp $41
		jr c,hex_done
		cp $47
		jr nc,hex_done
hexdaf		sub $07
hexd09		sub $30

got_hexd	add hl,hl
		ret c
		add hl,hl
		ret c
		add hl,hl
		ret c
		add hl,hl
		ret c
		or l
		ld l,a
		inc de
		jr hexloop
	
hex_done	xor a
		ret
		
	
	
	
decode_dec

; src number string in HL, output in DE (on return HL = first char not part of the number)
; CF set if > 65535. 

		ex de,hl
		call decimain
		ex de,hl
		ret

decimain	ld hl,0
deciloop	ld a,(de)
		sub $30			
		jr c,deci_done
		cp $0a
		jr nc,deci_done
		add hl,hl
		ret c
		push hl
		pop bc
		add hl,hl
		ret c
		add hl,hl
		ret c
		add hl,bc
		ret c
		ld b,0	
		ld c,a
		add hl,bc
		ret c
		inc de
		jr deciloop
	
deci_done	xor a
		ret
	
	
	
	
	
decode_ascii

; ascii char @ HL, output in DE (on return HL = first char after closing quote)
; ZF not set if garbage encountered 

		ex de,hl
		call asciimain
		ex de,hl
		ret

asciimain	ld hl,0
		ld a,(de)
		cp $22
		jr z,bad_ascii
		cp "'"
		jr z,bad_ascii
		ld l,a
		inc de
		ld a,(de)
		cp $22
		jr z,ascii_ok
		cp $27
		jr z,ascii_ok
		ld b,l
		ld l,a
		ld h,b
		inc de
		ld a,(de)
		or a
		jr z,ascii_ok
		cp $22
		jr z,ascii_ok
		cp $27
		jr nz,bad_ascii
		
ascii_ok	inc de			; dont return on a quote
		xor a
		ret
	
bad_ascii	ld a,$21
		or a
		ret
	
;----------------------------------------------------------------------------------------------------------------

hexword_to_ascii_string

; DE = source word
; HL = dest string

		ld a,d
		rrca
		rrca
		rrca
		rrca
		and $f
		call hex_digit
		ld a,d
		and $f
		call hex_digit
		ld a,e
		rrca
		rrca
		rrca
		rrca
		and $f
		call hex_digit
		ld a,e
		and $f
		call hex_digit
		ret

hex_digit	cp $a
		jr c,hex09a
		add a,$27
hex09a		add a,$30
		ld (hl),a
		inc hl
		ret
		
;----------------------------------------------------------------------------------------------------------------

print_hexword_hex

; DE = source word
; HL = dest string
		
		ld a,"$"
		call putchar
		
		ld b,0				;zero plot decision
		
		ld a,h
		rrca
		rrca
		rrca
		rrca
		call hex_char
		ld a,h
		call hex_char
		ld a,l
		rrca
		rrca
		rrca
		rrca
		call hex_char
		ld a,l
		and $f
		call hexdnz			;last char always plotted
		ret

hex_char	and $f
		jr nz,hexdnz
		bit 0,b
		ret z
hexdnz		call do_hex_digit
		call putchar
		ld b,1
		ret

do_hex_digit	cp $a
		jr c,hex09
		add a,$07
hex09		add a,$30
		ret
	
;----------------------------------------------------------------------------------

; Prints a hexword as decimal - excludes leading zeroes

; Input: HL = number to display

print_hexword_dec

		ld a,"#"
		call putchar

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
Num1		ld a,'0'-1
Num2		inc a
		add hl,bc
		jr c,Num2
		sbc hl,bc
		dec d
		jr z,notzero
		cp "0"
		jr nz,notzero
		bit 0,e
		ret z
notzero		call putchar
		ld e,1
		ret 
		
putchar		push hl			;FLOS print char routine
		ld hl,my_char
		ld (hl),a
		call kjt_print_string
		pop hl
		ret
		
my_char		db 0,0				;note zero string terminator

;-----------------------------------------------------------------------------------

print_hexword_bin

; Prints a hexword as binary 
; Input: HL = number to display

		ld a,"%"
		call putchar
		
		ld e,0				;e = leading zero decision
		ld b,15	
		
pb_loop		ld a,"1"
		add hl,hl
		jr c,pb_bit1
		dec a
		bit 0,e
		jr z,nobinz
pb_bit1		call putchar
		ld e,1
nobinz		djnz pb_loop
		
		ld a,"1"			;last digit always displayed
		add hl,hl
		jr c,pb_bit1b
		dec a
pb_bit1b	call putchar
		ret

;-----------------------------------------------------------------------------------
	

calculation_result	dw 0

expression_start_loc	dw 0

last_open_bracket_loc	dw 0

close_bracket_loc	dw 0

unbracketed_expression	ds 256,0

ascii_hexword		db "$xxxx"
			ds 251,0

deflated_string_txt	ds 41,0

result			dw 0

;----------------------------------------------------------------------------------------------------------------	
