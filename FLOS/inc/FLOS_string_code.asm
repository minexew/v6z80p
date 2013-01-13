;----------------------------------------------------------------------------------
; FLOS String handling routines
;----------------------------------------------------------------------------------


os_move_to_next_arg

		ld hl,(os_args_start_lo)
	
os_next_arg

		call os_scan_for_space
		or a
		ret z
		call os_scan_for_non_space
		or a
		ret


;------------------------------------------------------------------------------------------
	

os_scan_for_space

os_sfspl 	ld a,(hl)				;hl = source text, hl = space char on exit	
		or a					;or location of zero if encountered first
		ret z
		cp " "
		ret z
		inc hl
		jr os_sfspl
		

;-----------------------------------------------------------------------------------------
	

os_scan_for_non_space

		dec hl					;hl = source text, hl = 1st non-space char on exit			
os_nsplp	inc hl			
		ld a,(hl)			
		or a			
		ret z					;if zero flag set on return end of line was encountered
		cp " "
		jr z,os_nsplp
		ret
	
	

;--------- Number <-> String functions -----------------------------------------------------


	
os_skip_leading_ascii_zeros

slazlp		ld a,(hl)				;advances HL past leading zeros in ascii string
		cp "0"					;set b to max numner of chars to skip
		ret nz
		inc hl
		djnz slazlp
		ret
	



os_leading_ascii_zeros_to_spaces

		push hl
clazlp		ld a,(hl)				;leading zeros in ascii string (HL) are replaced by spaces
		cp "0"					;set b to max numbner of chars
		jr nz,claze
		ld (hl)," "
		inc hl
		djnz clazlp
claze		pop hl
		ret
	



		
n_hexbytes_to_ascii

; set b to number of digits.
; set de to most significant byte address

		ld a,(de)			
		call hexbyte_to_ascii	
		dec de
		djnz n_hexbytes_to_ascii
		ret

	
hexword_to_ascii	

;ASCII version of DE is stored at hl to hl+3

		ld a,d			
		call hexbyte_to_ascii
		ld a,e

				
hexbyte_to_ascii

;puts ASCII version of hex byte value in A at HL (two chars)

		push af			
		call hexdig1
		pop af
		jr hexdig2
hexdig1		rra
		rra
		rra
		rra
hexdig2		or $f0
		daa 
		add a,$a0
		adc a,$40
		ld (hl),a
		inc hl
		ret



	


ascii_to_hexword
	
		call os_scan_for_non_space		; set text address in hl, de = hex word on return
		jr z,no_hex

ascii_to_hexw_no_scan
	
		push bc
		call ascii_to_hex32
		jr nz,hex16ret				; abort now if error in conversion
		
		ld a,b
		or c
		jr z,hex16ret
		ld a,$1a				; error $1a (Value Out Of Range) if > 65535
		or a		

hex16ret	pop bc
		ret
		
		




ascii_to_hex32_scan

		call os_scan_for_non_space		; set text address in hl
		jr nz,ascii_to_hex32
no_hex		ld a,$1f				; if a=0, set "no hex" return code $1f
		or a
		ret	


ascii_to_hex32

		xor a					;source: HL, dest: BC:DE   (HL location = space at end of string on exit)
		ld d,a
		ld e,a
		ld b,a
		ld c,a

hex32clp	ld a,(hl)
		or a
		ret z
		cp " "
		jr nz,hexnspc
		xor a
		ret
			
hexnspc		ex de,hl
		ld a,4
hexclp		add hl,hl
		rl c
		rl b
		jr nc,val32_ir		
		ld a,$1a				;value out of range error if > 2^32
		or a
		ret
val32_ir	dec a
		jr nz,hexclp
		ex de,hl
		
		ld a,(hl)				;ascii to hex char 
		call os_uppercasify
		sub $3a			
		jr c,zeronine
		add a,$f9
zeronine	add a,$a
		cp 16
		jr nc,badhx2

		or e
		ld e,a
		inc hl
		jr hex32clp

badhx2		ld a,$0c
		or a
		ret
	
	
;--------- Text Input / Non-numeric string functions ------------------------------------


os_user_input

; Waits for user to enter a string of characters followed by Enter
; Set A to max chars allowed

; Returns HL = string location (zero termimated)
;         A  = number of characters in entered string (zero if aborted by ESC)

		ld (ui_max_chars),a
		ld hl,output_line			;clear old string 
		ld c,OS_window_cols
		call os_chl_memclear_short
		xor a
		ld (ui_index),a				;clear index
		
ui_loop		ld de,$85f				;force underscore cursor
		call cursor_keywait

		ld ix,ui_index

		ld a,(current_scancode)
		cp $66					;pressed backspace?
		jr nz,os_nuibs
		
		ld a,(ix)				;get input char index
		or a
		jr z,ui_loop				;cant delete if at start
		ld hl,cursor_x				;shift cursor left and put a space at new position
		dec (hl)			
os_uixok	ld b,(hl)		
		ld a,(cursor_y)
		ld c,a
		ld a,32
		call os_plotchar
		dec (ix)				;dec char count
		xor a 		
		call ui_put_char
		jr ui_loop

