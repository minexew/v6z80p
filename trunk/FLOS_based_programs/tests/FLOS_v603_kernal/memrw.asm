; copy bank 1 to bank 2 with new routines

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

;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------


	ld hl,$8000
lp1	ld b,1	
	call kjt_read_baddr
	ld b,2
	call kjt_write_baddr
	inc hl
	ld a,h
	or l
	jr nz,lp1
	
	xor a
	ret
	