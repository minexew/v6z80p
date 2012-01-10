
; ECHO.EXE - Shows a line of text v1.02
; Usage: echo.exe Text_to_display

;---Standard header for OSCA and FLOS ----------------------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"


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

					;home cursor
	call kjt_get_cursor_position
	ld b,0
shchlp	call kjt_set_cursor_position
	jr nz,ldone
	ld a,(hl)
	or a
	jr z,ldone
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
