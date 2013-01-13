
; Tests serial irq - waits for 16 bytes in (software) serial buffer - osca 675

;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

		org $5000

		di
		ld hl,(irq_vector)
		ld (orig_vector),hl
		ld hl,my_irq
		ld (irq_vector),hl
		ld a,%01000000
		out (sys_irq_enable),a
		ld hl,rx_buffer
		ld (buffer_loc),hl
		ei
		
lp1		ld hl,$f0f				;background task - alternate border colour
		ld (palette),hl
		ld hl,$0f0
		ld (palette),hl
		ld hl,(buffer_loc)
		ld de,rx_buffer+16
		xor a
		sbc hl,de				;isbuffer full?
		jr nz,lp1
		
		di
		ld hl,(orig_vector)
		ld (irq_vector),hl
		ld a,%00000011
		out (sys_irq_enable),a
		xor a
		ret
		
		
my_irq		push af
		push hl
		in a,(sys_serial_port)			;reading serial port clears serial IRQ flag - no other IRQs enabled
		ld hl,(buffer_loc)			;so dont bother testing for serial RX flag
		ld (hl),a
		inc hl
		ld (buffer_loc),hl
		pop hl
		pop af
		ei
		reti
	
orig_vector	dw 0
buffer_loc	dw rx_buffer

	org	$6000

rx_buffer	ds 32,$ff
