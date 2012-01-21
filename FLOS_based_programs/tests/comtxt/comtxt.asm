
; COMTXT.EXE - sends characters to the com port
; Usage: com.exe Text_to_send (characters up to first space are sent)

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


	push hl				;look for end of line
feol	ld a,(hl)
	inc hl
	or a
	jr nz,feol
flc	dec hl				;look for last char 
	ld a,(hl)
	cp $20
	jr nz,flc
	inc hl
	ld (hl),13			;<CR> at end of line
	inc hl
	ld (hl),10
	pop hl
	
comlp	ld a,(hl)
	push hl
	push af
	call kjt_serial_tx_byte
	pop af
	pop hl
	inc hl
	cp 10
	jr nz,comlp
	
	xor a
	ret

;---------------------------------------------------------------------------------------------
