
;---Standard header for V5Z80P and OS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000
	
;-----------------------------------------------------------------------------

	di			; disable interrupts

	ld a,%00000000
	out (sys_irq_enable),a	; disable all irq sources
	ld a,%00000111
	out (sys_clear_irq_flags),a	; clear all irq flags 
	ld hl,(irq_vector)
	ld (original_irq),hl	; save OS IRQ vector
	ld hl,irq_handler		
	ld (irq_vector),hl		; new IRQ vector
	ld a,irq_line
	ld (vreg_rastlo),a		; split line number req'd
	ld a,%00000010
	ld (vreg_rasthi),a		; rast pos MSB and IRQ enable
	ld a,%10000000
	out (sys_irq_enable),a	; irq enable (master)
	
	ei			; allow IRQs @ CPU

;--------- Main loop -------------------------------------------------------------------------	

wvrtstart	ld a,(vreg_read)		; wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	ld hl,0
	ld (bitplane0a_loc),hl	; reset address counter
	ld hl,8192
	ld (bitplane1a_loc),hl	; reset address counter
	ld hl,16384
	ld (bitplane2a_loc),hl	; reset address counter
	ld hl,24576
	ld (bitplane3a_loc),hl	; reset address counter

	ld a,(irq_line)
	inc a
	jr nz,not_of
	ld a,$30
not_of	ld (irq_line),a
	ld (vreg_rastlo),a		; set line position of IRQ

	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		; quit if ESC key pressed

;---------------------------------------------------------------------------------------------

	ld hl,(original_irq)
	ld (irq_vector),hl
	ld a,%10000011		
	out (sys_irq_enable),a	; enable keyboard and mouse irqs for OS
	xor a			
	ret			; and exit

;--------------------------------------------------------------------------------------------


irq_handler

	push af
	push hl

	ld hl,32*40
	ld (bitplane0a_loc),hl	; reset address counter
	ld hl,8192+(32*40)
	ld (bitplane1a_loc),hl	; reset address counter
	ld hl,16384+(32*40)
	ld (bitplane2a_loc),hl	; reset address counter
	ld hl,24576+(32*40)
	ld (bitplane3a_loc),hl	; reset address counter

	ld a,%10000000
	ld (vreg_rasthi),a		; clear video irq
	pop hl
	pop af
	ei			; re-enable interrupts
	reti			; return to main code

;---------------------------------------------------------------------------------------------

original_irq	dw $0

irq_line		db $30
	
;---------------------------------------------------------------------------------------------