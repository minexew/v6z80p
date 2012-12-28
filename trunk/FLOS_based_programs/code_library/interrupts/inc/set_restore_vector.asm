
;----------------------------------------------------------------------------------------------------------------------------

set_irq_vector
		push hl
		ld hl,(irq_vector)
		ld (orig_irq_vector),hl
		pop hl
		ld (irq_vector),hl
		ret
		
		
restore_irq_vector

		di
		ld hl,(orig_irq_vector)
		ld (irq_vector),hl
		ei
		ret
		
		
orig_irq_vector

		dw 0
		
;----------------------------------------------------------------------------------------------------------------------------
