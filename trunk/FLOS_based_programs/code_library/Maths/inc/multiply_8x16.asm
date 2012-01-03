;----------------------------------------------------------------------------------------------------
;Thanks to Milos "baze" Bazelides: http://baze.au.com/misc/z80bits.html for collecting these routines
;----------------------------------------------------------------------------------------------------

mult_816

; Input:  A = Multiplier, DE = Multiplicand
; Output: A:HL = Product 

	ld 	hl,0
	ld	c,0
	add	a,a		; optimised 1st iteration
	jr	nc,$+4
	ld	h,d
	ld	l,e
	add	hl,hl		; 
	rla			;
	jr	nc,$+4		; 
	add	hl,de		; 
	adc	a,c		; 
	add	hl,hl		; 
	rla			; 
	jr	nc,$+4		; 
	add	hl,de		; 
	adc	a,c		; 
	add	hl,hl		; 
	rla			; 
	jr	nc,$+4		; 
	add	hl,de		; 
	adc	a,c		; 
	add	hl,hl		; 
	rla			; 
	jr	nc,$+4		; 
	add	hl,de		; 
	adc	a,c		; 
	add	hl,hl		;
	rla			; 
	jr	nc,$+4		; 
	add	hl,de		; 
	adc	a,c		;
	add	hl,hl		; 
	rla			; 
	jr	nc,$+4		; 
	add	hl,de		; 
	adc	a,c		; 
	add	hl,hl		; 
	rla			; 
	jr	nc,$+4		; 
	add	hl,de		; 
	adc	a,c		; 
	ret

;---------------------------------------------------------------------------------------------	
