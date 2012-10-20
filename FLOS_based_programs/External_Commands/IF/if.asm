;----------------------------------------------------------------------------------------------
; App: "IF.EXE" for script control based on environment variables - v1.00 By Phil @ retroleum
;       (Sets the GOTO envar based on the condition / args supplied)
;
; Usage: IF xxxx cond yyyy GOTO zzzz
;
; Where xxxx = An Envar
;       cond = "=" for maths or strings or  "<" ">" or "<>" for maths only. 
;       yyyy = an immediate value, the value of another ENVAR in brackets (ENVAR) or a 4-char string in quotes "yyyy"
;       zzzz = a 4 char label
;--------------------------------------------------------------------------------------------


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
include 	"flos_based_programs\code_library\program_header\force_load_location.asm"

required_flos	equ $594
include 	"flos_based_programs\code_library\program_header\test_flos_version.asm"

;--------------------------------------------------------------------------------------
	
		push hl			; always delete the GOTO envar at start
		ld hl,goto_txt
		call kjt_delete_envar
		pop hl
		
		ld (args_pointer),hl
		
		ld a,(hl)			; If no arguments supplied, show usage.
		or a
		jp z,show_usage

		push hl			; "source" envar name is copied to var_name
		ld de,var_name
		ld b,4
evnclp		ld a,(hl)
		cp " "
		jr z,evncdone
		ld (de),a
		inc hl
		inc de
		djnz evnclp
evncdone	pop hl
		
		call next_arg		;move to condition
		jp z,bad_args
		
		ld b,0
		ld a,(hl)
		cp "="
		jr z,operator_set		; = [0]
		inc b
		cp ">"
		jr z,operator_set		; > [1]
		inc b
		cp "<"
		jp nz,bad_operator		; < [2]
		inc hl
		ld a,(hl)
		dec hl
		cp ">"			; <> [3]
		jr nz,operator_set
		inc b
		
operator_set

		ld a,b
		ld (operator),a
		
		call next_arg		;move to comparison string
		jp z,bad_args
		
		ld a,(hl)			;is it in quotes?
		cp $22
		jp z,string_compare
		
		cp "("			;is it in brackets?
		jp z,envar_val_compare
		

;--------------------------------------------------------------------------------------


absolute_compare

		call ascii_to_long_word	;puts result at var_data
		
val_comp	ld hl,var_name
		call kjt_get_envar		;get value of source envar loc at HL
		ret nz
		ld e,(hl)
		inc hl
		ld d,(hl)
		inc hl
		ld c,(hl)
		inc hl
		ld b,(hl)			;BC:DE = value
		push bc
		pop ix
		ex de,hl			;IX:HL = source value
		ld de,(var_data)
		ld bc,(var_data+2)		;BC:DE = comparison value
		xor a
		sbc hl,de
		ex de,hl
		push ix
		pop hl
		sbc hl,bc
		jp c,source_smaller		
		ld a,h
		or l
		or d
		or e
		jp z,source_same
		
source_larger

		ld a,(operator)		;source is larger, does condition require that?
		cp 1
		jp z,cond_true
		cp 3
		jp z,cond_true
		jp cond_false

source_smaller

		ld a,(operator)		;source is smaller, does condition require that?
		cp 2
		jp z,cond_true
		cp 3
		jp z,cond_true
		jp cond_false
		
source_same
		ld a,(operator)		;source is same, does condition require that?
		cp 3
		jp z,cond_false
		or a
		jp z,cond_true
		jp cond_false
		
		
;---------------------------------------------------------------------------------------
		
			
string_compare

		inc hl			; skip opening quote
		ld de,var_data		; put compare string at var_data
		ld b,4
strclp		ld a,(hl)
		cp $22
		jr z,got_str		; end at closing quote
		ld (de),a
		inc hl
		inc de
		djnz strclp
		
got_str		ld hl,var_name
		call kjt_get_envar		; set "value" of source envar loc at HL
		ret nz
		
		ld de,var_data		; compare with given string
		ld b,4
		call kjt_compare_strings
		jp nc,str_diff	
		ld a,(operator)		; string is same, does condition require that?
		or a
		jp z,cond_true
		jp cond_false
		
