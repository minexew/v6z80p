
; Tests video irq - with newer port based irq enable - osca 675

;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

;-----------------------------------------------------------------------------

irq_line	equ $60			; position of colour bar
	
;-----------------------------------------------------------------------------

		org $5000

		di
		ld hl,(irq_vector)
		ld (orig_vector),hl
		ld hl,my_irq1
		ld (irq_vector),hl
		ld a,%00001000
		out (sys_irq_enable),a

		ld a,irq_line
		ld (vreg_rastlo),a		; split scan line position LSB
		ld a,0+(irq_line>>8)
		ld (vreg_rasthi),a		; split scan line position MSB 
		
		ei				; allow IRQs @ CPU
	

;--------- Main loop -------------------------------------------------------------------------	

		ld b,250
bgndtlp		call kjt_wait_vrt		;wait 5 seconds
		djnz bgndtlp
		
		di				;back to flos
		ld hl,(orig_vector)
		ld (irq_vector),hl
		ld a,%00000011
		out (sys_irq_enable),a
		ei
		xor a
		ret
		
;----------------------------------------------------------------------------------------------


my_irq1		push hl			; if any other IRQs are enabled we'd need to test port 1 bit 3 for virq 
		ld hl,$f0f			; there arent here so we'll assume its a video irq
		ld (palette),hl			; set border colour
		
		push af
		ld a,irq_line+16
		ld (vreg_rastlo),a		; set split scan line position LSB
		ld a,0+((irq_line+16)>>8)
		ld (vreg_rasthi),a		; set split scan line position MSB 
		
		ld hl,my_irq2
		ld (irq_vector),hl		; on next irq go to routine 2
		ld a,%10000000
		ld (vreg_rasthi),a		; clear irq flag (Special bit 7 write: leaves rest of register intact)

		pop af
		pop hl
		ei
		reti
	

	
my_irq2		push hl			; if any other IRQs are enabled we'd need to test port 1 bit 3 for virq 
		ld hl,$0f0			; there arent here so we'll assume its a video irq
		ld (palette),hl			; set border colour
		
		push af
		ld a,irq_line
		ld (vreg_rastlo),a		; set split scan line position LSB
		ld a,0+(irq_line>>8)
		ld (vreg_rasthi),a		; set split scan line position MSB 
		
		ld hl,my_irq1
		ld (irq_vector),hl		; on next irq go to routine 1
		ld a,%10000000
		ld (vreg_rasthi),a		; clear irq flag (Special bit 7 write: leaves rest of register intact)

		pop af
		pop hl
		ei
		reti

;----------------------------------------------------------------------------------------------

orig_vector	dw 0

		
