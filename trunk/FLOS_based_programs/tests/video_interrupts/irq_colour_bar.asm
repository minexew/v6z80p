
; Video (Raster) Interrupt test: Colour bar - interrupts on each line of colour bar

; Note: VGA mode will probably show the interrupt jitter at the left edge, due to
; its shorter sync/backporch period and faster scan rate. The easiest way to avoid
; this is to use the Linecop for line sync'd register changed.

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------

irq_line	equ $60			; position of colour bar
	
;-----------------------------------------------------------------------------

	di			; disable interrupts

	ld a,%00000000
	out (sys_irq_enable),a	; disable all irq sources

	ld a,%00000111
	out (sys_clear_irq_flags),a	; clear all irq flags 


;-------- Set up video ------------------------------------------------------

	ld a,%00000000		; select y window pos register
	ld (vreg_rasthi),a		; 
	ld a,$5a			; set 200 line display
	ld (vreg_window),a
	ld a,%00000100		; switch to x window pos register
	ld (vreg_rasthi),a		
	ld a,$bb
	ld (vreg_window),a		; set 256 pixels wide window

	ld a,0			; Use 1 bitplane
	ld (vreg_yhws_bplcount),a

	xor a			; initialize bitplane pointer
	ld (bitplane0a_loc),a
	ld (bitplane0a_loc+1),a
	ld (bitplane0a_loc+2),a
	
	ld a,%00000000
	ld (vreg_vidctrl),a		; Set bitmap mode, video: on

	ld hl,0			
	ld (palette),hl		; zero palette cols 0 and 1
	ld (palette+2),hl
	
	xor a
	ld (vreg_vidpage),a		; select video page 0
		
	call kjt_page_in_video	; clear video page 
	ld hl,$2000
	ld bc,$2000
clrbplp	ld (hl),0
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,clrbplp
	call kjt_page_out_video


;--------- Set up scanline IRQ ---------------------------------------------------------------

	ld hl,irq_handler		
	ld (irq_vector),hl
	ld a,irq_line
	ld (vreg_rastlo),a		; split line number req'd
	ld a,%00000010
	ld (vreg_rasthi),a		; rast pos MSB and IRQ enable
	ld a,%10000000
	out (sys_irq_enable),a	; raster irq enable
	
	ei			; allow IRQs @ CPU
	

;--------- Main loop -------------------------------------------------------------------------	

wvrtstart	ld a,(vreg_read)		;wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	ld a,irq_line
	ld (vreg_rastlo),a		; set position of first IRQ
	xor a
	ld (irq_line_count),a	; clear the IRQ line counter
	ld a,%00000010
	ld (vreg_rasthi),a		; rast pos MSB and IRQ enable
	ld hl,(colour_bar_list)
	ld (colour_bar_val),hl	; first line's colour

	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		;loop if ESC key not pressed
	
	xor a
	ld a,$ff			;quit (restart OS)
	ret

;----------------------------------------------------------------------------------------------


irq_handler

	push hl
	ld hl,(colour_bar_val)	; set new colour ASAP upon IRQ
	ld (palette),hl
	
	push af
	push de
	
	ld a,(irq_line_count)
	inc a
	cp 17
	jr nz,sunl
	ld a,%00000000		; disable further interrupts this frame
	ld (vreg_rasthi),a
	jr irq_done

sunl	ld (irq_line_count),a	; set up next interrupt and find colour data
	add a,irq_line
	ld (vreg_rastlo),a

	ld hl,colour_bar_list
	ld de,(irq_line_count)
	sla e
	add hl,de
	ld a,(hl)
	ld (colour_bar_val),a
	inc hl
	ld a,(hl)
	ld (colour_bar_val+1),a
	
irq_done	ld a,%10000000
	ld (vreg_rasthi),a		; clear irq flag (leaves rest of register intact)
	
	pop de
	pop af			
	pop hl
	ei			; re-enable interrupts
	reti			; return to main code

;-------------------------------------------------------------------------------------------------

irq_line_count	db 0,0

colour_bar_val	dw 0

colour_bar_list	dw $025,$238,$459,$77b,$99c,$bbd,$eef,$fff
		dw $ff8,$ee7,$db6,$b95,$973,$752,$631,$410
		dw $000
	
;-------------------------------------------------------------------------------------------------
