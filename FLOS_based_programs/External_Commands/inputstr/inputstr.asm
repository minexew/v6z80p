;----------------------------------------------------------------------------------------------
; App: "INPUTSTR.EXE" sets an environment variable with string from user  - v1.00 By Phil @ retroleum
;
; Usage: INPUTSTR xxxx
; Where xxxx = An Envar
;--------------------------------------------------------------------------------------------


;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $f000
my_bank		equ $0e
include 		"force_load_location.asm"

required_flos	equ $594
include 		"test_flos_version.asm"

;--------------------------------------------------------------------------------------
	
	ld a,(hl)			; If no arguments supplied, show usage.
	or a
	jp z,show_usage

	push hl			; "source" envar name is copied to var_name
	ld de,var_name
	ld b,4
evnclp	ld a,(hl)
	cp " "
	jr z,evncdone
	ld (de),a
	inc hl
	inc de
	djnz evnclp
evncdone	pop hl
	
	ld a,4			
	call kjt_get_input_string
	jr nz,nodata
	
	ld de,var_data
	ld b,4			; copy input string to var_data
envdlp	ld a,(hl)
	ld (de),a
	or a
	jr z,datardy
	inc hl
	inc de
	jr envdlp
			
datardy	ld hl,var_name
	ld de,var_data
	call kjt_set_envar
	ret

nodata	ld hl,var_name		;if no string entered delete the envar (if it exists)
	call kjt_delete_envar
	xor a
	ret
			
;-------------------------------------------------------------------------------------------

show_usage

	ld hl,usage_txt
	call kjt_print_string
	xor a
	ret

		
;-------------------------------------------------------------------------------------------

var_name		ds 5,0

var_data  	ds 5,0

usage_txt	db "-----------------------------------",11
	db "INPUTSTR.EXE - V1.00 By Phil Ruston",11
	db "Gets a 4 char max string for Envar",11
	db "Usage:",11
	db "INPUTSTR envar",11
	db "-----------------------------------",11,0
	
	
;-------------------------------------------------------------------------------------------

