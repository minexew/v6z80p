
; Tests PS2 keyboard interface - shows scancodes

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================
	
	ld hl,text
	call kjt_print_string
	
begin	call kjt_wait_key_press		;returns b = ascii code / a = scancode
	cp $76
	jr nz,noexit
	xor a
	ret
	
noexit	push af
	ld a,"-"
	ld (hex_text),a
	ld a,b
	cp $20
	jr c,nochar
	cp $80
	jr nc,nochar
	ld (hex_text),a
nochar	pop af

	ld hl,hex_text+4			
	call kjt_hex_byte_to_ascii		
	ld hl,hex_text
	call kjt_print_string		;shows byte data from kb as hex
	jr begin
	
;----------------------------------------------------------------------------------

text	db "Press keys to show scancodes..",11,"ESC to quit..",11,11,0

hex_text	db "x = --  ",0

;-----------------------------------------------------------------------------------
