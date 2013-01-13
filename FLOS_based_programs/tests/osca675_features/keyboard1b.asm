
; Tests keyboard with IRQs off (force KB to buffer)
; keypresses when irqs are off should are buffered internally by KB but
; absorbed by clear KB buffer routine

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

		call clear_kb_buffer
				
		ei
		ld hl,irqon
		call kjt_print_string

		xor a
		ret



clear_kb_buffer	ld b,50					; clear keyboard's internal buffer
clrkbbf_lp	call kjt_wait_vrt			; (throw away upto 16 scancodes)
		in a,(sys_irq_ps2_flags)		; wait 1 second max for scancodes to be transmitted
		and 1					; expect each each scancode within 1 frame 
		ret z
		out (sys_clear_irq_flags),a
		djnz clrkbbf_lp
		ret


	
wait		ld b,200
lp1		push bc
		call kjt_wait_vrt
		pop bc
		djnz lp1
		ret
	
irqon	db "IRQs on",11,0
irqoff	db "IRQs off",11,0
