; Shows info about loaded program

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

;======================================================================================
; Program Location File Header:
; FLOS v569+ will use this data to load the program a specific location
; and optionally truncate it to n bytes
; Earlier versions of FLOS will ignore it and load the program to $5000
;======================================================================================

my_location	equ $5000
my_bank		equ $0


	org my_location	; desired load address
	
load_loc	db $ed,$00	; Location Header ID (ED,00 is an invalid Z80 instruction)
	jr exec_addr	; jump over remaining header data

	dw load_loc	; location that file should load to
	db my_bank	; upper bank that the file should load into

	db $01		; 1 = use truncated load length in following 3 bytes
	dw $c1		; load length [15:0]
	db $00		; load length [23:16]
	
exec_addr	

;-----------------------------------------------------------------------------

; Upon start in FLOS 584+, IX = file system info pointer
	

	ld hl,fl1
	ld a,(iy+3)
	call kjt_hex_byte_to_ascii
	ld a,(iy+2)
	call kjt_hex_byte_to_ascii
	ld a,(iy+1)
	call kjt_hex_byte_to_ascii
	ld a,(iy+0)
	call kjt_hex_byte_to_ascii
	
	ld hl,fcp
	ld a,(iy+9)
	call kjt_hex_byte_to_ascii
	ld a,(iy+8)
	call kjt_hex_byte_to_ascii

	ld hl,my_text	
	call kjt_print_string
	xor a
	ret
	
;------------------------------------------------------------------------------------------------

my_text	db 11,"File length:"
fl1	db "xxxxyyyy",11,11

	db "First cluster:"
fcp	db "xxxx",11,0

;------------------------------------------------------------------------------------------------

	ds 1000,255		; just padding
	