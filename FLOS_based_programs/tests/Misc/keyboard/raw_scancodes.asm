
; Tests PS2 keyboard interface - shows RAW scancodes
; NOTE: Too slow to respond to all codes when screen starts scrolling

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================
	
	call kjt_clear_screen
	ld hl,text
	call kjt_print_string
	di				;disable system (keyboard handler) IRQ
	
begin	in a,(sys_irq_ps2_flags)
	and 1
	jr z,begin

;	ld a,16
;	out (sys_ps2_joy_control),a		;tell keyboard to wait (stop sending keycodes)

	in a,(sys_keyboard_data)
	cp $76
	jr nz,noexit
	ei
	xor a
	ret
	
noexit	ld hl,hex_text+1			
	call kjt_hex_byte_to_ascii		
	ld hl,hex_text
	call kjt_print_string		;shows byte data from kb as hex

;	ld a,0
;	out (sys_ps2_joy_control),a		;tell keyboard to continue sending keycodes
;	call wait

	ld a,1
	out (sys_clear_irq_flags),a

	jr begin
	
wait	ld bc,0
wait2	dec bc
	ld a,b
	or c
	jr nz,wait2
	ret
	
;----------------------------------------------------------------------------------

text	db "Press keys to show RAW scancodes..",11,"ESC to quit..",11,11
	db "NOTE: Too slow to respond to all",11
	db "scancodes once screen starts scrolling",11,11,0

hex_text	db "$   ",0

;-----------------------------------------------------------------------------------