str_diff	ld a,(operator)		; string is different, does condition require that?
		cp 3
		jp z,cond_true
		jp cond_false
		
		
;----------------------------------------------------------------------------------------


envar_val_compare
		
		inc hl			; skip opening bracket
		ld de,var_name2		; put envar name at var_name2
		ld b,4
strclp2		ld a,(hl)
		cp ")"
		jr z,got_str2		; end at close bracket
		ld (de),a
		inc hl
		inc de
		djnz strclp2

got_str2	ld hl,var_name2
		call kjt_get_envar
		ret nz
		ld de,var_data		;put value of comparison var at var_data
		ld bc,4
		ldir 
		
		jp val_comp		;continue as for absolute


;---------------------------------------------------------------------------------------


bad_args	call cond_false		;remove goto envar and return with FLOS message $12 = "bad args"
		ld a,$12	
		or a
		ret
		


cond_false

		ld hl,goto_txt		;remove goto envar
		call kjt_delete_envar
		xor a
		ret



cond_true

		call next_arg		;next part of the arg string should be "GOTO"
		jr z,bad_args
		ld de,goto_txt		
		ld b,4
		call kjt_compare_strings
		jp nc,bad_args
		
		call next_arg		;move to label after GOTO
		jr z,bad_args
		ld de,var_name
		ld b,4
newvlp		ld a,(hl)
		cp $21
		jr c,newvdone		;end on space or below
		ld (de),a
		inc hl
		inc de
		djnz newvlp
newvdone	xor a
		ld (de),a
		
		ld hl,goto_txt		;set the GOTO envar and quit
		ld de,var_name
		call kjt_set_envar
		ret


;-----------------------------------------------------------------------------------------

next_arg	ld hl,(args_pointer)
		call fnextarg
		ld (args_pointer),hl
		ret
		
fnextarg	inc hl
		ld a,(hl)			; locate next arg, ZF is NOT set if found
		or a
		ret z
		cp " "
		jr nz,fnextarg
nxtarg2		inc hl
		ld a,(hl)
		cp " "
		ret nz
		or a
		ret z
		jr nxtarg2
		
;------------------------------------------------------------------------------------------

ascii_to_long_word

; hl = source
; result in "var_data"

		ld b,8			; convert ascii to long word
lp4		ld a,(hl)
		or a
		jr z,got_evd
		cp " "
		jr z,got_evd
		push bc
		cp $60
		jr c,upcase
		sub $20
upcase		sub $3a			
		jr c,zeronine
		add a,$f9
zeronine	add a,$a
		push hl
		ld hl,(var_data)
		ld de,(var_data+2)
		ld b,4
rotquad		add hl,hl
		rl e
		rl d
		djnz rotquad
		ld (var_data),hl
		ld (var_data+2),de
		ld hl,var_data
		and $f
		or (hl)
		ld (hl),a
		pop hl
		inc hl
		pop bc
		djnz lp4
got_evd		ret

		
;-------------------------------------------------------------------------------------------

show_usage

		ld hl,usage_txt
		call kjt_print_string
		xor a
		ret

bad_operator
		
		ld a,$12			;FLOS error $12 = bad args
		or a
		ret
			
;-------------------------------------------------------------------------------------------

operator	db 0

args_pointer	dw 0

var_name	ds 5,0

var_name2	ds 5,0

var_data	 s 5,0

goto_txt	db "GOTO",0

usage_txt	db "-----------------------------",11
		db "IF.EXE - V1.00 By Phil Ruston",11
		db "(Script control command)",11
		db "Usage:",11
		db "IF xxxx cond yyyy GOTO zzzz",11
		db "Where:",11
		db "xxxx is an Envar",11
		db "cond is '=', '<', '>' or '<>'",11
		db "yyyy is a hex value, string",11
		db "in quotes or envar in brackets",11
		db "zzzz is label to go to.",11
		db "------------------------------",11,0
		
	
	
;-------------------------------------------------------------------------------------------

