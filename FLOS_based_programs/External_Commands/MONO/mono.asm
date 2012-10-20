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


;=======================================================================================		
;  Main Code starts here
;=======================================================================================
	
	ld hl,mono_txt
	call kjt_print_string
	ld a,%11111111		;all to both
	out ($22),a
	xor a
	ret

;-----------------------------------------------------------------------------------------

mono_txt	db "Sound config set to mono",11,0
	
;-----------------------------------------------------------------------------------------

