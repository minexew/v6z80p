
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

;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------

		ld a,(hl)
		ld (digit),a
		
		call kjt_ascii_to_hex_word
		ret nz
	
		ld a,e
		cp 50
		jr z,go50hz
		cp 60
		jr z,go60hz
		
		ld a,$1a
		or a
		ret
		
go60hz		ld a,%00000000			; enable 60Hz VGA mode timing
		jr set_vga

go50hz		ld a,%00001000
set_vga		out (sys_hw_settings),a		; enable 50Hz VGA mode timing
	
pr_exit		ld hl,message
		call kjt_print_string
		xor a
		ret

message		db "VGA mode set to "
digit		db "50Hz",11,11,0

;------------------------------------------------------------------------------------------------
