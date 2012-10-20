
; App: Vers - shows OSCA / FLOS version, if args = # just make envars instead

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

required_flos	equ $598
include 	"flos_based_programs\code_library\program_header\test_flos_version.asm"

;-------- Parse command line arguments -------------------------------------------------
	
	
	push hl
	call kjt_get_version
	ld (osca),de
	ld (flos),hl
	pop hl
	
	ld a,(hl)
	cp '#'				; check for # = silent running (make envars OSCA,FLOS)
	jr z,make_vars
	
	ld hl,flos_version_txt
	call kjt_print_string
	ld de,(flos)
	call show_hex_word
	
	call new_line
	
	ld hl,osca_version_txt
	call kjt_print_string
	ld de,(osca)
	call show_hex_word
	
	call new_line	
	xor a
	ret
	
	

make_vars
	
	ld hl,osca_version_txt
	ld de,osca
	call kjt_set_envar
	ret nz
	
	ld hl,flos_version_txt
	ld de,flos
	call kjt_set_envar
	ret


	

show_hex_word

				
	ld hl,output_txt		; put word to display in DE
	push hl
	ld a,d
	call kjt_hex_byte_to_ascii
	ld a,e
	call kjt_hex_byte_to_ascii
	pop hl
	call kjt_print_string
	ret
	
	
	
	
new_line	

	ld hl,cr_txt
	call kjt_print_string
	ret
	
;------------------------------------------------------------------------------------------------

cr_txt	db 11,0

osca	dw 0,0

flos	dw 0,0

flos_version_txt

	db "FLOS V:",0

osca_version_txt

	db "OSCA V:",0

output_txt ds 5,0

;------------------------------------------------------------------------------------------------
