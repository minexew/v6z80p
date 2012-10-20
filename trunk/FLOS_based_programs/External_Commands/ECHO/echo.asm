
; ECHO.EXE - Shows a line of text v1.03
; Usage: echo.exe Text_to_display

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

required_flos	equ $594
include 	"flos_based_programs\code_library\program_header\inc\test_flos_version.asm"


;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------

					
	call kjt_get_cursor_position		;home cursor
	ld b,0
shchlp	call kjt_set_cursor_position
	jr nz,ldone
	ld a,(hl)
	cp 32
	jr c,ldone
	call kjt_plot_char
	inc hl
	inc b
	jr shchlp

ldone	ld hl,cr_txt
	call kjt_print_string
	xor a
	ret

cr_txt	db 11,0

;---------------------------------------------------------------------------------------------
