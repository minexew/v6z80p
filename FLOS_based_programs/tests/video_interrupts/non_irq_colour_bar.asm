
; Video (Raster) Interrupt FLAG test: Tests video IRQ FLAG ONLY,
; no actual interrupts are used. (Busy waiting) Should show a colour bar.

; Note: VGA mode will probably show jitter at the left edge, due to
; its shorter sync/backporch period and faster scan rate.

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------

irq_line	equ $60			; position of colour bar
	
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


;--------- Main loop -------------------------------------------------------------------------	

wvrtstart	ld a,(vreg_read)		;wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	ld a,irq_line
	ld (vreg_rastlo),a		; set position of first "IRQ"
	xor a
	ld (irq_line_count),a	; clear the IRQ line counter
	ld a,%00000000
	ld (vreg_rasthi),a		; set raster IRQ pos MSB / IRQ disabled
	
	call busy_wait_colour_bar

	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		;loop if ESC key not pressed
	xor a
	ld a,$ff			;quit (restart OS)
	ret

;----------------------------------------------------------------------------------------------

busy_wait_colour_bar

	ld a,$80
	ld (vreg_rasthi),a		;clear video irq flag at outset (from previous pass)

	ld b,17			;number of bars
	ld hl,colour_bar_list	;colour list
barloop	ld e,(hl)			;get first colour
	inc hl
	ld d,(hl)
	inc hl

waiting	ld a,(vreg_read)		;wait for raster IRQ flag to become set
	bit 3,a
	jr z,waiting
			
	ld (palette),de		;set the new colour

	ld a,(irq_line_count)	
	inc a
	ld (irq_line_count),a
	add a,irq_line
	ld (vreg_rastlo),a		;set position of next line match

	ld a,$80
	ld (vreg_rasthi),a		;clear irq flag

	djnz barloop
	ret
	

;-------------------------------------------------------------------------------------------------

irq_line_count	db 0

colour_bar_list	dw $025,$238,$459,$77b,$99c,$bbd,$eef,$fff
		dw $ff8,$ee7,$db6,$b95,$973,$752,$631,$410
		dw $000
	
;-------------------------------------------------------------------------------------------------
