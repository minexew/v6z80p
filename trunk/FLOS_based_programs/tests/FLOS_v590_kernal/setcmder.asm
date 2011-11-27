
; Tests the kjt_set_commander routine

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	ld hl,master_name
	call kjt_set_commander
	
	ld hl,msg
	call kjt_print_string	
	
	call kjt_wait_key_press
	ld a,b
	cp "1"
	jr z,launch
	cp "2"
	jr z,remove
	xor a
	ret
	
launch	ld hl,launch_name		;program to launch on exit
	ld a,$fe
	ret
		
remove	ld hl,no_prog		;null master = back to FLOS CLI 
	call kjt_set_commander	
	xor a
	ret
	
	
;----------------------------------------------------------------------------------------

msg	db "Commander program set!",11,11

	db "Press 1 - launch eeprom.exe",11
	db "Press 2 - remove commander",11
	db "Any other key, exit to FLOS (commander relaunches)",11,0
	

master_name

	db "setcmder.exe",0
	
launch_name

	db "eeprom.exe",0
	
no_prog	db 0
		
;--------------------------------------------------------------------------------------

