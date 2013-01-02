;-----------------------------------------------------------------------------------------------
; "MOUSE.EXE" = Test for mouse and activate driver v1.05
;-----------------------------------------------------------------------------------------------

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
required_osca	equ $675
include 	"flos_based_programs\code_library\program_header\inc\test_osca_version.asm"

;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------

		di
		call init_mouse
		ei
		jr nc,minit_ok
		
		ld hl,no_mouse_txt
		call kjt_print_string
		xor a
		ret
		
minit_ok	call kjt_get_display_size		;get pointer boundaries
		ld l,c
		ld h,0
		add hl,hl
		add hl,hl
		add hl,hl
		ex de,hl
		ld l,b
		ld h,0
		add hl,hl
		add hl,hl
		add hl,hl
		call kjt_enable_mouse
		
		ld hl,mouse_enabled_txt
		call kjt_print_string
		xor a
		ret

;-----------------------------------------------------------------------------------------------

mouse_enabled_txt

	db 11,"Mouse detected and enabled",11,11,0
	
no_mouse_txt
	
	db 11,"No mouse detected",11,11,0

;-----------------------------------------------------------------------------------------------
	
init_mouse

; returns carry set if no mouse / problem initializing

		
		ld a,$ff			; send "reset" command
		call ms_send_byte
		ret c
		call ms_get_response		; should be FA (ack)
		ret c
		cp $fa
		jr nz,ms_bad
		call ms_get_response		; should be AA (pass self test)
		ret c
		cp $aa
		jr nz,ms_bad
		call ms_get_response		; should be 00 (mouse ID)
		ret c
		or a
		jr nz,ms_bad
		
		ld a,$f4			; send "enable data reporting" command
		call ms_send_byte
		ret c
		call ms_get_response		; should be $FA (ack)
		ret c
		cp $fa
		ret z
				
ms_bad		scf
		ret
		

;----------------------------------------------------------------------------------------------------------

include "flos_based_programs/code_library/peripherals/mouse/inc/mouse_low_level_all.asm"

;-----------------------------------------------------------------------------------------------------------

