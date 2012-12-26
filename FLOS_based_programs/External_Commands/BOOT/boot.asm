; boot.exe command - reconfigs the FPGA. v1.04
;
; Changes: 1.02 - when run without args, the EEPROM contents are displayed

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
	
		push hl			
		call get_eeprom_size
		pop hl
		
		ld a,(hl)				;any args supplied?	
		or a    
		jr nz,got_arg
	    
		call kjt_clear_screen			;if args = null, show slot contents etc	
		ld hl,contents_txt
		call kjt_print_string
		call eeprom_slot_list	
		ld hl,slot_prompt_txt
		call kjt_print_string
		ld a,2
		call kjt_get_input_string
		or a
		jr nz,got_arg
		ld a,$2d				; if no input show "aborted" error
		or a
		ret


got_arg		call kjt_ascii_to_hex_word		; is entered text a valid number (result in DE)?
		ld a,d
		or e
		jr z,badslot				; cant boot from slot 0
		
		ld a,(number_of_slots)	
		dec a
		cp e
		jr c,badslot
		
		ld a,e
		ld (slot_number),a
		
		ld hl,reconfig_txt
		call kjt_print_string
		
		ld b,244				; wait a second 
op2wait		xor a
		call kjt_timer_wait
		djnz op2wait					

		ld a,(slot_number)
		jp eeprom_reconfig
		
;--------------------------------------------------------------------------------------

badslot		ld hl,badslot_txt
		call kjt_print_string
		ld a,$80
		or a
		ret

;--------------------------------------------------------------------------------------

		include "flos_based_programs\code_library\eeprom\inc\eeprom_subroutines.asm"
		include "flos_based_programs\code_library\eeprom\inc\eeprom_read.asm"
		include "flos_based_programs\code_library\eeprom\inc\eeprom_interogation.asm"
		include "flos_based_programs\code_library\eeprom\inc\eeprom_slot_list.asm"
		include "flos_based_programs\code_library\eeprom\inc\eeprom_config.asm"
		
;-------------------------------------------------------------------------------------------------

slot_number	db 0

;------------------------------------------------------------------------------------------

contents_txt		db 11,"           EEPROM CONTENTS:",11
			db "           ----------------",11,11,0

;------------------------------------------------------------------------------------------

reconfig_txt		db 11,11,"Reconfiguring...",0
badslot_txt		db 11,11,"Invalid slot selection.",11,0
slot_prompt_txt		db 11,"Enter slot to configure from: ",0

;-------------------------------------------------------------------------------------------

