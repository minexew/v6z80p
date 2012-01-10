
;Force VGA mode to 50Hz

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

	ld a,%00001000
	out (sys_hw_settings),a		; enable 50Hz VGA mode timing
	
	ld hl,message
	call kjt_print_string
	xor a
	ret

message	db "VGA mode set to 50Hz",11,11,0

;------------------------------------------------------------------------------------------------
