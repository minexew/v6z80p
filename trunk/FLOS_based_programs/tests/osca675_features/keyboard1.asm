
; Tests keyboard with IRQs off (force KB to buffer)
; keys pressed when irqs are off should still appear afterwards

;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

		org $5000

		ld hl,irqon
		call kjt_print_string
		call wait
		ld hl,irqoff
		call kjt_print_string
		di
		call wait
		ei
		ld hl,irqon
		call kjt_print_string
		xor a
		ret
	
wait		ld b,100
lp1		push bc
		call kjt_wait_vrt
		pop bc
		djnz lp1
		ret
	
irqon	db "IRQs on",11,0
irqoff	db "IRQs off",11,0
