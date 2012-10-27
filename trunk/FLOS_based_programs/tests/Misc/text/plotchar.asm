
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	ld d,$20			;ascii char
	ld e,$00			;pen colour / loop count

testloop	ld a,e
	call kjt_set_pen		;select pen colour ($ab, a=bgnd colour, b = fgnd colour)
	
	ld a,e
	and $f
	ld b,a			;x coord
	
	ld a,e
	rrca
	rrca
	rrca
	rrca
	and $f
	ld c,a			;y coord
	
	ld a,d			;ascii char to plot
		
	push de
	call kjt_plot_char
	pop de
	
	inc d			;next char
	ld a,d
	cp $80
	jr nz,charok
	ld d,$20
	
charok	inc e			;next pen colour
	jr nz,testloop


	ld a,$07
	call kjt_set_pen		;select pen colour

	xor a			;no error on return 
	ret
	
;--------------------------------------------------------------------------------------
	
test_text	db "Hello World! ",0

;--------------------------------------------------------------------------------------
