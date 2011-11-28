
; LineCop example: Changes a single scanline (border) colour to white
;
; (The FLOS command "LCD 0" can be used to disassemble the linecop program once this program has run)

;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;--------------------------------------------------------------------------------------------------------------

		ld b,end_my_linecop_list-my_linecop_list	; copy LineCop instructions to $70000+
		ld hl,0					; IE: Locations accessible by LineCop system
		ld e,7					
		ld ix,my_linecop_list
copyloop		ld a,(ix)
		push hl
		push bc
		push de
		call kjt_write_sysram_flat			; put A @ (E:HL)
		pop de
		pop bc
		pop hl
		inc ix
		inc hl
		djnz copyloop
	
	
		ld hl,$0001
		ld (vreg_linecop_lo),hl			; set linecop program location and start
		
		call kjt_wait_key_press			; wait for any key
		
		ld a,0
		ld (vreg_linecop_lo),a			; disable linecop
	
		xor a					; back to FLOS
		ret


;--------------------------------------------------------------------------------------------------------

my_linecop_list	dw $c050		; Wait for line $50
		dw $8000		; Select video register $000 (background colour)
		dw $40ff		; Write $ff to colour LSB, increment video register
		dw $20ff		; Write $ff to colour MSB, increment wait line (and wait)
		dw $8000		; Select video register $000 (background colour)
		dw $4000		; Write $00 to colour LSB, increment video register
		dw $0000		; Write $00 to colour MSB
		dw $C1FF		; Wait for Line $1FF (End of LineCop program)
		
end_my_linecop_list	db 0

;---------------------------------------------------------------------------------------------------------
