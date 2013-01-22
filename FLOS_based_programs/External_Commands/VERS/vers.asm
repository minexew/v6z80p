
; App: Vers - shows OSCA / FLOS version, if args = # just make envars instead
; V1.01 - Improved by EB 22/1/2013 (reports PIC firmware and bootcode versions also)

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

required_flos	equ $598
include 	"flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;-------- Parse command line arguments -------------------------------------------------
	
	
	push hl
	
	call kjt_get_version
	ld (osca),de
	ld (flos),hl
	
	ld hl,0
	ld a,c
	or a
	jr nz,bcode_ver_set
	ld l,(ix+0)
	ld h,(ix+1)
bcode_ver_set
	ld (bcode),hl
	
;---- this part is based on EEPROM.ASM code
	ld hl,0
	call get_pic_fw			; if fw byte > $00, the PIC firmware is v618+
	jr nz,picfw_ver_set
	ld l,a
	ld h,6				; constant 6 for v6
picfw_ver_set
	ld (picfw),hl
;----
	
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
	
	ld hl,bcode_version_txt
	call kjt_print_string
	ld de,(bcode)
	ld a,d
	or e
	jr nz,print_bootcode_version
	
	ld hl,unknown_text
	call kjt_print_string
	jr skip_bootcode_version
	
print_bootcode_version
	call show_hex_word
	
	call new_line
	
skip_bootcode_version

	ld hl,picfw_version_txt
	call kjt_print_string
	ld de,(picfw)
	ld a,d
	or e
	jr nz,print_picfw_version
	
	ld hl,unknown_text
	call kjt_print_string
	jr skip_picfw_version
	
print_picfw_version
	call show_hex_word
	
	call new_line
	
skip_picfw_version
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
	ret nz
	
	ld hl,(bcode)
	ld a,h
	or l
	jr z,skip_bcode_variable	; do not set variable if version is unknown
	
	ld hl,bcode_version_txt
	ld de,bcode
	call kjt_set_envar
	ret nz
skip_bcode_variable

	ld hl,(picfw)
	ld a,h
	or l
	ret z				; do not set variable if version is unknown
	
	ld hl,picfw_version_txt
	ld de,picfw
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
	

;--------------------------------------------------------------------------------------
; Header code - routines to communicate with Config PIC
;--------------------------------------------------------------------------------------

include	"flos_based_programs\code_library\eeprom\inc\eeprom_subroutines.asm"
include	"flos_based_programs\code_library\eeprom\inc\eeprom_interogation.asm"

;------------------------------------------------------------------------------------------------

cr_txt	db 11,0

osca	dw 0,0

flos	dw 0,0

bcode	dw 0,0

picfw	dw 0,0

flos_version_txt

	db "FLOS V:",0

osca_version_txt

	db "OSCA V:",0

bcode_version_txt

	db "BCOD V:",0

picfw_version_txt

	db "PIC  V:",0

unknown_text
	
	db "Not reported",11,0

output_txt ds 5,0

;------------------------------------------------------------------------------------------------
