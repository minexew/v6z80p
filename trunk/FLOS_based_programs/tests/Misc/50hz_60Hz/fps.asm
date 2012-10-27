
; wait with os timer - measures frame rate (approximately)

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	xor a
	ld (irq_count),a		; clear the IRQ counter

	di
	call kjt_wait_vrt
	ld a,$40
	ld (vreg_rastlo),a		; set position of first "IRQ"
	ld a,%00000000
	ld (vreg_rasthi),a		; set raster IRQ pos MSB / IRQ disabled
	ld a,$80
	ld (vreg_rasthi),a		; clear video irq flag at outset (from previous pass)

	ld hl,irq_count
	ld b,244
lp1	xor a
	call kjt_timer_wait
	in a,(sys_vreg_read)
	bit 3,a
	jr z,novirq
	inc (hl)
	ld a,$80
	ld (vreg_rasthi),a		;clear irq flag
novirq	djnz lp1
	
	ei
	ld a,(irq_count)
	ld hl,ascii_hex
	call kjt_hex_byte_to_ascii
	ld hl,message
	call kjt_print_string
	xor a
	ret
	
	
irq_count	db 0
		
message   db "Frame rate: $"
ascii_hex	db "xx frames per second.",11,11,0


;--------------------------------------------------------------------------------------
