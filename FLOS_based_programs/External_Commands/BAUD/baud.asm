
; BAUD [speed] command - sets baud rate - v0.03 By Phil '09

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


		ld a,(hl)			; examine argument text, if 0: show use
		or a			
		jr z,no_param

		ld (args_start),hl

		ld ix,baud_list
baud_lp		ld e,(ix)
		ld d,(ix+1)			;what baud rate was requested?
		ld b,(ix+2)
		ld a,e
		or d
		jr z,nbaud
		call kjt_compare_strings
		jr c,got_baud
		ld de,6
		add ix,de
		jr baud_lp
		
got_baud	push ix
		call kjt_get_version		
		pop ix				;hardware revision required for selected baud
		ld l,(ix+4)
		ld h,(ix+5)
		xor a
		sbc hl,de
		jr nc,nbaud

		ld a,(ix+3)
		out (sys_baud_rate),a
		ld hl,baud_set_txt
		call kjt_print_string
		ld l,(ix)
		ld h,(ix+1)
		call kjt_print_string
		ld hl,bps_txt
		call kjt_print_string
		xor a
		ret		

nbaud		xor a					
		ld hl,bad_baud_txt		;unknown args/unsupported baud rate
		call kjt_print_string
		xor a
		ret

no_param	ld hl,no_param_txt
		call kjt_print_string
		xor a
		ret
	

;------------------------------------------------------------------------------------------------

args_start	dw 0

baud_list	dw baud14
		db 5
		db %10
		dw $675-1
		
		dw baud28
		db 5
		db %11
		dw $675-1
		
		dw baud57
		db 5
		db %00
		dw $0
		
		dw baud115
		db 6
		db %01
		dw $266-1
		
		dw 0			;list terminator
		
		
baud14		db "14400",0
baud28		db "28800",0
baud57		db "57600",0
baud115		db "115200",0

	
baud_set_txt	db "BAUD rate set at: ",0

bps_txt		db " bps",11,0

bad_baud_txt	db "Unsupported baud rate!",11,0

no_param_txt	db "Usage: BAUD [speed]",11,0

;------------------------------------------------------------------------------------------------
