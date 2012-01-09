;----------------------------------------------------------------------------------------------
; App: "GOTO.EXE" for script control - v1.00 By Phil @ retroleum
; Essentially the same as "SET GOTO xxxx"
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
	
	ld a,(hl)			; If no arguments supplied, show usage and delete goto envar
	or a
	jp z,show_usage

	push hl			; "source" envar name is copied to var_name
	ld de,label_name
	ld b,4
evnclp	ld a,(hl)
	cp " "
	jr z,evncdone
	ld (de),a
	inc hl
	inc de
	djnz evnclp
evncdone	pop hl
	
	ld hl,goto_txt
	ld de,label_name
	call kjt_set_envar
	ret

show_usage
	
	ld hl,goto_txt
	call kjt_delete_envar
	
	ld hl,usage_txt
	call kjt_print_string
	xor a
	ret

;-------------------------------------------------------------------------------------------

label_name

	ds 5,0

goto_txt	db "GOTO",0

usage_txt	db "-------------------------------",11
	db "GOTO.EXE - V1.00 By Phil Ruston",11
	db "Usage:",11
	db "GOTO script_label",11
	db "-------------------------------",11,0
	
		
	
;-------------------------------------------------------------------------------------------