os_nuibs	cp $76
		jr z,ui_aborted				; pressed esc?
	
		cp $5a					; pressed enter?
		jr z,ui_enter_pressed
		
		ld a,(cursor_x)				; do nothing if cursor is at right of screen
		cp OS_window_cols-1
		jr z,ui_loop	
		ld a,(ui_max_chars)			; or index at max char count
		cp (ix)
		jr z,ui_loop
		
		ld a,(current_asciicode)		; not a bkspace, esc or enter... 
		or a					; if scancode is not an ascii skip char.
		jr z,ui_loop		

		call flip_char_case

		call ui_put_char			; enter char in allocated input string space
		inc (ix)				; next string position
					
		ld bc,(cursor_y)			; and print character on screen...
		call os_plotchar		
		ld hl,cursor_x				; ..and move cursor right
		inc (hl)
		jp ui_loop


ui_enter_pressed

		ld hl,output_line
		ld a,(ix)
		ret


ui_aborted	xor a					; on exit a = 0 if escape pressed / aborted
		ret
		
		
ui_put_char	ld hl,output_line
		ld e,(ix)
		ld d,0
		add hl,de
		ld (hl),a	
		ret
				
;--------------------------------------------------------------------------------
	
os_count_lines

		push hl				;counts output lines and says "More?"
		ld b,"y"				;default "no wait" key return
		ld hl,os_linecount			;every 20, waiting for a keypress to continue
		inc (hl)				;b (ascii code) = "y" by default
		ld a,(hl)
		cp 20
		jr nz,os_nntpo
		ld (hl),0
		ld hl,os_more_txt
		call os_print_string
		call os_wait_key_press	
os_nntpo	pop hl
		ret

	
;---------------------------------------------------------------------------------

os_compare_strings

; both strings should be zero terminated.
; compare will fail if string lengths are different
; unless count (b) is reached
; carry flag set on return if same
; not case sensitive (FLOS v594+)

		push hl				;set de = source string
		push de				;set hl = compare string
ocslp		ld a,(de)				;b = max chars to compare
		or a
		jr z,ocsbt
		call os_uppercasify
		ld c,a
		ld a,(hl)
		call os_uppercasify
		cp c
		jr nz,ocs_diff
		inc de
		inc hl
		djnz ocslp
		jr ocs_same
ocsbt		ld a,(de)				;check both strings at termination point
		or (hl)
		jr nz,ocs_diff
ocs_same	pop de
		pop hl
		scf					; carry flag set if same		
		ret
ocs_diff	pop de
		pop hl
		xor a					; carry flag zero if different	
		ret


;-----------------------------------------------------------------------------------

os_copy_ascii_run

;INPUT HL = source ($00 or $20 terminates)
;      DE = dest
;       b = max chars

;OUTPUT HL/DE = end of runs
;           c = char count
	
		ld c,0
cpyar_lp	ld a,(hl)
		or a
		ret z
		cp 32
		ret z
		ld (de),a
		inc hl
		inc de
		inc c
		djnz cpyar_lp
		ret

;-----------------------------------------------------------------------------------

uppercasify_string

; Set HL to string location ($00 quits)
; Set B to max number of chars

		ld a,(hl)
		or a
		ret z
		call os_uppercasify
		ld (hl),a
		inc hl
		djnz uppercasify_string
		ret
		

os_uppercasify

; INPUT/OUTPUT A = ascii char to make uppercase

		cp $61			
		ret c
		cp $7b
		ret nc
		sub $20				
		ret
				
;----------------------------------------------------------------------------------

os_print_decimal
	
;Number in hl to decimal ASCII (thanks to z80 Bits)
;Modified to skip leading zeroes by Phil Ruston
;inputs:	hl = number to ASCII
;example: hl=300 outputs '300'
;destroys: af, bc, hl, de used

DispHL		ld d,5
		ld e,0
		ld bc,-10000
		call Num1
		ld bc,-1000
		call Num1
		ld bc,-100
		call Num1
		ld c,-10
		call Num1
		ld c,-1
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
notzero		call os_print_char
		ld e,1
		ret 

			
;-----------------------------------------------------------------------------------

		
os_copy_to_output_line
	
		push de
		push bc
		ld de,output_line				;hl = zero terminated string
		ld bc,OS_window_cols+1				;note copies terminating zero
os_cloll	ldi					
		ld a,(hl)
		or a
		jr z,os_clold
		ld a,b
		or c
		jr nz,os_cloll
os_clold	ld (de),a
		pop bc
		pop de
		ret


;----------------------------------------------------------------------------------


os_show_hex_byte

		push hl					; put byte to display in A
		ld hl,output_line
		call hexbyte_to_ascii
		jr shb_nt

os_show_hex_word

		push hl					; put word to display in DE
		ld hl,output_line
		call hexword_to_ascii
shb_nt		ld (hl),0
		pop hl
		
os_print_output_line

		push hl
		ld hl,output_line
cproline	call os_print_string
		pop hl
		ret



os_print_output_line_skip_zeroes

		push hl
		ld hl,output_line
		call os_skip_leading_ascii_zeros
		jr cproline

;----------------------------------------------------------------------------------

flip_char_case
		cp $7b					; upper <-> lower case are flipped in OS 
		ret nc					; to make unshifted = upper case
		cp $61
		jr c,ui_ntupc
		sub $20
		ret
ui_ntupc	cp $5b
		ret nc
		cp $41
		ret c
		add a,$20
ui_gtcha	ret

;----------------------------------------------------------------------------------
