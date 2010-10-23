; Shows bytes received via RS232 serial port

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	ld hl,test_txt
	call kjt_print_string
	
rx_loop	ld a,$8a			;wait 10 seconds (quit if ESC pressed)
	call kjt_serial_rx_byte
	jr nc,show_byte		;if carry clear, received a byte
	cp $14			
	jr nz,rx_loop		;if a = $14, no byte received so just loop
		
	xor a			;else quit to FLOS
	ret

show_byte

	ld hl,hex_txt
	call kjt_hex_byte_to_ascii
	ld hl,string_txt
	call kjt_print_string
	jr rx_loop
	

;--------------------------------------------------------------------------------------

test_txt		db "Waiting for RS232 byte..",11,0

string_txt	db "Byte received:$"
hex_txt		db "xx",11,0

;--------------------------------------------------------------------------------------
