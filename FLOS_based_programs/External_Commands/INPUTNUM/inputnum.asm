;----------------------------------------------------------------------------------------------
; App: "INPUTNUM.EXE" sets an environment variable with hex number from user  - v1.00 By Phil @ retroleum
;
; Usage: INPUTNUM xxxx
; Where xxxx = An Envar
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
include 	"flos_based_programs\code_library\program_header\inc\force_load_location.asm"

required_flos	equ $594
include 	"flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;--------------------------------------------------------------------------------------
	
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
		
		ld a,8			
		call kjt_get_input_string
		jr nz,nodata
		
		call ascii_to_long_word
		
		ld hl,var_name
		ld de,var_data
		call kjt_set_envar
		ret

nodata		ld hl,var_name		;if no string entered delete the envar (if it exists)
		call kjt_delete_envar
		xor a
		ret
				
;-------------------------------------------------------------------------------------------

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

		
;-------------------------------------------------------------------------------------------

var_name	ds 5,0

var_data  	ds 5,0

usage_txt	db "-----------------------------------",11
		db "INPUTNUM.EXE - V1.00 By Phil Ruston",11
		db "Gets a hex number (32bit) for Envar",11
		db "Usage:",11
		db "INPUTNUM envar",11
		db "-----------------------------------",11,0
	
	
;-------------------------------------------------------------------------------------------

